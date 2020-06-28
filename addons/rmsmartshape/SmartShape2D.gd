tool
extends Node2D
class_name SmartShape2D, "shape.png"

"""
- This class assumes that points are in clockwise orientation
- This class does not support polygons with a counter-clockwise orientation
	- To remedy this, it contains functions to detect and invert the orientation if needed
		- Inverting the orientation will need to be called by the code using this class
		- Inverting the orientation isn't autmoatically done by the class
			- This would change the indices of points and would cause weird issues
"""

enum TEXTURE_STYLE { LEFT_CORNER, RIGHT_CORNER, LEFT_TAPER, RIGHT_TAPER, EDGE, FILL }


func _style_to_string(d: int) -> String:
	match d:
		TEXTURE_STYLE.EDGE:
			return "EDGE"
		TEXTURE_STYLE.FILL:
			return "FILL"
		TEXTURE_STYLE.LEFT_CORNER:
			return "LEFT_CORNER"
		TEXTURE_STYLE.RIGHT_CORNER:
			return "RIGHT_CORNER"
		TEXTURE_STYLE.LEFT_TAPER:
			return "LEFT_TAPER"
		TEXTURE_STYLE.RIGHT_TAPER:
			return "RIGHT_TAPER"
	return "???"


func _is_corner_style(s: int) -> bool:
	match s:
		TEXTURE_STYLE.LEFT_CORNER:
			return true
		TEXTURE_STYLE.RIGHT_CORNER:
			return true
	return false


func _is_taper_style(s: int) -> bool:
	match s:
		TEXTURE_STYLE.LEFT_TAPER:
			return true
		TEXTURE_STYLE.RIGHT_TAPER:
			return true
	return false


class EdgeData:
	var indicies: Array = []
	var material: RMSS2D_Material_Edge_Metadata = null

	func _init(a: Array, m: RMSS2D_Material_Edge_Metadata):
		indicies = a
		material = m


class MeshInfo:
	extends Reference
	"""
	Used to organize all requested meshes to be rendered by their texture
	"""
	var texture: Texture = null
	var normal_texture: Texture = null
	var texture_style: int = TEXTURE_STYLE.FILL
	var rotation: float = 0
	var z_index: int = 0
	var meshes: Array = []


class QuadArray:
	var quads: Array = []
	var edge: EdgeData = null

	func _init(q: Array, e: EdgeData):
		quads = q
		edge = e


class QuadInfo:
	extends Reference
	"""
	Used to describe the welded quads that form the edge data
	"""
	var pt_a: Vector2
	var pt_b: Vector2
	var pt_c: Vector2
	var pt_d: Vector2

	var texture: Texture = null
	var normal_texture: Texture = null
	var texture_style: int
	var edge_material: RMSS2D_Material_Edge = null
	var color: Color = Color(1.0, 1.0, 1.0, 1.0)

	var flip_texture: bool = false
	var width_factor: float = 1.0
	var control_point_index: int

	func get_rotation() -> float:
		return RMSS2D_NormalRange.get_angle_from_vector(pt_c - pt_a)

	func get_length() -> float:
		return (pt_d.distance_to(pt_a) + pt_c.distance_to(pt_b)) / 2.0

	func different_render(q: QuadInfo) -> bool:
		"""
		Will return true if this quad is part of a different render sequence than q
		"""
		if (
			q.texture_style != texture_style
			or q.texture != texture
			or q.flip_texture != flip_texture
			or q.normal_texture != normal_texture
		):
			return true
		return false


export (bool) var editor_debug = null setget set_editor_debug
export (Curve2D) var _curve: Curve2D = null setget set_curve, get_curve
export (bool) var closed_shape = false setget set_close_shape
export (int, 1, 8) var tessellation_stages = 5 setget set_tessellation_stages
export (float, 1, 8) var tessellation_tolerence = 4.0 setget set_tolerence
export (NodePath) var collision_polygon_node_path setget set_collision_polygon_node
export (float, 1, 512) var collision_bake_interval = 20.0 setget set_collision_collision_back_interval
export (bool) var draw_edges: bool = true setget set_draw_edges

export (Resource) var shape_material = RMSS2D_Material_Shape.new() setget _set_material

# This will set true if it is time to rebake mesh, should prevent unnecessary
# mesh creation unless a change to a property deems it necessary
var _dirty: bool = true

var vertex_properties = RMS2D_VertexPropertiesArray.new(0)

# For rendering fill and edges
var meshes: Array = Array()
var _quads: Array

# Reduce clockwise check if points don't change
var is_clockwise: bool = false setget , are_points_clockwise

# Signals
signal points_modified
signal on_dirty_update


#####################
# SETTERS / GETTERS #
#####################
func set_tessellation_stages(value: int):
	tessellation_stages = value
	set_as_dirty()
	if Engine.editor_hint:
		property_list_changed_notify()


func set_tolerence(value: float):
	tessellation_tolerence = value
	set_as_dirty()
	if Engine.editor_hint:
		property_list_changed_notify()


func _set_material(value: RMS2D_Material):
	if shape_material != null:
		if shape_material.is_connected("changed", self, "_handle_material_change"):
			shape_material.disconnect("changed", self, "_handle_material_change")

	shape_material = value
	if shape_material != null:
		shape_material.connect("changed", self, "_handle_material_change")
	set_as_dirty()
	if Engine.editor_hint:
		property_list_changed_notify()


func set_close_shape(value):
	closed_shape = value
	fix_close_shape()
	if Engine.editor_hint:
		property_list_changed_notify()


func set_curve(value: Curve2D):
	_curve = value

	if vertex_properties.resize(_curve.get_point_count()):
		set_as_dirty()
		emit_signal("points_modified")
	if Engine.editor_hint:
		property_list_changed_notify()


func get_curve():
	return _curve.duplicate()


func set_editor_debug(value: bool):
	editor_debug = value
	set_as_dirty()
	if Engine.editor_hint:
		property_list_changed_notify()


func set_draw_edges(v: bool):
	draw_edges = v
	set_as_dirty()
	if Engine.editor_hint:
		property_list_changed_notify()


func set_collision_polygon_node(np: NodePath):
	collision_polygon_node_path = np
	if Engine.editor_hint:
		property_list_changed_notify()


func set_collision_collision_back_interval(f: float):
	collision_bake_interval = f
	_curve.bake_interval = f
	if Engine.editor_hint:
		property_list_changed_notify()


#####################
# VERTEX PROPERTIES #
#####################
func set_point_width(width: float, at_position: int):
	if vertex_properties.set_width(width, at_position):
		set_as_dirty()
		emit_signal("points_modified")
		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_width(at_position: int) -> float:
	return vertex_properties.get_width(at_position)


func set_point_texture_index(point_index: int, tex_index: int):
	if vertex_properties.set_texture_idx(tex_index, point_index):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_texture_index(at_position: int) -> int:
	return vertex_properties.get_texture_idx(at_position)


func set_point_texture_flip(flip: bool, at_position: int):
	if vertex_properties.set_flip(flip, at_position):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_texture_flip(at_position: int) -> bool:
	return vertex_properties.get_flip(at_position)


#########
# GODOT #
#########
func _init():
	pass


func _ready():
	if _curve == null:
		_curve = Curve2D.new()


func _process(delta):
	if not is_inside_tree():
		return
	_on_dirty_update()


func _enter_tree():
	pass


func _exit_tree():
	if shape_material != null:
		if shape_material.is_connected("changed", self, "_handle_material_change"):
			shape_material.disconnect("changed", self, "_handle_material_change")


func _draw():
	if not is_inside_tree():
		return

	# Assume that meshes array is already sorted by z_index

	# Draw fill
	var mesh_transform = Transform2D()
	for mesh_info in meshes:
		for mesh in mesh_info.meshes:
			draw_mesh(mesh, mesh_info.texture, mesh_info.normal_texture, mesh_transform)

	# Draw edge quads for debug purposes (ONLY IN EDITOR)
	if Engine.editor_hint and editor_debug:
		for q in _quads:
			var t: QuadInfo = q
			draw_line(t.pt_a, t.pt_b, t.color)
			draw_line(t.pt_b, t.pt_c, t.color)
			draw_line(t.pt_c, t.pt_d, t.color)
			draw_line(t.pt_d, t.pt_a, t.color)

		var _range
		if not closed_shape:
			_range = range(1, _quads.size())
		else:
			_range = range(_quads.size())

		# Draw quad verts
		# Skip the first ad last vert if the shape isn't closed
		for index in _range:
			if (
				not (index % 3 == 0)
				or (not closed_shape and (index == 0 or index == _quads.size()))
			):
				continue
			var this_quad: QuadInfo = _quads[index % _quads.size()]
			_draw_quad_verts(this_quad, 3, 0.5)
		for index in _range:
			if (
				not ((index + 1) % 3 == 0)
				or (not closed_shape and (index == 0 or index == _quads.size()))
			):
				continue
			var this_quad: QuadInfo = _quads[index % _quads.size()]
			_draw_quad_verts(this_quad, 2, 0.75)
		for index in _range:
			if (
				not ((index + 2) % 3 == 0)
				or (not closed_shape and (index == 0 or index == _quads.size()))
			):
				continue
			var this_quad: QuadInfo = _quads[index % _quads.size()]
			_draw_quad_verts(this_quad, 1, 1.0)


#########
# CURVE #
#########
func get_tessellated_points() -> PoolVector2Array:
	# Point 0 will be the same on both the curve points and the vertecies
	# Point size - 1 will be the same on both the curve points and the vertecies
	var points = _curve.tessellate(tessellation_stages, tessellation_tolerence)
	points[0] = _curve.get_point_position(0)
	points[points.size() - 1] = _curve.get_point_position(_curve.get_point_count() - 1)
	return points


func get_vertices() -> Array:
	var verts = []
	for i in range(0, _curve.get_point_count(), 1):
		verts.push_back(_curve.get_point_position(i))
	return verts


func invert_point_order():
	var verts = get_vertices()

	# Store inverted verts and properties
	var inverted_properties = []
	var inverted = []
	for i in range(0, verts.size(), 1):
		var vert = verts[i]
		var prop = vertex_properties.properties[i]
		inverted.push_front(vert)
		inverted_properties.push_front(prop)

	# Clear Verts, add Inverted Verts
	_curve.clear_points()
	_quads = []
	meshes = []
	add_points_to_curve(inverted, -1, false)

	# Set Inverted Properties
	for i in range(0, inverted_properties.size(), 1):
		var prop = inverted_properties[i]
		vertex_properties.properties[inverted_properties.size() - i] = prop

	# Update and set as dirty
	set_as_dirty()

	if Engine.editor_hint:
		property_list_changed_notify()


func clear_points():
	_curve.clear_points()
	vertex_properties = RMS2D_VertexPropertiesArray.new(0)
	_quads = []
	meshes = []


func add_points_to_curve(verts: Array, starting_index: int = -1, update: bool = true):
	for i in range(0, verts.size(), 1):
		var v = verts[i]
		if starting_index != -1:
			_curve.add_point(v, Vector2.ZERO, Vector2.ZERO, starting_index + i)
			vertex_properties.add_point(starting_index + i)
		else:
			_curve.add_point(v, Vector2.ZERO, Vector2.ZERO, starting_index)
			vertex_properties.add_point(starting_index)

	if update:
		_add_point_update()


func add_point_to_curve(position: Vector2, index: int = -1, update: bool = true):
	_curve.add_point(position, Vector2.ZERO, Vector2.ZERO, index)
	vertex_properties.add_point(index)

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


func set_point_position(at_position: int, position: Vector2):
	if _curve != null:
		if _is_curve_index_in_range(at_position):
			_curve.set_point_position(at_position, position)
			set_as_dirty()
			emit_signal("points_modified")


func remove_point(idx: int):
	_curve.remove_point(idx)
	if vertex_properties.remove_point(idx):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func resize_points(size: int):
	if size < 0:
		size = 0

	_curve.resize(size)
	if vertex_properties.resize(size):
		set_as_dirty()

		if Engine.editor_hint:
			property_list_changed_notify()


#################
# CURVE WRAPPER #
#################
func set_point_in(idx: int, p: Vector2):
	if _curve != null:
		_curve.set_point_in(idx, p)
		set_as_dirty()
		emit_signal("points_modified")


func set_point_out(idx: int, p: Vector2):
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


func get_point_position(at_position: int):
	if _curve != null:
		if at_position < _curve.get_point_count() and at_position >= 0:
			return _curve.get_point_position(at_position)
	return null


########
# MISC #
########
func _in_range(v: float, low: float, high: float) -> bool:
	return (v >= low) and (v <= high)


static func sort_by_z(a: Array) -> Array:
	a.sort_custom(RMSS2D_Common_Functions, "sort_z")
	return a


func _draw_quad_verts(q: QuadInfo, rad: float, intensity: float):
	draw_circle(q.pt_a, rad, Color(intensity, 0, 0))
	draw_circle(q.pt_b, rad, Color(0, 0, intensity))
	draw_circle(q.pt_c, rad, Color(0, intensity, 0))
	draw_circle(q.pt_d, rad, Color(intensity, 0, intensity))


func _on_dirty_update():
	if _dirty:
		fix_close_shape()
		#bake_collision()
		#bake_mesh()
		update()
		_dirty = false
		emit_signal("on_dirty_update")


func _is_array_index_in_range(a: Array, i: int) -> bool:
	if a.size() > i and i >= 0:
		return true
	return false


func set_as_dirty():
	_dirty = true


func _handle_material_change():
	set_as_dirty()


func fix_close_shape():
	var point_count = get_point_count()
	var first_point = _curve.get_point_position(0)
	var final_point = _curve.get_point_position(point_count - 1)
	if closed_shape and first_point != final_point:
		add_point_to_curve(get_point_position(0))
		set_as_dirty()
	elif (
		not closed_shape
		and get_point_position(0) == get_point_position(point_count - 1)
		and point_count > 2
	):
		remove_point(point_count - 1)
		set_as_dirty()


func _get_next_point_index(idx: int, points: Array, closed: bool) -> int:
	var new_idx = idx
	if closed_shape:
		new_idx = (idx + 1) % points.size()
	else:
		new_idx = int(min(idx + 1, points.size() - 1))

	# First and last point are the same when closed
	if points[idx] == points[new_idx] and closed:
		new_idx = _get_next_point_index(new_idx, points, closed)
	return new_idx


func _get_previous_point_index(idx: int, points: Array, closed: bool) -> int:
	var new_idx = idx
	if closed_shape:
		new_idx = idx - 1
		if new_idx < 0:
			new_idx += points.size()
	else:
		new_idx = int(max(idx - 1, 0))

	# First and last point are the same when closed
	if points[idx] == points[new_idx] and closed:
		new_idx = _get_previous_point_index(new_idx, points, closed)
	return new_idx


# TODO
# NEEDS TESTED
func get_vertex_idx_from_tessellated_point(points: Array, tess_points: Array, tess_point_idx: int) -> int:
	if tess_point_idx == 0:
		return 0

	var vertex_idx = -1
	for i in range(0, tess_point_idx + 1, 1):
		var tp = tess_points[i]
		var p = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
	return vertex_idx


# TODO
# NEEDS TESTED
func get_tessellated_idx_from_point(points: Array, tess_points: Array, point_idx: int) -> int:
	if point_idx == 0:
		return 0

	var vertex_idx = -1
	var tess_idx = 0
	for i in range(0, tess_points.size(), 1):
		tess_idx = i
		var tp = tess_points[i]
		var p = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
		if vertex_idx == point_idx:
			break
	return tess_idx


# TODO
# NEEDS TESTED
func get_distance_as_ratio_from_tessellated_point(
	points: Array, tess_points: Array, tess_point_idx: int
) -> float:
	"""
	Returns a float between 0.0 and 1.0
	0.0 means that this tessellated point is at the same position as the vertex
	0.5 means that this tessellated point is half way between this vertex and the next
	0.999 means that this tessellated point is basically at the next vertex
	1.0 isn't going to happen; If a tess point is at the same position as a vert, it gets a ratio of 0.0
	"""
	if tess_point_idx == 0:
		return 0.0

	var vertex_idx = -1
	# The total tessellated points betwen two verts
	var tess_point_count = 0
	# The index of the passed tess_point_idx relative to the starting vert
	var tess_index_count = 0
	for i in range(0, tess_points.size(), 1):
		var tp = tess_points[i]
		var p = points[vertex_idx + 1]
		tess_point_count += 1
		if i < tess_point_idx:
			tess_index_count += 1
		if tp == p:
			if i < tess_point_idx:
				vertex_idx += 1
				tess_point_count = 0
				tess_index_count = 0
			else:
				break

	return float(tess_index_count) / float(tess_point_count)


############
# GEOMETRY #
############
func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)


func _convert_local_space_to_uv(point: Vector2, custom_size: Vector2 = Vector2(0, 0)):
	var pt: Vector2 = point
	var tex_size = Vector2(0, 0)
	if custom_size != Vector2(0, 0):
		tex_size = custom_size
	else:
		tex_size = shape_material.fill_texture.get_size()

	var size: Vector2 = tex_size  #* Vector2(1.0 / scale.x, 1.0 / scale.y)
	var rslt: Vector2 = Vector2(pt.x / size.x, pt.y / size.y)
	return rslt


func are_points_clockwise() -> bool:
	var sum = 0.0
	var point_count = _curve.get_point_count()
	for i in point_count:
		var pt = _curve.get_point_position(i)
		var pt2 = _curve.get_point_position((i + 1) % point_count)
		sum += pt.cross(pt2)

	is_clockwise = sum > 0.0
	return is_clockwise


func bake_mesh(force: bool = false):
	if not _dirty and not force:
		return
	# Clear Meshes
	for mesh in meshes:
		if mesh.meshes != null:
			mesh.meshes.clear()

	var points = get_tessellated_points()
	var point_count = points.size()
	# Cant make a mesh without enough points
	if (closed_shape and point_count < 3) or (not closed_shape and point_count < 2):
		return

	var is_clockwise: bool = are_points_clockwise()
	_quads = Array()

	# Produce Fill Mesh
	var fill_points: PoolVector2Array = PoolVector2Array()
	fill_points.resize(point_count)
	for i in point_count:
		fill_points[i] = points[i]

	var fill_tris: PoolIntArray = Geometry.triangulate_polygon(fill_points)
	var st: SurfaceTool

	if closed_shape and shape_material.fill_texture != null:
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		for i in range(0, fill_tris.size() - 1, 3):
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i]]))
			st.add_vertex(Vector3(points[fill_tris[i]].x, points[fill_tris[i]].y, 0))
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 1]]))
			st.add_vertex(Vector3(points[fill_tris[i + 1]].x, points[fill_tris[i + 1]].y, 0))
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 2]]))
			st.add_vertex(Vector3(points[fill_tris[i + 2]].x, points[fill_tris[i + 2]].y, 0))
		st.index()
		st.generate_normals()
		st.generate_tangents()
		_add_mesh(
			st.commit(),
			shape_material.fill_texture,
			shape_material.fill_texture_normal,
			TEXTURE_STYLE.FILL
		)

	if closed_shape and not draw_edges:
		return

	# Build Edge Quads
	_quads = _build_quads_edges(1.0, shape_material.render_offset)
	_adjust_mesh_quads(_quads)


func _get_textures_from_edge_material(
	edge_material: RMSS2D_Material_Edge,
	p: Vector2,
	p_next: Vector2,
	is_corner: bool,
	is_first_point: bool,
	is_last_point: bool
) -> Array:
	"""
	Will return an array of two textures and the style
	[0] = diffuse
	[1] = normal
	[2] = style
	"""

	var texture = null
	var texture_normal = null
	var texture_style = -1
	if shape_material == null or edge_material == null:
		return [texture, texture_normal, texture_style]

	var is_taper = is_first_point or is_last_point
	if is_corner:
		#TODO, how to decide which corner texture?
		texture_style = TEXTURE_STYLE.CORNER_LEFT
		texture = edge_material.texture_corner_left
		texture_normal = edge_material.texture_normal_corner_left

	if is_taper and texture == null:
		if is_first_point:
			texture_style = TEXTURE_STYLE.LEFT_TAPER
			texture = edge_material.texture_taper_left
			texture_normal = edge_material.texture_normal_taper_left
		elif is_last_point:
			texture_style = TEXTURE_STYLE.RIGHT_TAPER
			texture = edge_material.texture_taper_right
			texture_normal = edge_material.texture_normal_taper_right

	if not edge_material.textures.empty() and texture == null:
		texture_style = TEXTURE_STYLE.EDGE
		var textures_diffuse = edge_material.textures
		var textures_normal = edge_material.texture_normals
		var tex_index = 0

		tex_index = (abs(vertex_properties.get_texture_idx(pt_index)) % textures_diffuse.size())
		if textures_diffuse.size() > tex_index:
			texture = textures_diffuse[tex_index]
		if textures_normal != null:
			if textures_normal.size() > tex_index:
				tex_normal = textures_normal[tex_index]
	return [texture, texture_normal, texture_style]


func _get_edge_material_meta_from_delta(delta: Vector2) -> RMSS2D_Material_Edge_Metadata:
	if shape_material == null:
		return null

	var delta_normal = delta.normalized()
	var normal = Vector2(delta.y, -delta.x).normalized()

	var edge_materials_meta = []
	edge_materials_meta = shape_material.get_edge_materials(normal)
	var edge_material_meta = vtx_edge_materials_meta[0]
	return edge_material_meta


func _build_quads_edge(edge: EdgeData, c_scale: float, c_offset: float, c_extends: float) -> QuadArray:
	var quads = QuadArray.new([], edge)
	var points = get_vertices()
	var tess_points = get_tessellated_points()
	if (points < 3 and closed_shape) or (points < 2 and not closed_shape):
		return quads
	if edge.indicies.size() < 2:
		return quads

	var edge_material_meta = edge.material
	var edge_material = edge_material_meta.edge_material
	# Generate entire edge using EDGE Style texturing
	# All points are in the tess point context
	for idx in edge.indicies:
		var is_first_point = idx == edge.indicies[0]
		var is_last_point = idx == edge.indicies[edge.indicies.size() - 1]

		var idx_next = _get_next_point_index(idx, tess_points, closed_shape)
		var idx_prev = _get_previous_point_index(idx, tess_points, closed_shape)
		var pt_next = tess_points[idx_next]
		var pt = tess_points[idx]
		var pt_prev = tess_points[idx_prev]

		var delta = next - pt
		var delta_normal = delta.normalized()
		var normal = Vector2(delta.y, -delta.x).normalized()

		var tex = edge_material.textures[0]
		var tex_normal = edge_material.texture_normal[0]
		var tex_style = TEXTURE_STYLE.EDGE
		var tex_size = Vector2(0, 0)
		if tex != null:
			tex_size = tex.get_size()

		# This causes weird rendering if the texture isn't a square
		var vtx: Vector2 = vtx_normal * (tex_size * 0.5)

		var scale_in: float = 1.0
		var scale_out: float = 1.0
		var width = vertex_properties.get_width(pt_index)
		if width != 0.0:
			scale_in = width

		if not are_points_clockwise():
			vtx *= -1
		#if flip_edges:
		#vtx *= -1

		var clr: Color = Color.white
		var offset = Vector2.ZERO
		if tex != null and custom_offset != 0.0:
			offset = vtx
			offset *= custom_offset

		if not closed_shape:
			if tex != null:
				if tess_index == 0:
					tess_pt -= (
						(tess_pt_next - tess_pt).normalized()
						* tex.get_size()
						* custom_extends
					)
				if tess_index == tess_count - 2 and tex != null:
					tess_pt_next -= (
						(tess_pt - tess_pt_next).normalized()
						* tex.get_size()
						* custom_extends
					)

		var ratio = get_distance_as_ratio_from_tessellated_point(points, tess_points, tess_index)
		var w1 = vertex_properties.get_width(pt_index)
		var w2 = vertex_properties.get_width(pt_index_next)
		var w = lerp(w1, w2, ratio)

		var new_quad = QuadInfo.new()
		var final_offset_scale_in = (vtx * scale_in) * custom_scale
		var final_offset_scale_out = (vtx * scale_out) * custom_scale
		var pt_a = tess_pt + final_offset_scale_in + offset
		var pt_b = tess_pt - final_offset_scale_in + offset
		var pt_c = tess_pt_next - final_offset_scale_out + offset
		var pt_d = tess_pt_next + final_offset_scale_out + offset
		new_quad.pt_a = pt_a
		new_quad.pt_b = pt_b
		new_quad.pt_c = pt_c
		new_quad.pt_d = pt_d
		new_quad.color = clr
		new_quad.texture_style = TEXTURE_STYLE.EDGE
		new_quad.texture = tex
		new_quad.normal_tex = tex_normal
		new_quad.flip_texture = vertex_properties.get_flip(pt_index)
		new_quad.width_factor = w

	# Generate textures at each end of the edge. Either Corners or Tapers
	return quads


func _get_edge_data(points: Array, s_material: RMSS2D_Material_Shape) -> Array:
	var final_edges: Array = []
	var edge_building: Dictionary = {}
	for idx in range(0, points.size(), 1):
		# Skip final point on closed shape. First and Last point are the same
		if idx == points.size() - 1 and closed_shape:
			break
		var idx_next = _get_next_point_index(idx, points, closed_shape)
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
				edge_building[e] = EdgeData.new([idx], e)

		# Closeout and stop building edges that are no longer viable
		for e in edge_building.keys():
			if not edge_meta_materials.has(e):
				edges.push_back(edge_building[e])
				edge_building.erase(e)

	# Closeout all edge building
	for e in edge_building.keys():
		edges.push_back(edge_building[e])

	return edges


func _build_quads_edges(c_scale: float = 1.0, c_offset: float = 0, c_extends: float = 0.0) -> Array:
	"""
	This function will generate an of quads for representing edges and return them
	"""
	var quads: Array = []
	if shape_material == null:
		return quads

	for edge_data in _get_edge_data(get_tessellated_points, shape_material):
		quads.push_back(_build_quads_edge(edge, c_scale, c_offset, c_extends))

	return quads


func _add_mesh(mesh: ArrayMesh, texture: Texture, normal_texture: Texture, style: int):
	# Is there already a MeshInfo with these textures?
	for m in meshes:
		if m.texture == texture and m.normal_texture == normal_texture:
			# if so, add this mesh to that MeshInfo
			m.meshes.push_back(mesh)
			return

	# If not, make a new mesh for these textures
	var m = MeshInfo.new()
	m.meshes = [mesh]
	m.texture = texture
	m.normal_texture = normal_texture
	m.texture_style = style
	meshes.push_back(m)


func _weld_quads(a: QuadInfo, b: QuadInfo, custom_scale: float = 1.0):
	var needed_length: float = 0.0
	if a.texture != null and b.texture != null:
		needed_length = ((a.texture.get_size().y + (b.texture.get_size().y * b.width_factor)) / 2.0)

	if not _is_corner_style(a.texture_style) and not _is_corner_style(b.texture_style):
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
	else:
		if _is_corner_style(a.texture_style):
			b.pt_a = a.pt_c
			b.pt_b = a.pt_b

		if _is_corner_style(b.texture_style):
			a.pt_d = b.pt_a
			a.pt_c = b.pt_b


func _weld_quad_array(quads: Array, custom_scale: float = 1.0):
	for index in range(quads.size()):
		# Skip the first and last vert if the shape isn't closed
		if not closed_shape and (index == 0 or index == quads.size()):
			continue

		var previous_quad: QuadInfo = quads[(index - 1) % quads.size()]
		var this_quad: QuadInfo = quads[index % quads.size()]
		_weld_quads(previous_quad, this_quad)


# Needs tested
func _is_corner(point_prev: Vector2, point: Vector2, point_next: Vector2, corner_range: float) -> bool:
	var ab = point - point_prev
	var bc = point_next - point
	var dot_prod = ab.dot(bc)
	var determinant = (ab.x * bc.y) - (ab.y * bc.x)
	var angle = atan2(determinant, dot_prod)

	# This angle has a range of 360 degrees
	# Is between 180 and - 180
	var deg = rad2deg(angle)

	if _in_range(abs(deg), 90.0 - corner_range, 90.0 + corner_range):
		var ab_normal = ab.tangent().normalized()
		var bc_normal = bc.tangent().normalized()
		var averaged = (ab_normal + bc_normal) / 2.0
		if not are_points_clockwise():
			averaged *= -1.0

		# Inner
		if deg < 0:
			return false
		# Outer
		else:
			return true
	return false
