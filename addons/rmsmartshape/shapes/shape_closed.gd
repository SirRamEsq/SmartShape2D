@tool
@icon("../assets/closed_shape.png")
extends SS2D_Shape_Base
class_name SS2D_Shape_Closed

##########
# CLOSED #
##########

# A Hole is a closed polygon
# Orientation doesn't matter
# Holes should not intersect each other

# FIXME: unused member.
#var _holes = []


# FIXME: unused method.
#func set_holes(holes: Array):
#	_holes = holes


# FIXME: unused method.
#func get_holes() -> Array:
#	return _holes


#########
# GODOT #
#########

func _init() -> void:
	super._init()
	_is_instantiable = true


############
# OVERRIDE #
############

func _point_array_assigned() -> void:
	close_shape()


func has_minimum_point_count() -> bool:
	return _points.get_point_count() > 3


func _build_meshes(edges: Array[SS2D_Edge]) -> Array[SS2D_Mesh]:
	var meshes: Array[SS2D_Mesh] = []

	var produced_fill_mesh := false
	for e in edges:
		if not produced_fill_mesh:
			if e.z_index > shape_material.fill_texture_z_index:
				# Produce Fill Meshes
				for m in _build_fill_mesh(get_tessellated_points(), shape_material):
					meshes.push_back(m)
				produced_fill_mesh = true

		# Produce edge Meshes
		for m in e.get_meshes(color_encoding):
			meshes.push_back(m)
	if not produced_fill_mesh:
		for m in _build_fill_mesh(get_tessellated_points(), shape_material):
			meshes.push_back(m)
		produced_fill_mesh = true
	return meshes


## Returns true if line segment 'a1a2' and 'b1b2' intersect.[br]
## Find the four orientations needed for general and special cases.[br]
func do_edges_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
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


static func get_edge_intersection(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> Variant:
	var den: float = (b2.y - b1.y) * (a2.x - a1.x) - (b2.x - b1.x) * (a2.y - a1.y)

	# Check if lines are parallel or coincident
	if den == 0:
		return null

	var ua: float = ((b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x)) / den
	var ub: float = ((a2.x - a1.x) * (a1.y - b1.y) - (a2.y - a1.y) * (a1.x - b1.x)) / den

	if ua < 0 or ub < 0 or ua > 1 or ub > 1:
		return null

	return Vector2(a1.x + ua * (a2.x - a1.x), a1.y + ua * (a2.y - a1.y))


func _build_fill_mesh(points: PackedVector2Array, s_mat: SS2D_Material_Shape) -> Array[SS2D_Mesh]:
	var meshes: Array[SS2D_Mesh] = []
	if s_mat == null:
		return meshes
	if s_mat.fill_textures.is_empty():
		return meshes
	if points.size() < 3:
		return meshes

	var tex: Texture2D = null
	if s_mat.fill_textures.is_empty():
		return meshes
	tex = s_mat.fill_textures[0]
	var tex_size: Vector2 = tex.get_size()

	# Points to produce the fill mesh
	var fill_points: PackedVector2Array = PackedVector2Array()
	var polygons: Array[PackedVector2Array] = Geometry2D.offset_polygon(
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
		st.set_color(Color.WHITE)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i]].x, points[fill_tris[i]].y, 0))
		st.set_color(Color.WHITE)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 1]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i + 1]].x, points[fill_tris[i + 1]].y, 0))
		st.set_color(Color.WHITE)
		_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 2]], tex_size))
		st.add_vertex(Vector3(points[fill_tris[i + 2]].x, points[fill_tris[i + 2]].y, 0))
	st.index()
	st.generate_normals()
	st.generate_tangents()
	var array_mesh := st.commit()
	var flip := false
	var trans := Transform2D()
	var mesh_data := SS2D_Mesh.new(tex, flip, trans, [array_mesh])
	mesh_data.material = s_mat.fill_mesh_material
	mesh_data.z_index = s_mat.fill_texture_z_index
	mesh_data.z_as_relative = true
	mesh_data.show_behind_parent = s_mat.fill_texture_show_behind_parent
	meshes.push_back(mesh_data)

	return meshes


## Is this shape not yet closed but should be?
func can_close() -> bool:
	return _points.get_point_count() > 2 and _has_closing_point() == false


## Will mutate the _points to ensure this is a closed_shape.[br]
## Last point will be constrained to first point.[br]
## Returns key of a point used to close the shape.[br]
## [param key] suggests which key to use instead of auto-generated.[br]
func close_shape(key: int = -1) -> int:
	if not can_close():
		return -1

	var key_first: int = _points.get_point_key_at_index(0)
	var key_last: int = _points.get_point_key_at_index(_points.get_point_count() - 1)

	if get_point_position(key_first) != get_point_position(key_last):
		key_last = _points.add_point(_points.get_point_position(key_first), -1, key)
	_points.set_constraint(key_first, key_last, SS2D_Point_Array.CONSTRAINT.ALL)

	return key_last


func is_shape_closed() -> bool:
	if _points.get_point_count() < 4:
		return false
	return _has_closing_point()


func _has_closing_point() -> bool:
	if _points.get_point_count() < 2:
		return false
	var key1: int = _points.get_point_key_at_index(0)
	var key2: int = _points.get_point_key_at_index(_points.get_point_count() - 1)
	return get_point_constraint(key1, key2) == SS2D_Point_Array.CONSTRAINT.ALL


func adjust_add_point_index(index: int) -> int:
	# Don't allow a point to be added after the last point of the closed shape or before the first
	if _has_closing_point():
		if index < 0 or (index > get_point_count() - 1):
			index = maxi(get_point_count() - 1, 0)
		if index < 1:
			index = 1
	return index


func generate_collision_points() -> PackedVector2Array:
	var points := PackedVector2Array()
#	var collision_width := 1.0
#	var collision_extends := 0.0
	var verts: PackedVector2Array = get_vertices()
	var t_points: PackedVector2Array = get_tessellated_points()
	if t_points.size() < 2:
		return points
	var indicies: Array[int] = []
	for i in range(verts.size()):
		indicies.push_back(i)
	var edge_data := SS2D_IndexMap.new(indicies, null)
	# size of 1, has no meaning in a closed shape
	var edge: SS2D_Edge = _build_edge_with_material(edge_data, collision_offset - 1.0, 1)
	_weld_quad_array(edge.quads, false)
	var first_quad: SS2D_Quad = edge.quads[0]
	var last_quad: SS2D_Quad = edge.quads.back()
	weld_quads(last_quad, first_quad, 1.0)
	if not edge.quads.is_empty():
		for quad in edge.quads:
			if quad.corner == SS2D_Quad.CORNER.NONE:
				points.push_back(quad.pt_a)
			elif quad.corner == SS2D_Quad.CORNER.OUTER:
				points.push_back(quad.pt_d)
			elif quad.corner == SS2D_Quad.CORNER.INNER:
				pass
	return points


func cache_edges() -> void:
	if shape_material != null and render_edges:
		_edges = _build_edges(shape_material, get_vertices())
	else:
		_edges = []


## Differs from the main get_meta_material_index_mapping
## in that the points wrap around.
func _get_meta_material_index_mapping(s_material: SS2D_Material_Shape, verts: PackedVector2Array) -> Array[SS2D_IndexMap]:
	return get_meta_material_index_mapping(s_material, verts, true)


func _merge_index_maps(imaps: Array[SS2D_IndexMap], verts: PackedVector2Array) -> Array[SS2D_IndexMap]:
	# See if any edges have both the first (0) and last idx (size)
	# Merge them into one if so
	var final_edges: Array[SS2D_IndexMap] = imaps.duplicate()
	var edges_by_material: Dictionary = SS2D_IndexMap.index_map_array_sort_by_object(final_edges)
	# Erase any with null material
	edges_by_material.erase(null)
	for mat in edges_by_material:
		var edge_first_idx: SS2D_IndexMap = null
		var edge_last_idx: SS2D_IndexMap = null
		for e in edges_by_material[mat]:
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
				var indicies: Array[int] = []
				indicies.append_array(edge_last_idx.indicies)
				indicies.append_array(edge_first_idx.indicies)
				var merged_edge := SS2D_IndexMap.new(indicies, mat)
				final_edges.push_back(merged_edge)

	return final_edges


func _imap_contains_all_points(imap: SS2D_IndexMap, verts: PackedVector2Array) -> bool:
	return imap.indicies[0] == 0 and imap.indicies.back() == verts.size()-1


func _is_edge_contiguous(imap: SS2D_IndexMap, verts: PackedVector2Array) -> bool:
	return _imap_contains_all_points(imap, verts)
