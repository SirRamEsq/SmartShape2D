tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Closed, "../closed_shape.png"

export (float) var fill_mesh_offset: float = 0.0 setget set_fill_mesh_offset


func set_fill_mesh_offset(f: float):
	fill_mesh_offset = f
	set_as_dirty()


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


static func do_edges_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	"""
	Returns true if line segment 'a1a2' and 'b1b2' intersect.
	Find the four orientations needed for general and special cases
	"""
	var o1: int = get_points_orientation([a1, a2, b1])
	var o2: int = get_points_orientation([a1, a2, b2])
	var o3: int = get_points_orientation([b1, b2, a1])
	var o4: int = get_points_orientation([b1, b2, a2])

	# General case
	if o1 != o2 and o3 != o4:
		return true

	# Special Cases
	# a1, a2 and b1 are colinear and b1 lies on segment p1q1
	if o1 == ORIENTATION.COLINEAR and on_segment(a1, b1, a2):
		return true

	# a1, a2 and b2 are colinear and b2 lies on segment p1q1
	if o2 == ORIENTATION.COLINEAR and on_segment(a1, b2, a2):
		return true

	# b1, b2 and a1 are colinear and a1 lies on segment p2q2
	if o3 == ORIENTATION.COLINEAR and on_segment(b1, a1, b2):
		return true

	# b1, b2 and a2 are colinear and a2 lies on segment p2q2
	if o4 == ORIENTATION.COLINEAR and on_segment(b1, a2, b2):
		return true

	# Doesn't fall in any of the above cases
	return false

static func get_edge_intersection(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2):
	var den = (b2.y - b1.y) * (a2.x - a1.x) - (b2.x - b1.x) * (a2.y - a1.y)

	# Check if lines are parallel or coincident
	if den == 0:
		return null

	var ua = ((b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x)) / den
	var ub = ((a2.x - a1.x) * (a1.y - b1.y) - (a2.y - a1.y) * (a1.x - b1.x)) / den

	if ua < 0 or ub < 0 or ua > 1 or ub > 1:
		return null

	return Vector2(a1.x + ua * (a2.x - a1.x), a1.y + ua * (a2.y - a1.y))

#static func resolve_edge_collisions(points: Array) -> Array:
#var new_points = []
#for p in points:
#new_points.push_back(p)
#
#var intersecting_edges = true
## Keep restarting the for loop until there are no more intersecting edges
#while intersecting_edges:
#intersecting_edges = false
#var merge_index = null
#for i in range(new_points.size() - 1, 1, -1):
#var a1 = new_points[i]
#var a2 = new_points[i - 1]
#var b1 = new_points[i - 2]
#var b2 = new_points[i - 3]
#if do_edges_intersect(a1, a2, b1, b2):
#intersecting_edges = true
#merge_index = i
#break
#
#if merge_index != null:
#var a1 = new_points[merge_index]
#var a2 = new_points[merge_index - 1]
#var b1 = new_points[merge_index - 2]
#var b2 = new_points[merge_index - 3]
#new_points.remove(merge_index - 1)
#new_points.remove(merge_index - 2)
#new_points.insert(merge_index - 1, get_edge_intersection(a1, a2, b1, b2))
#
#return new_points

static func resolve_edge_shrink_collisions(original_points, shrunk_points: Array) -> Array:
	var new_points = []
	for p in shrunk_points:
		new_points.push_back(p)

	var merge_indicies = []
	for i in range(0, original_points.size() - 1, 1):
		var a1 = original_points[i]
		var a2 = original_points[i + 1]
		var b1 = shrunk_points[i]
		var b2 = shrunk_points[i + 1]
		var delta_a_x = a1.x - a2.x
		var delta_a_y = a1.y - a2.y
		var delta_b_x = b1.x - b2.x
		var delta_b_y = b1.y - b2.y

		var x_axis_equal = (a1.x == a2.x)
		var y_axis_equal = (a1.y == a2.y)

		# If shrinking the points has changed the sign of the delta, they need merged
		if ((sign(delta_a_x) != sign(delta_b_x)) ) or (sign(delta_a_y) != sign(delta_b_y)):
			merge_indicies.push_back([i, i + 1])

	# Iterate in reverse order
	var already_merged = []
	for i in range(merge_indicies.size()-1, -1, -1):
		var merge_idx = merge_indicies[i]
		var idx = merge_idx[0]
		var idx_next = merge_idx[1]
		#if already_merged.has(idx) or already_merged.has(idx_next):
			#continue
		already_merged.push_back(idx)
		already_merged.push_back(idx_next)
		var p1 = shrunk_points[idx]
		var p2 = shrunk_points[idx_next]
		new_points.remove(idx_next)
		new_points.remove(idx)
		new_points.insert(idx, (p1 + p2) / 2.0)

	return new_points

static func resolve_edge_shrink_collisions_2(original_points, shrunk_points: Array) -> Array:
	var new_points = []
	for p in shrunk_points:
		new_points.push_back(p)

	var poly_orient = get_points_orientation(original_points)

	var working = true
	while working:
		working = false
		var merge_indicies = []
		for i in range(0, new_points.size(), 1):
			var p1 = new_points[i]
			var i_2 = (i + 1) % new_points.size()
			var i_3 =(i + 2) % new_points.size()
			var p2 = new_points[i_2]
			var p3 = new_points[i_3]

			# If shrinking the points has changed the sign of the delta, they need merged
			var new_orient = get_points_orientation([p1,p2,p3])
			if new_orient != poly_orient and not new_orient == ORIENTATION.COLINEAR:
				merge_indicies = [i, i_2]
				working = true
				break

		if not merge_indicies.empty():
			var idx = min(merge_indicies[0], merge_indicies[1])
			var idx_next = max(merge_indicies[0], merge_indicies[1])
			var p1 = new_points[idx]
			var p2 = new_points[idx_next]
			new_points.remove(idx_next)
			new_points.remove(idx)
			new_points.insert(idx, (p1 + p2) / 2.0)

	return new_points

static func resolve_edge_shrink_collisions_3(original_points, shrunk_points: Array) -> Array:
	var new_points = []
	for p in shrunk_points:
		new_points.push_back(p)

	var poly_orient = get_points_orientation(original_points)

	var merge_indicies = []
	for i in range(0, original_points.size(), 1):
		var i_2 = (i + 1) % new_points.size()
		var i_3 =(i + 2) % new_points.size()

		var a1 = original_points[i]
		var a2 = original_points[i_2]
		var a3 = original_points[i_3]

		var b1 = shrunk_points[i]
		var b2 = shrunk_points[i_2]
		var b3 = shrunk_points[i_3]

		# If shrinking the points has changed the sign of the delta, they need merged
		var orient_a = get_points_orientation([a1,a2,a3])
		var orient_b = get_points_orientation([b1,b2,b3])
		if orient_a != orient_b:# and not new_orient == ORIENTATION.COLINEAR:
			merge_indicies.push_back([i, i_2])

	# Reverse iteration
	for i in range(merge_indicies.size()-1, -1, -1):
		var merge_index = merge_indicies[i]
		var idx = min(merge_index[0], merge_index[1])
		var idx_next = max(merge_index[0], merge_index[1])
		var p1 = new_points[idx]
		var p2 = new_points[idx_next]
		new_points.remove(idx_next)
		new_points.remove(idx)
		new_points.insert(idx, (p1 + p2) / 2.0)

	return new_points

static func scale_points(points: Array, units: float) -> Array:
	var new_points = []
	for i in range(points.size()):
		var i_next = (i + 1) % points.size()
		var i_prev = i - 1
		if i_prev < 0:
			i_prev += points.size()

		var pt = points[i]
		var pt_next = points[i_next]
		var pt_prev = points[i_prev]

		var ab = pt - pt_prev
		var bc = pt_next - pt
		var delta = (ab + bc) / 2.0
		var normal = Vector2(delta.y, -delta.x).normalized()
		var offset = normal * units

		var new_point = Vector2(pt + offset)
		new_points.push_back(new_point)

	new_points[new_points.size()-1] = new_points[0]

	if units < 0:
		return resolve_edge_shrink_collisions_3(points, new_points)

	return new_points


func _build_fill_mesh(points: Array, s_mat: RMSS2D_Material_Shape) -> Array:
	var meshes = []
	if s_mat == null:
		return meshes
	if s_mat.fill_textures.empty():
		return meshes
	if points.size() < 3:
		return meshes

	var tex = null
	if s_mat.fill_textures.empty():
		return meshes
	tex = s_mat.fill_textures[0]
	var tex_normal = null
	if not s_mat.fill_texture_normals.empty():
		tex_normal = s_mat.fill_texture_normals[0]
	var tex_size = tex.get_size()

	# Points to produce the fill mesh
	var fill_points: PoolVector2Array = PoolVector2Array()
	points = scale_points(points, tex_size.x * fill_mesh_offset)
	fill_points.resize(points.size())
	for i in range(points.size()):
		fill_points[i] = points[i]

	# Produce the fill mesh
	var fill_tris: PoolIntArray = Geometry.triangulate_polygon(fill_points)
	if fill_tris.empty():
		push_error("'%s': Couldn't Triangulate shape" % name)
		return []

	var st: SurfaceTool
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(0, fill_tris.size() - 1, 3):
		st.add_color(Color.white)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i]].x, points[fill_tris[i]].y, 0))
		st.add_color(Color.white)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 1]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i + 1]].x, points[fill_tris[i + 1]].y, 0))
		st.add_color(Color.white)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 2]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i + 2]].x, points[fill_tris[i + 2]].y, 0))
	st.index()
	st.generate_normals()
	st.generate_tangents()
	var array_mesh = st.commit()
	var flip = false
	var transform = Transform2D()
	var mesh_data = RMSS2D_Mesh.new(tex, tex_normal, flip, transform, [array_mesh])
	meshes.push_back(mesh_data)

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
