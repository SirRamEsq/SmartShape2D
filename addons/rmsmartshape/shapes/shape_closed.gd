tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Closed, "../closed_shape.png"


#########
# GODOT #
#########
func _init():
	_is_instantiable = true


############
# OVERRIDE #
############
func _has_minimum_point_count() -> bool:
	return get_point_count() >= 3


func duplicate_self():
	var _new = .duplicate()
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()


func _get_next_point_index(idx: int, points: Array) -> int:
	var new_idx = idx
	new_idx = idx % (points.size() - 1)
	# Skip last point; First and last point are the same when closed
	if new_idx == points.size() - 1:
		new_idx = _get_next_point_index(new_idx, points)
	return new_idx


func _get_previous_point_index(idx: int, points: Array) -> int:
	var new_idx = idx - 1
	if new_idx < 0:
		new_idx += points.size()
	# Skip last point; First and last point are the same when closed
	if new_idx == points.size() - 1:
		new_idx = _get_previous_point_index(new_idx, points)
	return new_idx


func _get_last_point_index(points: Array) -> int:
	return points.size() - 2


func _build_meshes(edges: Array) -> Array:
	var meshes = []

	var produced_fill_mesh = false
	for e in edges:
		if not produced_fill_mesh:
			if e.z_index > shape_material.fill_texture_z_index:
				# Produce Fill Meshes
				for m in _build_fill_mesh(get_tessellated_points(), shape_material):
					meshes.push_back(m)
				produced_fill_mesh = true

		# Produce edge Meshes
		for m in e.get_meshes():
			meshes.push_back(m)
	if not produced_fill_mesh:
		for m in _build_fill_mesh(get_tessellated_points(), shape_material):
			meshes.push_back(m)
		produced_fill_mesh = true
	return meshes


func _build_edges(s_mat: RMSS2D_Material_Shape, wrap_around: bool) -> Array:
	var points = get_tessellated_points()
	var edges: Array = []
	if s_mat == null:
		return edges

	for edge_material in get_edge_materials(points, s_mat, wrap_around):
		edges.push_back(_build_edge(edge_material))

	if s_mat.weld_edges:
		if edges.size() > 1:
			for i in range(0, edges.size(), 1):
				var this_edge = edges[i]
				var next_edge = edges[i + 1]
				_weld_quads(this_edge.quads[this_edge.quads.size() - 1], next_edge.quads[0], 1.0)
		var first_edge = edges[0]
		var last_edge = edges[edges.size() - 1]
		_weld_quads(last_edge.quads[last_edge.quads.size() - 1], first_edge.quads[0], 1.0)
	return edges


func _close_shape() -> bool:
	"""
	Will mutate the _points to ensure this is a closed_shape
	last point will be constrained to first point
	returns true if _points is modified
	"""
	var point_count = get_point_count()
	if not _has_minimum_point_count():
		return false
	var first_point = _points.get_point_at_index(0)
	var final_point = _points.get_point_at_index(point_count - 1)
	if not first_point.equals(final_point):
		var key_first = _points.get_point_key_at_index(0)
		var key_last = add_point(first_point.position)
		_points.set_constraint(key_first, key_last, RMSS2D_Point_Array.CONSTRAINT.ALL)
		return true
	return false


func _add_point_update():
	# Return early if _close_shape() adds another point
	# _add_point_update() will be called again by having another point added
	if _close_shape():
		return
	set_as_dirty()
	emit_signal("points_modified")
