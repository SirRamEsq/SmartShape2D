tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Closed, "../closed_shape.png"


#########
# GODOT #
#########
func _init():
	._init()
	_is_instantiable = true


############
# OVERRIDE #
############
func remove_point(key: int):
	_points.remove_point(key)
	_close_shape()
	_update_curve(_points)
	set_as_dirty()
	emit_signal("points_modified")


func set_point_array(a: RMSS2D_Point_Array):
	_points = a.duplicate(true)
	_close_shape()
	clear_cached_data()
	_update_curve(_points)
	set_as_dirty()
	property_list_changed_notify()


func _has_minimum_point_count() -> bool:
	return _points.get_point_count() >= 3


func duplicate_self():
	var _new = .duplicate()
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()



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
	_add_point_update()
	return true


func is_shape_closed() -> bool:
	var point_count = _points.get_point_count()
	if not _has_minimum_point_count():
		return false
	var key1 = _points.get_point_key_at_index(0)
	var key2 = _points.get_point_key_at_index(point_count - 1)
	return get_point_constraint(key1, key2) == RMSS2D_Point_Array.CONSTRAINT.ALL


func add_points(verts: Array, starting_index: int = -1, key: int = -1) -> Array:
	return .add_points(verts, adjust_add_point_index(starting_index), key)


func add_point(position: Vector2, index: int = -1, key: int = -1) -> int:
	return .add_point(position, adjust_add_point_index(index), key)


func adjust_add_point_index(index: int) -> int:
	# Don't allow a point to be added after the last point of the closed shape or before the first
	if is_shape_closed():
		if index < 0 or (index > get_point_count() - 1):
			index = max(get_point_count() - 1, 0)
		if index < 1:
			index = 1
	return index


func _add_point_update():
	# Return early if _close_shape() adds another point
	# _add_point_update() will be called again by having another point added
	if _close_shape():
		return
	._add_point_update()


func bake_collision():
	if not has_node(collision_polygon_node_path) or not is_shape_closed():
		return
	var polygon = get_node(collision_polygon_node_path)
	var collision_width = 1.0
	var collision_extends = 0.0
	var verts = get_vertices()
	var t_points = get_tessellated_points()
	if t_points.size() < 2:
		return
	var collision_quads = []
	for i in range(0, t_points.size() - 1, 1):
		var width = _get_width_for_tessellated_point(verts, t_points, i)
		collision_quads.push_back(
			_build_quad_from_point(
				t_points,
				i,
				null,
				null,
				Vector2(collision_size, collision_size),
				width,
				should_flip_edges(),
				i == 0,
				i == t_points.size() - 1,
				collision_width,
				collision_offset - 1.0,
				collision_extends
			)
		)
	_weld_quad_array(collision_quads)
	var first_quad = collision_quads[0]
	var last_quad = collision_quads.back()
	_weld_quads(last_quad, first_quad, 1.0)
	var points: PoolVector2Array = PoolVector2Array()
	# PT A
	for quad in collision_quads:
		points.push_back(
			polygon.get_global_transform().xform_inv(get_global_transform().xform(quad.pt_a))
		)

	polygon.polygon = points


func _on_dirty_update():
	if _dirty:
		clear_cached_data()
		# Close shape
		_close_shape()
		if _has_minimum_point_count():
			bake_collision()
			cache_edges()
			cache_meshes()
		update()
		_dirty = false
		emit_signal("on_dirty_update")
