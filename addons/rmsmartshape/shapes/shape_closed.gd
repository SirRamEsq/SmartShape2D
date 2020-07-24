tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Closed, "../closed_shape.png"

var _constrained_points: Array = []


#########
# GODOT #
#########
func _init():
	._init()
	_is_instantiable = true


############
# OVERRIDE #
############
func _has_minimum_point_count() -> bool:
	return _points.get_point_count() >= 3


func duplicate_self():
	var _new = .duplicate()
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()


func _get_next_point_index(idx: int, points: Array) -> int:
	if not is_shape_closed():
		return ._get_next_point_index(idx, points)

	var new_idx = idx + 1
	new_idx = new_idx % (points.size() - 1)
	# Skip last point; First and last point are the same when closed
	if new_idx == points.size() - 1:
		new_idx = _get_next_point_index(new_idx, points)
	return new_idx


func _get_previous_point_index(idx: int, points: Array) -> int:
	if not is_shape_closed():
		return ._get_next_point_index(idx, points)

	var new_idx = idx - 1
	if new_idx < 0:
		new_idx += points.size()
	# Skip last point; First and last point are the same when closed
	if new_idx == points.size() - 1:
		new_idx = _get_previous_point_index(new_idx, points)
	return new_idx


func get_real_point_count():
	return _points.get_point_count()

func get_point_count():
	if is_shape_closed():
		return get_real_point_count() - 1
	return get_real_point_count()

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
	if is_shape_closed():
		return false
	if not _has_minimum_point_count():
		return false
	var key_first = _points.get_point_key_at_index(0)
	# Manually add final point
	var key_last = _points.add_point(_points.get_point_position(key_first))
	_points.set_constraint(key_first, key_last, RMSS2D_Point_Array.CONSTRAINT.ALL)
	_constrained_points = [key_first, key_last]
	_add_point_update()
	return true


func is_shape_closed() -> bool:
	var point_count = _points.get_point_count()
	if not _has_minimum_point_count():
		return false
	var key1 = _points.get_point_key_at_index(0)
	var key2 = _points.get_point_key_at_index(point_count - 1)
	var first_point = _points.get_point(key1)
	var final_point = _points.get_point(key2)
	return first_point.equals(final_point)


func add_points(verts: Array, starting_index: int = -1, update: bool = true) -> Array:
	return .add_points(verts, adjust_add_point_index(starting_index), update)


func add_point(position: Vector2, index: int = -1, update: bool = true) -> int:
	return .add_point(position, adjust_add_point_index(index), update)

func adjust_add_point_index(index:int)->int:
	# Don't allow a point to be added after the last point of the closed shape or before the first
	if is_shape_closed():
		if index < 0 or (index > _points.get_point_count() - 1):
			index = max(_points.get_point_count() - 1, 0)
		if index < 1:
			index = 1
	return index


func _add_point_update():
	# Return early if _close_shape() adds another point
	# _add_point_update() will be called again by having another point added
	if _close_shape():
		return
	._add_point_update()
