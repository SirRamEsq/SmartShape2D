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

export (bool) var editor_debug: bool = false setget _set_editor_debug
export (Curve2D) var _curve: Curve2D = Curve2D.new() setget set_curve, get_curve
export (int, 1, 8) var tessellation_stages: int = 5 setget set_tessellation_stages
export (float, 1, 8) var tessellation_tolerence: float = 4.0 setget set_tessellation_tolerence
export (float, 1, 512) var collision_bake_interval: float = 20.0 setget set_collision_collision_back_interval
export (NodePath) var collision_polygon_node_path: NodePath = ""

var _dirty: bool = true
var _edges: Array = []
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


############
# GEOMETRY #
############


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


########
# MISC #
########
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


func _on_dirty_update():
	if _dirty:
		update()
		_dirty = false
		emit_signal("on_dirty_update")


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
