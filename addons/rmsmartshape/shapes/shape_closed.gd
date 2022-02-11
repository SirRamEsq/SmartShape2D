@tool
extends SS2D_Shape_Base
class_name SS2D_Shape_Closed, "../assets/closed_shape.png"

##########
# CLOSED #
##########
#"""
#A Hole is a closed polygon
#Orientation doesn't matter
#Holes should not intersect each other
#"""
var _holes = []


func set_holes(holes: Array):
	_holes = holes


func get_holes() -> Array:
	return _holes


#########
# GODOT #
#########
func _init():
	super._init()
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


func set_point_array(a: SS2D_Point_Array, make_unique: bool = true):
	if make_unique:
		_points = a.duplicate(true)
	else:
		_points = a
	_close_shape()
	clear_cached_data()
	_update_curve(_points)
	set_as_dirty()
	notify_property_list_changed()


func has_minimum_point_count() -> bool:
	return _points.get_point_count() >= 3


func duplicate_self():
	var _new = super.duplicate()
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
				for m in _build_fill_mesh(get_tessellated_points(), shape_material as RefCounted):
					meshes.push_back(m)
				produced_fill_mesh = true

		# Produce edge Meshes
		for m in e.get_meshes(color_encoding):
			meshes.push_back(m)
	if not produced_fill_mesh:
		for m in _build_fill_mesh(get_tessellated_points(), shape_material as RefCounted):
			meshes.push_back(m)
		produced_fill_mesh = true
	return meshes


func do_edges_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	# """
	# Returns true if line segment 'a1a2' and 'b1b2' intersect.
	# Find the four orientations needed for general and special cases
	# """
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


func _build_fill_mesh(points: Array, s_mat: SS2D_Material_Shape) -> Array:
	var meshes = []
	if s_mat == null:
		return meshes
	if s_mat.fill_textures.is_empty():
		return meshes
	if points.size() < 3:
		return meshes

	var tex = null
	if s_mat.fill_textures.is_empty():
		return meshes
	tex = s_mat.fill_textures[0]
	var tex_normal = null
	if not s_mat.fill_texture_normals.is_empty():
		tex_normal = s_mat.fill_texture_normals[0]
	var tex_size = tex.get_size()

	# Points to produce the fill mesh
	var fill_points: PackedVector2Array = PackedVector2Array()
	var polygons = Geometry2D.offset_polygon_2d(
		PackedVector2Array(points), tex_size.x * s_mat.fill_mesh_offset
	)
	points = polygons[0]
	fill_points.resize(points.size())
	for i in range(points.size()):
		fill_points[i] = points[i]

	# Produce the fill mesh
	var fill_tris: PackedInt32Array = Geometry2D.triangulate_polygon(fill_points)
	if fill_tris.is_empty():
		push_error("'%s': Couldn't Triangulate shape" % name)
		return []

	var st: SurfaceTool
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(0, fill_tris.size() - 1, 3):
		st.add_color(Color.WHITE)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i]].x, points[fill_tris[i]].y, 0))
		st.add_color(Color.WHITE)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 1]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i + 1]].x, points[fill_tris[i + 1]].y, 0))
		st.add_color(Color.WHITE)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 2]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i + 2]].x, points[fill_tris[i + 2]].y, 0))
	st.index()
	st.generate_normals()
	st.generate_tangents()
	var array_mesh = st.commit()
	var flip = false
	var transform = Transform2D()
	var mesh_data = SS2D_Mesh.new(tex, tex_normal, flip, transform, [array_mesh])
	mesh_data.material = s_mat.fill_mesh_material
	mesh_data.z_index = s_mat.fill_texture_z_index
	mesh_data.z_as_relative = true
	meshes.push_back(mesh_data)

	return meshes


func _close_shape() -> bool:
	# """
	# Will mutate the _points to ensure this is a closed_shape
	# last point will be constrained to first point
	# returns true if _points is modified
	# """
	if is_shape_closed():
		return false
	if not has_minimum_point_count():
		return false

	var key_first = _points.get_point_key_at_index(0)
	var key_last = _points.get_point_key_at_index(get_point_count() - 1)

	# If points are not the same pos, add new point
	if get_point_position(key_first) != get_point_position(key_last):
		key_last = _points.add_point(_points.get_point_position(key_first))

	_points.set_constraint(key_first, key_last, SS2D_Point_Array.CONSTRAINT.ALL)
	_add_point_update()
	return true


func is_shape_closed() -> bool:
	var point_count = _points.get_point_count()
	if not has_minimum_point_count():
		return false
	var key1 = _points.get_point_key_at_index(0)
	var key2 = _points.get_point_key_at_index(point_count - 1)
	return get_point_constraint(key1, key2) == SS2D_Point_Array.CONSTRAINT.ALL


func add_points(verts: Array, starting_index: int = -1, key: int = -1) -> Array:
	for i in range(0, verts.size(), 1):
		print("%s | %s" % [i, verts[i]])
	return super.add_points(verts, adjust_add_point_index(starting_index), key)


func add_point(position: Vector2, index: int = -1, key: int = -1) -> int:
	return super.add_point(position, adjust_add_point_index(index), key)


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
	super._add_point_update()


func generate_collision_points():
	var points: PackedVector2Array = PackedVector2Array()
	var collision_width = 1.0
	var collision_extends = 0.0
	var verts = get_vertices()
	var t_points = get_tessellated_points()
	if t_points.size() < 2:
		return points
	var indicies = []
	for i in range(verts.size()):
		indicies.push_back(i)
	var edge_data = SS2D_IndexMap.new(indicies, null)
	# size of 1, has no meaning in a closed shape
	var edge = _build_edge_with_material(edge_data, collision_offset - 1.0, 1)
	_weld_quad_array(edge.quads, false)
	var first_quad = edge.quads[0]
	var last_quad = edge.quads.back()
	weld_quads(last_quad, first_quad, 1.0)
	if not edge.quads.empty():
		for quad in edge.quads:
			if quad.corner == SS2D_Quad.CORNER.NONE:
				points.push_back(quad.pt_a)
			elif quad.corner == SS2D_Quad.CORNER.OUTER:
				points.push_back(quad.pt_d)
			elif quad.corner == SS2D_Quad.CORNER.INNER:
				pass
	return points


func _on_dirty_update():
	if _dirty:
		update_render_nodes()
		clear_cached_data()
		# Close shape
		_close_shape()
		if has_minimum_point_count():
			bake_collision()
			cache_edges()
			cache_meshes()
		update()
		_dirty = false
		emit_signal("on_dirty_update")


func cache_edges():
	if shape_material != null and render_edges:
		_edges = _build_edges(shape_material as RefCounted, get_vertices())
	else:
		_edges = []


func import_from_legacy(legacy: RMSmartShape2D):
	# Sanity Check
	if legacy == null:
		push_error("LEGACY SHAPE IS NULL; ABORTING;")
		return
	if not legacy.closed_shape:
		push_error("OPEN LEGACY SHAPE WAS SENT TO SS2D_SHAPE_CLOSED; ABORTING;")
		return

	# Properties
	editor_debug = legacy.editor_debug
	flip_edges = legacy.flip_edges
	render_edges = legacy.draw_edges
	tessellation_stages = legacy.tessellation_stages
	tessellation_tolerence = legacy.tessellation_tolerence
	curve_bake_interval = legacy.collision_bake_interval
	collision_polygon_node_path = legacy.collision_polygon_node

	# Points
	_points.clear()
	add_points(legacy.get_vertices())
	for i in range(0, legacy.get_point_count(), 1):
		var key = get_point_key_at_index(i)
		set_point_in(key, legacy.get_point_in(i))
		set_point_out(key, legacy.get_point_out(i))
		set_point_texture_index(key, legacy.get_point_texture_index(i))
		set_point_texture_flip(key, legacy.get_point_texture_flip(i))
		set_point_width(key, legacy.get_point_width(i))


#"""
#Differs from the main get_meta_material_index_mapping
#in that the points wrap around
#"""
static func get_meta_material_index_mapping(s_material: SS2D_Material_Shape, verts: Array) -> Array:
	return _get_meta_material_index_mapping(s_material, verts, true)


func _merge_index_maps(imaps:Array, verts:Array) -> Array:
	# See if any edges have both the first (0) and last idx (size)
	# Merge them into one if so
	var final_edges = imaps.duplicate()
	var edges_by_material = SS2D_IndexMap.index_map_array_sort_by_object(final_edges)
	# Erase any with null material
	edges_by_material.erase(null)
	for material in edges_by_material:
		var edge_first_idx = null
		var edge_last_idx = null
		for e in edges_by_material[material]:
			if e.indicies.has(0):
				edge_first_idx = e
			if e.indicies.has(verts.size()-1):
				edge_last_idx = e
			if edge_first_idx != null and edge_last_idx != null:
				break
		if edge_first_idx != null and edge_last_idx != null:
			if edge_first_idx == edge_last_idx:
				pass
			else:
				final_edges.erase(edge_last_idx)
				final_edges.erase(edge_first_idx)
				var indicies = edge_last_idx.indicies + edge_first_idx.indicies
				var merged_edge = SS2D_IndexMap.new(indicies, material)
				final_edges.push_back(merged_edge)

	return final_edges

func _imap_contains_all_points(imap:SS2D_IndexMap, verts:Array)->bool:
	return imap.indicies[0] == 0 and imap.indicies.back() == verts.size()-1

func _is_edge_contiguous(imap:SS2D_IndexMap, verts:Array)->bool:
	var val = _imap_contains_all_points(imap, verts)
	return val
