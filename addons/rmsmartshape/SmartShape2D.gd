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


func _dir_to_string(d: int) -> String:
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


class QuadInfo:
	extends Reference
	"""
	Used to describe the welded quads that form the edge data
	"""
	var pt_a: Vector2
	var pt_b: Vector2
	var pt_c: Vector2
	var pt_d: Vector2

	var texture: Texture
	var normal_texture: Texture
	var color: Color

	var flip_texture: bool = false
	var width_factor: float = 1.0
	var texture_style: int
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


export (bool) var editor_debug: bool = false setget set_editor_debug
export (Curve2D) var _curve: Curve2D = null setget set_curve, get_curve
export (bool) var closed_shape: bool = false setget set_close_shape
export (int, 1, 8) var tessellation_stages: int = 5 setget set_tessellation_stages
export (float, 1, 8) var tessellation_tolerence: float = 4 setget set_tolerence
export (NodePath) var collision_polygon_node_path: NodePath setget set_collision_polygon_node
export (float, 1, 512) var collision_bake_interval: float = 20.0 setget set_collision_collision_back_interval
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


func set_collision_collision_back_interval(i: float):
	collision_bake_interval = i
	_curve.bake_interval = i
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


############
# GEOMETRY #
############
func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)


func are_points_clockwise() -> bool:
	var sum = 0.0
	var point_count = _curve.get_point_count()
	for i in point_count:
		var pt = _curve.get_point_position(i)
		var pt2 = _curve.get_point_position((i + 1) % point_count)
		sum += pt.cross(pt2)

	is_clockwise = sum > 0.0
	return is_clockwise
