tool
extends Node2D
class_name RMSS2D_Shape_Base

"""
Represents the base functionality for all smart shapes
Functions consist of the following categories
  - Setters / Getters
  - Curve
  - Curve Wrapper
  - Godot
  - Misc

To use search to jump between categories, use the regex:
# .+ #
"""


class EdgeMaterialData:
	var material: RMSS2D_Material_Edge
	var indicies: Array = []

	func _init(i: Array, m: RMSS2D_Material_Edge):
		material = m
		indicies = i


export (bool) var editor_debug: bool = false setget _set_editor_debug
export (Curve2D) var _curve: Curve2D = Curve2D.new() setget set_curve, get_curve
export (int, 1, 8) var tessellation_stages: int = 5 setget set_tessellation_stages
export (float, 1, 8) var tessellation_tolerence: float = 4.0 setget set_tessellation_tolerence
export (float, 1, 512) var collision_bake_interval: float = 20.0 setget set_collision_collision_back_interval
export (NodePath) var collision_polygon_node_path: NodePath = ""
export (Resource) var shape_material = RMSS2D_Material_Shape.new() setget _set_material

var _dirty: bool = true
var _edges: Array = []
var _meshes: Array = []
var _vertex_properties = RMS2D_VertexPropertiesArray.new(0)

signal points_modified
signal on_dirty_update


#####################
# SETTERS / GETTERS #
#####################
func set_curve(value: Curve2D):
	_curve = value
	if _vertex_properties.resize(_curve.get_point_count()):
		set_as_dirty()
		emit_signal("points_modified")
	if Engine.editor_hint:
		property_list_changed_notify()


func get_curve():
	return _curve.duplicate()


func _set_editor_debug(value: bool):
	editor_debug = value
	set_as_dirty()


func set_tessellation_stages(value: int):
	tessellation_stages = value
	set_as_dirty()
	if Engine.editor_hint:
		property_list_changed_notify()


func set_tessellation_tolerence(value: float):
	tessellation_tolerence = value
	set_as_dirty()
	if Engine.editor_hint:
		property_list_changed_notify()


func set_collision_collision_back_interval(f: float):
	collision_bake_interval = f
	_curve.bake_interval = f
	if Engine.editor_hint:
		property_list_changed_notify()


func _set_material(value: RMS2D_Material):
	if (
		shape_material != null
		and shape_material.is_connected("changed", self, "_handle_material_change")
	):
		shape_material.disconnect("changed", self, "_handle_material_change")

	shape_material = value
	if shape_material != null:
		shape_material.connect("changed", self, "_handle_material_change")
	set_as_dirty()


#########
# CURVE #
#########
func get_vertices() -> Array:
	var verts = []
	for i in range(0, _curve.get_point_count(), 1):
		verts.push_back(_curve.get_point_position(i))
	return verts


func get_tessellated_points() -> PoolVector2Array:
	# Point 0 will be the same on both the curve points and the vertecies
	# Point size - 1 will be the same on both the curve points and the vertecies
	var points = _curve.tessellate(tessellation_stages, tessellation_tolerence)
	points[0] = _curve.get_point_position(0)
	points[points.size() - 1] = _curve.get_point_position(_curve.get_point_count() - 1)
	return points


func invert_point_order():
	var verts = get_vertices()

	# Store inverted verts and properties
	var inverted_properties = []
	var inverted = []
	for i in range(0, verts.size(), 1):
		var vert = verts[i]
		var prop = _vertex_properties.properties[i]
		inverted.push_front(vert)
		inverted_properties.push_front(prop)

	# Clear Verts, add Inverted Verts
	_curve.clear_points()
	clear_cached_data()
	add_points_to_curve(inverted, -1, false)

	# Set Inverted Properties
	for i in range(0, inverted_properties.size(), 1):
		var prop = inverted_properties[i]
		_vertex_properties.properties[i] = prop

	# Update and set as dirty
	set_as_dirty()

	if Engine.editor_hint:
		property_list_changed_notify()


func clear_points():
	_curve.clear_points()
	_vertex_properties = RMS2D_VertexPropertiesArray.new(0)
	_edges = []


func add_points_to_curve(verts: Array, starting_index: int = -1, update: bool = true):
	for i in range(0, verts.size(), 1):
		var v = verts[i]
		if starting_index != -1:
			_curve.add_point(v, Vector2.ZERO, Vector2.ZERO, starting_index + i)
			_vertex_properties.add_point(starting_index + i)
		else:
			_curve.add_point(v, Vector2.ZERO, Vector2.ZERO, starting_index)
			_vertex_properties.add_point(starting_index)

	if update:
		_add_point_update()


func add_point_to_curve(position: Vector2, index: int = -1, update: bool = true):
	_curve.add_point(position, Vector2.ZERO, Vector2.ZERO, index)
	_vertex_properties.add_point(index)

	if update:
		_add_point_update()


func _add_point_update():
	set_as_dirty()
	emit_signal("points_modified")

	if Engine.editor_hint:
		property_list_changed_notify()


func _is_curve_index_in_range(i: int) -> bool:
	if _curve.get_point_count() > i and i >= 0:
		return true
	return false


func _is_array_index_in_range(a: Array, i: int) -> bool:
	if a.size() > i and i >= 0:
		return true
	return false


func set_point_position(at_position: int, position: Vector2):
	if _curve != null:
		if _is_curve_index_in_range(at_position):
			_curve.set_point_position(at_position, position)
			set_as_dirty()
			emit_signal("points_modified")


func remove_point(idx: int):
	_curve.remove_point(idx)
	if _vertex_properties.remove_point(idx):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func resize_points(size: int):
	if size < 0:
		size = 0

	_curve.resize(size)
	if _vertex_properties.resize(size):
		set_as_dirty()

		if Engine.editor_hint:
			property_list_changed_notify()


#################
# CURVE WRAPPER #
#################
func set_point_in(idx: int, p: Vector2):
	"""
	point_in controls the edge leading from the previous vertex to this one
	"""
	if _curve != null:
		_curve.set_point_in(idx, p)
		set_as_dirty()
		emit_signal("points_modified")


func set_point_out(idx: int, p: Vector2):
	"""
	point_out controls the edge leading from this vertex to the next
	"""
	if _curve != null:
		_curve.set_point_out(idx, p)
		set_as_dirty()
		emit_signal("points_modified")


func get_point_in(idx: int) -> Vector2:
	if _curve != null:
		return _curve.get_point_in(idx)
	return Vector2(0, 0)


func get_point_out(idx: int) -> Vector2:
	if _curve != null:
		return _curve.get_point_out(idx)
	return Vector2(0, 0)


func get_closest_point(to_point: Vector2):
	if _curve != null:
		return _curve.get_closest_point(to_point)
	return null


func get_closest_offset(to_point: Vector2):
	if _curve != null:
		return _curve.get_closest_offset(to_point)
	return null


func get_point_count():
	if _curve == null:
		return 0
	return _curve.get_point_count()


func get_point_position(idx: int):
	get_point(idx)


func get_point(idx: int):
	if _curve != null:
		if idx < _curve.get_point_count() and idx >= 0:
			return _curve.get_point_position(idx)
	return null


#####################
# VERTEX PROPERTIES #
#####################
func set_point_width(idx: int, width: float):
	if _vertex_properties.set_width(width, idx):
		set_as_dirty()
		emit_signal("points_modified")
		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_width(idx: int) -> float:
	return _vertex_properties.get_width(idx)


func set_point_texture_index(idx: int, tex_idx: int):
	if _vertex_properties.set_texture_idx(tex_idx, idx):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_texture_index(idx: int) -> int:
	return _vertex_properties.get_texture_idx(idx)


func set_point_texture_flip(idx: int, flip: bool):
	if _vertex_properties.set_flip(flip, idx):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_texture_flip(idx: int) -> bool:
	return _vertex_properties.get_flip(idx)


#########
# GODOT #
#########
func _init():
	pass


func _ready():
	if _curve == null:
		_curve = Curve2D.new()


func _draw():
	var _sorted_edges = sort_by_z_index(_edges)
	for e in _sorted_edges:
		var meshes = e.get_meshes()
		for m in meshes:
			m.render()

	if editor_debug and Engine.editor_hint:
		_draw_debug(_sorted_edges)


func _draw_debug(edges: Array):
	for e in edges:
		for q in e.quads:
			q.render_lines()

		for i in range(0, e.quads.size(), 1):
			var q = e.quads[i]
			if not (i % 3 == 0):
				continue
			q.render_points(3, 0.5)

		for i in range(0, e.quads.size(), 1):
			var q = e.quads[i]
			if not ((i + 1) % 3 == 0):
				continue
			q.render_points(2, 0.75)

		for i in range(0, e.quads.size(), 1):
			var q = e.quads[i]
			if not ((i + 2) % 3 == 0):
				continue
			q.render_points(1, 1.0)


func _process(delta):
	if not is_inside_tree():
		return
	_on_dirty_update()


func _exit_tree():
	if shape_material != null:
		if shape_material.is_connected("changed", self, "_handle_material_change"):
			shape_material.disconnect("changed", self, "_handle_material_change")


############
# GEOMETRY #
############


func cache_edges():
	_edges = _build_edges(
		shape_material,
		shape_material.collision_width,
		shape_material.collision_offset,
		shape_material.collision_extends,
		false
	)


func cache_meshes():
	_meshes = _build_meshes(_edges)


func _build_meshes(edges: Array) -> Array:
	var meshes = []

	# Produce edge Meshes
	for e in edges:
		for m in e.get_meshes():
			meshes.push_back(m)

	return meshes


func _build_fill_mesh(points: Array, s_mat: RMSS2D_Material_Shape) -> Array:
	var meshes = []
	if s_mat == null:
		return meshes
	if s_mat.fill_textures.empty():
		return meshes
	if points.size() < 3:
		return meshes

	# Produce Fill Mesh
	var fill_points: PoolVector2Array = PoolVector2Array()
	fill_points.resize(points.size())
	for i in points.size():
		fill_points[i] = points[i]

	var fill_tris: PoolIntArray = Geometry.triangulate_polygon(fill_points)
	if fill_tris.empty():
		push_error("'%s': Couldn't Triangulate shape" % name)
		return []
	var tex = s_mat.textures[0]
	var tex_normal = s_mat.texture_normals[0]
	var tex_size = tex.get_size()
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


func _convert_local_space_to_uv(point: Vector2, size: Vector2) -> Vector2:
	var pt: Vector2 = point
	var rslt: Vector2 = Vector2(pt.x / size.x, pt.y / size.y)
	return rslt


func are_points_clockwise() -> bool:
	var sum = 0.0
	var point_count = _curve.get_point_count()
	for i in point_count:
		var pt = _curve.get_point_position(i)
		var pt2 = _curve.get_point_position((i + 1) % point_count)
		sum += pt.cross(pt2)

	return sum > 0.0


func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)


func _build_quad_from_point(
	points: Array,
	idx: int,
	mat: RMSS2D_Material_Edge,
	width: float,
	clockwise: bool,
	first_point: bool,
	last_point: bool,
	custom_scale: float,
	custom_offset: float,
	custom_extends: float
) -> RMSS2D_Quad:
	var quad = RMSS2D_Quad.new()
	quad.texture = mat.textures[0]
	quad.texture_normal = mat.texture_normals[0]
	quad.color = Color(1.0, 1.0, 1.0, 1.0)
	if quad.texture == null:
		return quad

	var idx_next = _get_next_point_index(idx, points)
	var idx_prev = _get_previous_point_index(idx, points)
	var pt_next = points[idx_next]
	var pt = points[idx]
	var pt_prev = points[idx_prev]

	var delta = pt_next - pt
	var delta_normal = delta.normalized()
	var normal = Vector2(delta.y, -delta.x).normalized()

	var tex_size = quad.texture.get_size()
	# This causes weird rendering if the texture isn't a square
	var vtx: Vector2 = normal * (tex_size * 0.5)
	if not clockwise:
		vtx *= -1

	var offset = vtx * custom_offset
	var final_offset_scale_in = vtx * custom_scale * width
	var final_offset_scale_out = vtx * custom_scale * width

	if first_point:
		pt -= (delta_normal * tex_size * custom_extends)
	if last_point:
		pt_next -= (delta_normal * tex_size * custom_extends)

	quad.pt_a = pt + final_offset_scale_in + offset
	quad.pt_b = pt - final_offset_scale_in + offset
	quad.pt_c = pt_next - final_offset_scale_out + offset
	quad.pt_d = pt_next + final_offset_scale_out + offset

	return quad


func _build_edge(edge_dat: EdgeMaterialData, c_scale: float, c_offset: float, c_extends: float) -> RMSS2D_Edge:
	var edge = RMSS2D_Edge.new()
	var edge_material: RMSS2D_Material_Edge = edge_dat.material
	var t_points = get_tessellated_points()
	var points = get_vertices()

	for i in range(0, edge_dat.indicies.size(), 1):
		var idx = edge_dat.indicies[i]
		var v_idx = get_vertex_idx_from_tessellated_point(t_points, points, idx)
		var v_idx_next = _get_next_point_index(v_idx, points)
		var w1 = _vertex_properties.get_width(v_idx)
		var w2 = _vertex_properties.get_width(v_idx_next)
		var ratio = get_ratio_from_tessellated_point_to_vertex(points, t_points, idx)
		var width = lerp(w1, w2, ratio)
		var is_first_point = idx == edge_dat.indicies[0]
		var is_last_point = idx == edge_dat.indicies[edge.indicies.size() - 1]

		var quad = _build_quad_from_point(
			t_points,
			idx,
			edge_material,
			width,
			are_points_clockwise(),
			is_first_point,
			is_last_point,
			c_scale,
			c_offset,
			c_extends
		)
		edge.quads.push_back(quad)

	if edge_material.weld_quads:
		_weld_quad_array(edge.quads)

	return edge


func _weld_quads(a: RMSS2D_Quad, b: RMSS2D_Quad, custom_scale: float = 1.0):
	var needed_length: float = 0.0
	if a.texture != null and b.texture != null:
		needed_length = ((a.texture.get_size().y + (b.texture.get_size().y * b.width_factor)) / 2.0)

	var pt1 = (a.pt_d + b.pt_a) * 0.5
	var pt2 = (a.pt_c + b.pt_b) * 0.5

	var mid_point: Vector2 = (pt1 + pt2) / 2.0
	var half_line: Vector2 = (pt2 - mid_point).normalized() * needed_length * custom_scale / 2.0

	if half_line != Vector2.ZERO:
		pt2 = mid_point + half_line
		pt1 = mid_point - half_line

	b.pt_a = pt1
	b.pt_b = pt2
	a.pt_d = pt1
	a.pt_c = pt2


func _weld_quad_array(quads: Array, custom_scale: float = 1.0):
	for index in range(quads.size() - 1):
		var this_quad: RMSS2D_Quad = quads[index]
		var next_quad: RMSS2D_Quad = quads[index + 1]
		_weld_quads(this_quad, next_quad, custom_scale)


func _build_edges(
	s_mat: RMSS2D_Material_Shape,
	c_scale: float,
	c_offset: float,
	c_extends: float,
	wrap_around: bool
) -> Array:
	var edges: Array = []
	if s_mat == null:
		return edges

	for edge_material in get_edge_materials(get_tessellated_points(), s_mat, wrap_around):
		edges.push_back(_build_edge(edge_material, c_scale, c_offset, c_extends))
	return edges


func get_edge_materials(points: Array, s_material: RMSS2D_Material_Shape, wrap_around: bool) -> Array:
	var final_edges: Array = []
	var edge_building: Dictionary = {}
	for idx in range(0, points.size(), 1):
		var idx_next = _get_next_point_index(idx, points)
		var pt = points[idx]
		var pt_next = points[idx_next]
		var delta = pt_next - pt
		var delta_normal = delta.normalized()
		var normal = Vector2(delta.y, -delta.x).normalized()

		var edge_meta_materials = s_material.get_edge_materials(normal)

		# Append to existing edges being built. Add new ones if needed
		for e in edge_meta_materials:
			if edge_building.has(e):
				edge_building[e].indicies.push_back(idx)
			else:
				edge_building[e] = EdgeMaterialData.new([idx], e)

		# Closeout and stop building edges that are no longer viable
		for e in edge_building.keys():
			if not edge_meta_materials.has(e):
				final_edges.push_back(edge_building[e])
				edge_building.erase(e)

	# Closeout all edge building
	for e in edge_building.keys():
		final_edges.push_back(edge_building[e])

	# See if edges that contain the final point can be merged with those that contain the first point
	if wrap_around:
		var first_edges = []
		var last_edges = []
		for e in final_edges:
			var has_first = e.indicies.has(_get_first_point_index(points))
			var has_last = e.indicies.has(_get_last_point_index(points))
			# '^' is the XOR operator
			if has_first ^ has_last:
				if has_first:
					first_edges.push_back(e)
				elif has_last:
					last_edges.push_back(e)
			# Contains all points
			elif has_first and has_last:
				pass
		var edges_to_add = []
		var edges_to_remove = []
		for first in first_edges:
			for last in last_edges:
				if first.material == last.material:
					var merged = []
					for i in last.indicies:
						merged.push_back(i)
					for i in first.indicies:
						merged.push_back(i)
					var new_edge = EdgeMaterialData.new(merged, first.material)
					edges_to_add.push_back(new_edge)
					if not edges_to_remove.has(first):
						edges_to_remove.push_back(first)
					if not edges_to_remove.has(last):
						edges_to_remove.push_back(last)
		for e in edges_to_remove:
			var i = final_edges.find(e)
			final_edges.remove(i)
		for e in edges_to_add:
			final_edges.push_back(e)

	return final_edges


########
# MISC #
########
func _handle_material_change():
	set_as_dirty()


func set_as_dirty():
	_dirty = true


func get_collision_polygon_node() -> Node:
	if collision_polygon_node_path == null:
		return null
	if not has_node(collision_polygon_node_path):
		return null
	return get_node(collision_polygon_node_path)


static func sort_by_z_index(a: Array) -> Array:
	a.sort_custom(RMSS2D_Common_Functions, "sort_z")
	return a


func clear_cached_data():
	_edges = []
	_meshes = []


func _on_dirty_update():
	if _dirty:
		update()
		cache_edges()
		cache_meshes()
		_dirty = false
		emit_signal("on_dirty_update")


func _get_first_point_index(points: Array) -> int:
	return 0


func _get_last_point_index(points: Array) -> int:
	return points.size() - 1


func _get_next_point_index(idx: int, points: Array) -> int:
	return int(min(idx + 1, points.size() - 1))


func _get_previous_point_index(idx: int, points: Array) -> int:
	return int(max(idx - 1, 0))


func get_ratio_from_tessellated_point_to_vertex(points: Array, t_points: Array, t_point_idx: int) -> float:
	"""
	Returns a float between 0.0 and 1.0
	0.0 means that this tessellated point is at the same position as the vertex
	0.5 means that this tessellated point is half-way between this vertex and the next
	0.999 means that this tessellated point is basically at the next vertex
	1.0 isn't going to happen; If a tess point is at the same position as a vert, it gets a ratio of 0.0
	"""
	if t_point_idx == 0:
		return 0.0

	var vertex_idx = 0
	# The total tessellated points betwen two verts
	var tess_point_count = 0
	# The index of the passed t_point_idx relative to the starting vert
	var tess_index_count = 0
	for i in range(0, t_points.size(), 1):
		var tp = t_points[i]
		var p = points[vertex_idx]
		tess_point_count += 1

		if i <= t_point_idx:
			tess_index_count += 1

		if tp == p:
			if i < t_point_idx:
				vertex_idx += 1
				tess_point_count = 0
				tess_index_count = 0
			else:
				break

	var result = fmod(float(tess_index_count) / float(tess_point_count), 1.0)
	return result


func get_vertex_idx_from_tessellated_point(points: Array, t_points: Array, t_point_idx: int) -> int:
	if t_point_idx == 0:
		return 0

	var vertex_idx = -1
	for i in range(0, t_point_idx + 1, 1):
		var tp = t_points[i]
		var p = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
	return vertex_idx


func get_tessellated_idx_from_point(points: Array, t_points: Array, point_idx: int) -> int:
	if point_idx == 0:
		return 0

	var vertex_idx = -1
	var tess_idx = 0
	for i in range(0, t_points.size(), 1):
		tess_idx = i
		var tp = t_points[i]
		var p = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
		if vertex_idx == point_idx:
			break
	return tess_idx


func duplicate_self():
	var _new = __new()
	_new.editor_debug = editor_debug
	_new.set_curve(get_curve())
	_new.tessellation_stages = tessellation_stages
	_new.tessellation_tolerence = tessellation_tolerence
	_new.collision_bake_interval = collision_bake_interval
	_new.collision_polygon_node_path = ""
	_new.set_as_dirty()
	for i in range(0, get_vertices().size(), 1):
		_new.set_point_width(i, get_point_width(i))
		_new.set_point_texture_index(i, get_point_texture_index(i))
		_new.set_point_texture_flip(i, get_point_texture_flip(i))
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()