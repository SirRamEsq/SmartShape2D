@tool
extends Node2D
class_name SS2D_Shape_Base

# """
# Represents the base functionality for all smart shapes
# Functions consist of the following categories
#   - Setters / Getters
#   - Curve
#   - Curve Wrapper
#   - Godot
#   - Misc

# To use search to jump between categories, use the regex:
# # .+ #
# """

const TUP = preload("../lib/tuple.gd")

################
# DECLARATIONS #
################
var _dirty: bool = true
var _edges: Array = []
var _meshes: Array = []
var _is_instantiable = false
var _curve: Curve2D = Curve2D.new()
# Used for calculating straight edges
var _curve_no_control_points: Curve2D = Curve2D.new()
# Whether or not the plugin should allow editing this shape
var can_edit = true

signal points_modified
signal on_dirty_update

enum ORIENTATION { COLINEAR, CLOCKWISE, C_CLOCKWISE }

###########
# EXPORTS #
###########
# @export (bool) var editor_debug: bool = false setget _set_editor_debug
var _editor_debug : bool = false
@export var editor_debug : bool:
	get: return _editor_debug
	set(v): _set_editor_debug

# @export (float, 1, 512) var curve_bake_interval: float = 20.0 setget set_curve_bake_interval
var _curve_bake_interval : float = 20.0
@export_range(1, 512, 2) var curve_bake_interval: float:
	get: return _curve_bake_interval
	set(v): set_curve_bake_interval

# @export (SS2D_Edge.COLOR_ENCODING) var color_encoding = SS2D_Edge.COLOR_ENCODING.COLOR setget set_color_encoding
var _color_encoding = SS2D_Edge.COLOR_ENCODING.COLOR
@export var color_encoding : int:
	get: return _color_encoding
	set(v): set_color_encoding

# @export (Resource) var _points = SS2D_Point_Array.new() setget set_point_array, get_point_array
var __points : Resource = SS2D_Point_Array.new()
@export var _points : Resource:
	get: return __points
	set(v): set_point_array

# Dictionary of (Array of 2 keys) to (SS2D_Material_Edge_Metadata)
# Deprecated, exists for Support of older versions
# @export (Dictionary) var material_overrides = null setget set_material_overrides
var _material_overrides : Dictionary = null 
@export var material_overrides : Dictionary:
	get: return _material_overrides
	set(v): set_material_overrides

####################
# DETAILED EXPORTS #
####################
# @export (Resource) var shape_material = SS2D_Material_Shape.new() setget _set_material
var _shape_material : RefCounted = SS2D_Material_Shape.new() 
@export var shape_material : Resource:
	get: return _shape_material
	set(v): _set_material

#"""
#		{
#			"name": "shape_material",
#			"type": TYPE_OBJECT,
#			"usage":
#			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
#			"hint": PROPERTY_HINT_RESOURCE_TYPE,
#			"hint_string": "SS2D_Material_Shape"
#		},
#"""

# COLLISION #
#export (float)
# var collision_size: float = 32 setget set_collision_size
var _collision_size: float = 32 
var collision_size : float:
	get: return _collision_size
	set(v): set_collision_size

#export (float)
# var collision_offset: float = 0.0 setget set_collision_offset
var _collision_offset: float = 0.0 
var collision_offset : float:
	get: return _collision_offset
	set(v): set_collision_offset

#export (NodePath)
var collision_polygon_node_path: NodePath = ""

# EDGES #
#export (bool)
# var flip_edges: bool = false setget set_flip_edges
var _flip_edges: bool = false 
var flip_edges: bool:
	get: return _flip_edges
	set(v): set_flip_edges

#export (bool)
# var render_edges: bool = true setget set_render_edges
var _render_edges: bool = true 
var render_edges: bool:
	get: return _render_edges
	set(v): set_render_edges

# TESSELLATION #
#export (int, 1, 8)
# var tessellation_stages: int = 5 setget set_tessellation_stages
var _tessellation_stages: int = 5 
var tessellation_stages : int:
	get: return _tessellation_stages
	set(v): set_tessellation_stages

#export (float, 1, 8)
# var tessellation_tolerence: float = 4.0 setget set_tessellation_tolerence
var _tessellation_tolerence: float = 4.0 
var tessellation_tolerence : float:
	get: return _tessellation_tolerence
	set(v): set_tessellation_tolerence


func _get_property_list():
	return [
		{
			"name": "Edges",
			"type": TYPE_NIL,
			"hint_string": "edge_",
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "Tessellation",
			"type": TYPE_NIL,
			"hint_string": "tessellation_",
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "tessellation_stages",
			"type": TYPE_INT,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,8,1"
		},
		{
			"name": "tessellation_tolerence",
			"type": TYPE_INT, # CHANGED FROM TYPE_REAL
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0.1,8.0,1,or_greater,or_lesser"
		},
		{
			"name": "flip_edges",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "render_edges",
			"type": TYPE_BOOL,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE,
		},
		{
			"name": "Collision",
			"type": TYPE_NIL,
			"hint_string": "collision_",
			"usage": PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
		},
		{
			"name": "collision_size",
			"type": TYPE_FLOAT,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,64,1,or_greater"
		},
		{
			"name": "collision_offset",
			"type": TYPE_FLOAT,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "-64,64,1,or_greater,or_lesser"
		},
		{
			"name": "collision_polygon_node_path",
			"type": TYPE_NODE_PATH,
			"usage":
			PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_NONE
		}
	]


#####################
# SETTERS / GETTERS #
#####################
func get_point_array() -> SS2D_Point_Array:
	return _points


func set_point_array(a: SS2D_Point_Array, make_unique: bool = true):
	if _points != null:
		if _points.material_override_changed.is_connected(_handle_material_override_change):
			_points.material_override_changed.disconnect(_handle_material_override_change)
	if make_unique:
		_points = a.duplicate(true)
	else:
		_points = a
	_points.material_override_changed.connect(_handle_material_override_change)
	clear_cached_data()
	_update_curve(_points)
	set_as_dirty()
	notify_property_list_changed()


func set_flip_edges(b: bool):
	flip_edges = b
	set_as_dirty()
	notify_property_list_changed()


func set_render_edges(b: bool):
	render_edges = b
	set_as_dirty()
	notify_property_list_changed()


func set_collision_size(s: float):
	collision_size = s
	set_as_dirty()
	notify_property_list_changed()


func set_collision_offset(s: float):
	collision_offset = s
	set_as_dirty()
	notify_property_list_changed()


func _update_curve_no_control():
	_curve_no_control_points.clear_points()
	for i in range(0, _curve.get_point_count(), 1):
		_curve_no_control_points.add_point(_curve.get_point_position(i))


func set_curve(value: Curve2D):
	_curve = value
	_points.clear()
	for i in range(0, _curve.get_point_count(), 1):
		_points.add_point(_curve.get_point_position(i))
	_update_curve_no_control()
	set_as_dirty()
	emit_signal("points_modified")
	notify_property_list_changed()


func get_curve():
	return _curve.duplicate()


func _set_editor_debug(value: bool):
	editor_debug = value
	set_as_dirty()
	notify_property_list_changed()


# """
# Overriding this method to set the light mask of all render children
# """


func set_light_mask(value):
	var render_parent = _get_rendering_nodes_parent()
	for c in render_parent.get_children():
		c.light_mask = value
	render_parent.light_mask = value
	super.set_light_mask(value)


func set_render_node_owners(v: bool):
	if Engine.editor_hint:
		# Force scene tree update
		var render_parent = _get_rendering_nodes_parent()
		var owner = null
		if v:
			owner = get_tree().edited_scene_root
		render_parent.set_owner(owner)

		# Set owner recurisvely
		for c in render_parent.get_children():
			c.set_owner(owner)

		# Force update
		var dummy_name = "__DUMMY__"
		if has_node(dummy_name):
			var n = get_node(dummy_name)
			remove_child(n)
			n.queue_free()

		var dummy = Node2D.new()
		dummy.name = dummy_name
		add_child(dummy)
		dummy.set_owner(owner)


func update_render_nodes():
	set_render_node_owners(editor_debug)
	set_light_mask(light_mask)


func set_tessellation_stages(value: int):
	tessellation_stages = value
	set_as_dirty()
	notify_property_list_changed()


func set_tessellation_tolerence(value: float):
	tessellation_tolerence = value
	set_as_dirty()
	notify_property_list_changed()


func set_curve_bake_interval(f: float):
	curve_bake_interval = f
	_curve.bake_interval = f
	notify_property_list_changed()

func set_color_encoding(i: int):
	color_encoding = i
	notify_property_list_changed()
	set_as_dirty()


func _set_material(value: SS2D_Material_Shape):
	if (
		shape_material != null
		and shape_material.changed.is_connected(_handle_material_change)
	):
		shape_material.changed.disconnect(_handle_material_change)

	shape_material = value as RefCounted
	if shape_material != null:
		shape_material.changed.connect(_handle_material_change)
	set_as_dirty()
	notify_property_list_changed()


func set_material_overrides(dict):
	material_overrides = null
	if dict == null:
		return
	_points.set_material_overrides(dict)


#########
# CURVE #
#########


func _update_curve(p_array: SS2D_Point_Array):
	_curve.clear_points()
	for p_key in p_array.get_all_point_keys():
		var pos = p_array.get_point_position(p_key)
		var _in = p_array.get_point_in(p_key)
		var out = p_array.get_point_out(p_key)
		_curve.add_point(pos, _in, out)
	_update_curve_no_control()


func get_vertices() -> Array:
	var positions = []
	for p_key in _points.get_all_point_keys():
		positions.push_back(_points.get_point_position(p_key))
	return positions


func get_tessellated_points() -> PackedVector2Array:
	if _curve.get_point_count() < 2:
		return PackedVector2Array()
	# Point 0 will be the same on both the curve points and the vertecies
	# Point size - 1 will be the same on both the curve points and the vertecies
	# TODO cache this result
	var points = _curve.tessellate(tessellation_stages, tessellation_tolerence)
	points[0] = _curve.get_point_position(0)
	points[points.size() - 1] = _curve.get_point_position(_curve.get_point_count() - 1)
	return points


func invert_point_order():
	_points.invert_point_order()
	_update_curve(_points)
	set_as_dirty()


func clear_points():
	_points.clear()
	_update_curve(_points)
	set_as_dirty()


# Meant to override in subclasses
func adjust_add_point_index(index: int) -> int:
	return index


# Meant to override in subclasses
func add_points(verts: Array, starting_index: int = -1, key: int = -1) -> Array:
	var keys = []
	for i in range(0, verts.size(), 1):
		var v = verts[i]
		if starting_index != -1:
			keys.push_back(_points.add_point(v, starting_index + i, key))
		else:
			keys.push_back(_points.add_point(v, starting_index, key))
	_add_point_update()
	return keys


# Meant to override in subclasses
func add_point(position: Vector2, index: int = -1, key: int = -1) -> int:
	key = _points.add_point(position, index, key)
	_add_point_update()
	return key


func get_next_key() -> int:
	return _points.get_next_key()


func _add_point_update():
	_update_curve(_points)
	set_as_dirty()
	emit_signal("points_modified")


func _is_array_index_in_range(a: Array, i: int) -> bool:
	if a.size() > i and i >= 0:
		return true
	return false


func is_index_in_range(idx: int) -> bool:
	return _points.is_index_in_range(idx)


func set_point_position(key: int, position: Vector2):
	_points.set_point_position(key, position)
	_update_curve(_points)
	set_as_dirty()
	emit_signal("points_modified")


func remove_point(key: int):
	_points.remove_point(key)
	_update_curve(_points)
	set_as_dirty()
	emit_signal("points_modified")


func remove_point_at_index(idx: int):
	remove_point(get_point_key_at_index(idx))


#######################
# POINT ARRAY WRAPPER #
#######################


func has_point(key: int) -> bool:
	return _points.has_point(key)


func get_all_point_keys() -> Array:
	return _points.get_all_point_keys()


func get_point_key_at_index(idx: int) -> int:
	return _points.get_point_key_at_index(idx)


func get_point_at_index(idx: int) -> int:
	return _points.get_point_at_index(idx)


func get_point_index(key: int) -> int:
	return _points.get_point_index(key)


func set_point_in(key: int, v: Vector2):
	"""
	point_in controls the edge leading from the previous vertex to this one
	"""
	_points.set_point_in(key, v)
	_update_curve(_points)
	set_as_dirty()
	emit_signal("points_modified")


func set_point_out(key: int, v: Vector2):
	"""
	point_out controls the edge leading from this vertex to the next
	"""
	_points.set_point_out(key, v)
	_update_curve(_points)
	set_as_dirty()
	emit_signal("points_modified")


func get_point_in(key: int) -> Vector2:
	return _points.get_point_in(key)


func get_point_out(key: int) -> Vector2:
	return _points.get_point_out(key)


func get_closest_point(to_point: Vector2):
	if _curve != null:
		return _curve.get_closest_point(to_point)
	return null


func get_closest_point_straight_edge(to_point: Vector2):
	if _curve != null:
		return _curve_no_control_points.get_closest_point(to_point)
	return null


func get_closest_offset_straight_edge(to_point: Vector2):
	if _curve != null:
		return _curve_no_control_points.get_closest_offset(to_point)
	return null


func get_closest_offset(to_point: Vector2):
	if _curve != null:
		return _curve.get_closest_offset(to_point)
	return null


func disable_constraints():
	_points.disable_constraints()


func enable_constraints():
	_points.enable_constraints()


func get_point_count():
	return _points.get_point_count()


func get_edges() -> Array:
	return _edges


func get_point_position(key: int):
	return _points.get_point_position(key)


func get_point(key: int):
	return _points.get_point(key)


func get_point_constraints(key: int):
	return _points.get_point_constraints(key)


func get_point_constraint(key1: int, key2: int):
	return _points.get_point_constraint(key1, key2)


func set_constraint(key1: int, key2: int, c: int):
	return _points.set_constraint(key1, key2, c)


func set_point(key: int, value: SS2D_Point):
	_points.set_point(key, value)
	_update_curve(_points)
	set_as_dirty()


func set_point_width(key: int, w: float):
	var props = _points.get_point_properties(key)
	props.width = w
	_points.set_point_properties(key, props)
	set_as_dirty()


func get_point_width(key: int) -> float:
	return _points.get_point_properties(key).width


func set_point_texture_index(key: int, tex_idx: int):
	var props = _points.get_point_properties(key)
	props.texture_idx = tex_idx
	_points.set_point_properties(key, props)


func get_point_texture_index(key: int) -> int:
	return _points.get_point_properties(key).texture_idx


func set_point_texture_flip(key: int, flip: bool):
	var props = _points.get_point_properties(key)
	props.flip = flip
	_points.set_point_properties(key, props)


func get_point_texture_flip(key: int) -> bool:
	return _points.get_point_properties(key).flip


func get_point_properties(key: int):
	return _points.get_point_properties(key)


func set_point_properties(key: int, properties):
	return _points.set_point_properties(key, properties)


#########
# GODOT #
#########
func _init():
	pass


func _ready():
	if not _points.material_override_changed.is_connected(
		_handle_material_override_change
	):
		_points.material_override_changed.connect(_handle_material_override_change)
	if _curve == null:
		_curve = Curve2D.new()
	_update_curve(_points)
	if not _is_instantiable:
		push_error("'%s': SS2D_Shape_Base should not be instantiated! Use a Sub-Class!" % name)
		queue_free()


func _get_rendering_nodes_parent() -> SS2D_Shape_Render:
	var render_parent_name = "_SS2D_RENDER"
	var render_parent = null
	if not has_node(render_parent_name):
		render_parent = SS2D_Shape_Render.new()
		render_parent.name = render_parent_name
		render_parent.light_mask = light_mask
		add_child(render_parent)
		if editor_debug and Engine.editor_hint:
			render_parent.set_owner(get_tree().edited_scene_root)
	else:
		render_parent = get_node(render_parent_name)
	return render_parent


# """
# Returns true if the children have changed
# """


func _create_rendering_nodes(size: int) -> bool:
	var render_parent = _get_rendering_nodes_parent()
	var child_count = render_parent.get_child_count()
	var delta = size - child_count
	#print ("%s | %s | %s" % [child_count, size, delta])
	# Size and child_count match
	if delta == 0:
		return false

	# More children than needed
	elif delta < 0:
		var children = render_parent.get_children()
		for i in range(0, abs(delta), 1):
			var child = children[child_count - 1 - i]
			render_parent.remove_child(child)
			child.set_mesh(null)
			child.queue_free()

	# Fewer children than needed
	elif delta > 0:
		for i in range(0, delta, 1):
			var child = SS2D_Shape_Render.new()
			child.light_mask = light_mask
			render_parent.add_child(child)
			if editor_debug and Engine.editor_hint:
				child.set_owner(get_tree().edited_scene_root)
	return true


# """
# Takes an array of SS2D_Meshes and returns a flat array of SS2D_Meshes
# If a SS2D_Mesh has n meshes, will return an array contain n SS2D_Mesh
# The returned array will consist of SS2D_Meshes each with a SS2D_Mesh::meshes array of size 1
# """


func _draw_flatten_meshes_array(meshes: Array) -> Array:
	var flat_meshes = []
	for ss2d_mesh in meshes:
		for godot_mesh in ss2d_mesh.meshes:
			var new_mesh = ss2d_mesh.duplicate(false)
			new_mesh.meshes = [godot_mesh]
			flat_meshes.push_back(new_mesh)
	return flat_meshes


func _draw():
	var flat_meshes = _draw_flatten_meshes_array(_meshes)
	_create_rendering_nodes(flat_meshes.size())
	var render_parent = _get_rendering_nodes_parent()
	var render_nodes = render_parent.get_children()
	#print ("RENDER | %s" % [render_nodes])
	#print ("MESHES | %s" % [flat_meshes])
	for i in range(0, flat_meshes.size(), 1):
		var m = flat_meshes[i]
		var render_node = render_nodes[i]
		render_node.set_mesh(m)

	if editor_debug and Engine.editor_hint:
		_draw_debug(sort_by_z_index(_edges))


func _draw_debug(edges: Array):
	for e in edges:
		for q in e.quads:
			q.render_lines(self)

		var _range = range(0, e.quads.size(), 1)
		for i in _range:
			var q = e.quads[i]
			if not (i % 3 == 0):
				continue
			q.render_points(3, 0.5, self)

		for i in _range:
			var q = e.quads[i]
			if not ((i + 1) % 3 == 0):
				continue
			q.render_points(2, 0.75, self)

		for i in _range:
			var q = e.quads[i]
			if not ((i + 2) % 3 == 0):
				continue
			q.render_points(1, 1.0, self)


func _process(delta):
	_on_dirty_update()


func _exit_tree():
	if shape_material != null:
		if shape_material.changed.is_connected(_handle_material_change):
			shape_material.changed.disconnect(_handle_material_change)


############
# GEOMETRY #
############


func should_flip_edges() -> bool:
	# XOR operator
	return not (are_points_clockwise() != flip_edges)


func generate_collision_points() -> PackedVector2Array:
	var points: PackedVector2Array= PackedVector2Array()
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
	var edge = _build_edge_with_material(
		edge_data, collision_offset - 1.0, collision_size
	)
	_weld_quad_array(edge.quads, false)
	if not edge.quads.empty():
		# Top edge (typically point A unless corner quad)
		for quad in edge.quads:
			if quad.corner == SS2D_Quad.CORNER.NONE:
				points.push_back(quad.pt_a)
			elif quad.corner == SS2D_Quad.CORNER.OUTER:
				points.push_back(quad.pt_d)
			elif quad.corner == SS2D_Quad.CORNER.INNER:
				pass

		# Right Edge (point d, the first or final quad will never be a corner)
		points.push_back(edge.quads[edge.quads.size() - 1].pt_d)

		# Bottom Edge (typically point c)
		for quad_index in edge.quads.size():
			var quad = edge.quads[edge.quads.size() - 1 - quad_index]
			if quad.corner == SS2D_Quad.CORNER.NONE:
				points.push_back(quad.pt_c)
			elif quad.corner == SS2D_Quad.CORNER.OUTER:
				pass
			elif quad.corner == SS2D_Quad.CORNER.INNER:
				points.push_back(quad.pt_b)

		# Left Edge (point b)
		points.push_back(edge.quads[0].pt_b)

	return points


func bake_collision():
	if not has_node(collision_polygon_node_path):
		return
	var polygon = get_node(collision_polygon_node_path)
	var points = generate_collision_points()
	var transformed_points = PackedVector2Array()
	var poly_transform = polygon.get_global_transform()
	var shape_transform = get_global_transform()
	for p in points:
		transformed_points.push_back(poly_transform.xform_inv(shape_transform.xform(p)))
	polygon.polygon = transformed_points


func cache_edges():
	if shape_material != null and render_edges:
		_edges = _build_edges(shape_material as RefCounted, get_vertices())
	else:
		_edges = []


func cache_meshes():
	if shape_material != null:
		_meshes = _build_meshes(sort_by_z_index(_edges))


func _build_meshes(edges: Array) -> Array:
	var meshes = []

	# Produce edge Meshes
	for e in edges:
		for m in e.get_meshes(color_encoding):
			meshes.push_back(m)

	return meshes


func _convert_local_space_to_uv(point: Vector2, size: Vector2) -> Vector2:
	var pt: Vector2 = point
	var rslt: Vector2 = Vector2(pt.x / size.x, pt.y / size.y)
	return rslt


static func on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	"""
	Given three colinear points p, q, r, the function checks if point q lies on line segment 'pr'
	See: https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/
	"""
	if (
		q.x <= max(p.x, r.x)
		and q.x >= min(p.x, r.x)
		and q.y <= max(p.y, r.y)
		and q.y >= min(p.y, r.y)
	):
		return true
	return false

static func get_points_orientation(points: Array) -> int:
	var point_count = points.size()
	if point_count < 3:
		return ORIENTATION.COLINEAR

	var sum = 0.0
	for i in point_count:
		var pt = points[i]
		var pt2 = points[(i + 1) % point_count]
		sum += pt.cross(pt2)

	# Colinear
	if sum == 0:
		return ORIENTATION.COLINEAR

	# Clockwise
	if sum > 0.0:
		return ORIENTATION.CLOCKWISE
	return ORIENTATION.C_CLOCKWISE


func are_points_clockwise() -> bool:
	var points = get_tessellated_points()
	var orient = get_points_orientation(points)
	return orient == ORIENTATION.CLOCKWISE


func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)


static func build_quad_from_two_points(
	pt: Vector2,
	pt_next: Vector2,
	tex: Texture,
	tex_normal: Texture,
	width: float,
	flip_x: bool,
	flip_y: bool,
	first_point: bool,
	last_point: bool,
	custom_offset: float,
	custom_extends: float,
	fit_texture: int
) -> SS2D_Quad:
	# Create new quad
	var quad = SS2D_Quad.new()
	quad.texture = tex
	quad.texture_normal = tex_normal
	quad.color = Color(1.0, 1.0, 1.0, 1.0)
	quad.flip_texture = flip_x
	quad.fit_texture = fit_texture

	# Calculate the normal
	var delta = pt_next - pt
	var delta_normal = delta.normalized()
	var normal_direction = Vector2(delta.y, -delta.x).normalized()
	var normal_rotation = Vector2(0, -1).angle_to(normal_direction)
	var normal_length = width
	var normal_with_magnitude: Vector2 = normal_direction * (normal_length * 0.5)
	if flip_y:
		normal_with_magnitude *= -1
	var offset = normal_with_magnitude * custom_offset

	# If is first or last point, extend past the normal boundary by 'custom_extends' pixels
	if first_point:
		pt -= (delta_normal * custom_extends)
	if last_point:
		pt_next += (delta_normal * custom_extends)

	##############################################
	# QUAD POINT ILLUSTRATION #                  #
	##############################################
	#                LENGTH                      #
	#           <-------------->                 #
	#      pt_a -> O--------O <- pt_d  ▲         #
	#              |        |          |         #
	#              |   pt   |          | WIDTH   #
	#              |        |          |         #
	#      pt_b -> O--------O <- pt_c  ▼         #
	##############################################
	##############################################

	quad.pt_a = pt + normal_with_magnitude + offset
	quad.pt_b = pt - normal_with_magnitude + offset
	quad.pt_c = pt_next - normal_with_magnitude + offset
	quad.pt_d = pt_next + normal_with_magnitude + offset

	return quad


# """
# Will build a corner quad
# pt is the center of this corner quad
# width will scale the quad in line with the next point (one dimension)
# prev_width will scale the quad in line with the prev point (hte other dimension)
# custom_scale will scale the quad in both dimensions
# """
static func build_quad_corner(
	pt_next: Vector2,
	pt: Vector2,
	pt_prev: Vector2,
	pt_width: float,
	pt_prev_width: float,
	flip_edges: bool,
	corner_status: int,
	texture: Texture,
	texture_normal: Texture,
	size: Vector2,
	custom_scale: float,
	custom_offset: float
) -> SS2D_Quad:
	var new_quad = SS2D_Quad.new()

	var extents = size / 2.0
	var delta_12 = pt - pt_prev
	var delta_23 = pt_next - pt
	var normal_23 = Vector2(delta_23.y, -delta_23.x).normalized()
	var normal_12 = Vector2(delta_12.y, -delta_12.x).normalized()
	var width = (pt_prev_width + pt_width) / 2.0

	var offset_12 = normal_12 * custom_scale * pt_prev_width * extents
	var offset_23 = normal_23 * custom_scale * pt_width * extents
	var custom_offset_13 = (normal_12 + normal_23) * custom_offset * extents
	if flip_edges:
		offset_12 *= -1
		offset_23 *= -1
		custom_offset_13 *= -1

	var pt_d = pt + (offset_23) + (offset_12) + custom_offset_13
	var pt_a = pt - (offset_23) + (offset_12) + custom_offset_13
	var pt_c = pt + (offset_23) - (offset_12) + custom_offset_13
	var pt_b = pt - (offset_23) - (offset_12) + custom_offset_13
	new_quad.pt_a = pt_a
	new_quad.pt_b = pt_b
	new_quad.pt_c = pt_c
	new_quad.pt_d = pt_d

	new_quad.corner = corner_status
	new_quad.texture = texture
	new_quad.texture_normal = texture_normal

	return new_quad


func _get_width_for_tessellated_point(points: Array, t_points: Array, t_idx) -> float:
	var v_idx = get_vertex_idx_from_tessellated_point(points, t_points, t_idx)
	var v_idx_next = _get_next_point_index(v_idx, points)
	var w1 = _points.get_point_properties(_points.get_point_key_at_index(v_idx)).width
	var w2 = _points.get_point_properties(_points.get_point_key_at_index(v_idx_next)).width
	var ratio = get_ratio_from_tessellated_point_to_vertex(points, t_points, t_idx)
	return lerp(w1, w2, ratio)


# """
# Mutates two quads to be welded
# returns the midpoint of the weld
# """


static func weld_quads(a: SS2D_Quad, b: SS2D_Quad, custom_scale: float = 1.0) -> Vector2:
	var midpoint = Vector2(0, 0)
	# If both quads are not a corner
	if a.corner == SS2D_Quad.CORNER.NONE and b.corner == SS2D_Quad.CORNER.NONE:
		var needed_height: float = (a.get_height_average() + b.get_height_average()) / 2.0

		var pt1 = (a.pt_d + b.pt_a) * 0.5
		var pt2 = (a.pt_c + b.pt_b) * 0.5

		midpoint = Vector2(pt1 + pt2) / 2.0
		var half_line: Vector2 = (pt2 - midpoint).normalized() * needed_height * custom_scale / 2.0

		if half_line != Vector2.ZERO:
			pt2 = midpoint + half_line
			pt1 = midpoint - half_line

		a.pt_d = pt1
		a.pt_c = pt2
		b.pt_a = pt1
		b.pt_b = pt2

	# If either quad is a corner
	else:
		if a.corner == SS2D_Quad.CORNER.OUTER:
			b.pt_a = a.pt_c
			b.pt_b = a.pt_b
			midpoint = (b.pt_a + b.pt_b) / 2.0

		elif a.corner == SS2D_Quad.CORNER.INNER:
			b.pt_a = a.pt_d
			b.pt_b = a.pt_a
			midpoint = (b.pt_a + b.pt_b) / 2.0

		elif b.corner == SS2D_Quad.CORNER.OUTER:
			a.pt_d = b.pt_a
			a.pt_c = b.pt_b
			midpoint = (a.pt_d + a.pt_c) / 2.0

		elif b.corner == SS2D_Quad.CORNER.INNER:
			a.pt_d = b.pt_d
			a.pt_c = b.pt_c
			midpoint = (a.pt_d + a.pt_c) / 2.0

	return midpoint


func _weld_quad_array(
	quads: Array, weld_first_and_last: bool, start_idx: int = 0
):
	if quads.is_empty():
		return

	for index in range(start_idx, quads.size() - 1, 1):
		var this_quad: SS2D_Quad = quads[index]
		var next_quad: SS2D_Quad = quads[index + 1]
		var mid_point = weld_quads(this_quad, next_quad)
		# If this quad self_intersects after welding, it's likely very small and can be removed
		# Usually happens when welding a very large and very small quad together
		# Generally looks better when simply being removed
		#
		# When welding and using different widths, quads can look a little weird
		# This is because they are no longer parallelograms
		# This is a tough problem to solve
		# See http://reedbeta.com/blog/quadrilateral-interpolation-part-1/
		if this_quad.self_intersects():
			quads.remove_at(index)
			if index < quads.size():
				var new_index = max(index - 1, 0)
				_weld_quad_array(quads, weld_first_and_last, new_index)
				return

	if weld_first_and_last:
		weld_quads(quads.back(), quads[0])


func _merge_index_maps(imaps:Array, verts:Array)->Array:
	return imaps

func _build_edges(s_mat: SS2D_Material_Shape, verts:Array) -> Array:
	var edges: Array = []
	if s_mat == null:
		return edges

	var index_maps = get_meta_material_index_mapping(s_mat, verts)
	var overrides = get_meta_material_index_mapping_for_overrides(s_mat, _points)

	# Remove the override indicies from the default index_maps
	for override in overrides:
		var old_to_new_imaps = {}
		for index_map in index_maps:
			var new_imaps = index_map.remove_edges(override.indicies)
			old_to_new_imaps[index_map] = new_imaps
		for k in old_to_new_imaps:
			index_maps.erase(k)
			for new_imap in old_to_new_imaps[k]:
				index_maps.push_back(new_imap)

	# Merge index maps
	index_maps = _merge_index_maps(index_maps, verts)


	# Add the overrides to the mappings to be rendered
	for override in overrides:
		index_maps.push_back(override)

	# Might be able to introduce threading here
	# One thread per index_map?
	var threads = []
	for index_map in index_maps:
		var thread = Thread.new()
		var args = [index_map, s_mat.render_offset, 0.0]
		var priority = 2
		thread.start(_build_edge_with_material_thread_wrapper, args, priority)
		threads.push_back(thread)
	for thread in threads:
		var new_edge = thread.wait_to_finish()
		edges.push_back(new_edge)

	return edges

# """
# Will return an array of SS2D_IndexMaps
# Each index map will map a set of indicies to a meta_material
# """
static func get_meta_material_index_mapping_for_overrides(
	s_material: SS2D_Material_Shape, pa:SS2D_Point_Array
) -> Array:
	var mappings = []
	var overrides = pa.get_material_overrides()
	for key_tuple in overrides:
		var indicies = [pa.get_point_index(key_tuple[0]), pa.get_point_index(key_tuple[1])]
		indicies = sort_by_int_ascending(indicies)
		var m = pa.get_material_override(key_tuple)
		var new_mapping = SS2D_IndexMap.new(indicies, m)
		mappings.push_back(new_mapping)

	return mappings


# """
# Will return a dictionary containing array of SS2D_IndexMap
# Each element in the array is a contiguous sequence of indicies that fit inside the meta_material's normalrange
# """
static func get_meta_material_index_mapping(s_material: SS2D_Material_Shape, verts: Array) -> Array:
	return _get_meta_material_index_mapping(s_material, verts, false)

static func _get_meta_material_index_mapping(s_material: SS2D_Material_Shape, verts: Array, wrap_around: bool) -> Array:
	var final_edges: Array = []
	var edge_building: Dictionary = {}
	for idx in range(0, verts.size() - 1, 1):
		var idx_next = _get_next_point_index(idx, verts, wrap_around)
		var pt = verts[idx]
		var pt_next = verts[idx_next]
		var delta = pt_next - pt
		var delta_normal = delta.normalized()
		var normal = Vector2(delta.y, -delta.x).normalized()

		# Get all valid edge_meta_materials for this normal value
		var edge_meta_materials: Array = s_material.get_edge_meta_materials(normal)

		# Append to existing edges being built. Add new ones if needed
		for e in edge_meta_materials:
			# Is exsiting, append
			if edge_building.has(e):
				if not idx_next in edge_building[e].indicies:
					edge_building[e].indicies.push_back(idx_next)
			# Isn't existing, make a new mapping
			else:
				edge_building[e] = SS2D_IndexMap.new([idx, idx_next], e)

		# Closeout and stop building edges that are no longer viable
		for e in edge_building.keys():
			if not edge_meta_materials.has(e):
				final_edges.push_back(edge_building[e])
				edge_building.erase(e)

	# Closeout all edge building
	for e in edge_building.keys():
		final_edges.push_back(edge_building[e])

	return final_edges

########
# MISC #
########
func _handle_material_change():
	set_as_dirty()


func _handle_material_override_change(tuple):
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
	a.sort_custom(SS2D_Common_Functions.sort_z)
	return a

static func sort_by_int_ascending(a: Array) -> Array:
	a.sort_custom(SS2D_Common_Functions.sort_int_ascending)
	return a


func clear_cached_data():
	_edges = []
	_meshes = []


func has_minimum_point_count() -> bool:
	return get_point_count() >= 2


func _on_dirty_update():
	if _dirty:
		update_render_nodes()
		clear_cached_data()
		if has_minimum_point_count():
			bake_collision()
			cache_edges()
			cache_meshes()
		update()
		_dirty = false
		emit_signal("on_dirty_update")


# TODO, Migrate these 'point index' functions to a helper library and make static?


static func get_first_point_index(points: Array) -> int:
	return 0


static func get_last_point_index(points: Array) -> int:
	return points.size() - 1


static func _get_next_point_index(idx: int, points: Array, wrap_around: bool = false) -> int:
	if wrap_around:
		return _get_next_point_index_wrap_around(idx, points)
	return _get_next_point_index_no_wrap_around(idx, points)


static func _get_previous_point_index(idx: int, points: Array, wrap_around: bool = false) -> int:
	if wrap_around:
		return _get_previous_point_index_wrap_around(idx, points)
	return _get_previous_point_index_no_wrap_around(idx, points)


static func _get_next_point_index_no_wrap_around(idx: int, points: Array) -> int:
	return int(min(idx + 1, points.size() - 1))


static func _get_previous_point_index_no_wrap_around(idx: int, points: Array) -> int:
	return int(max(idx - 1, 0))


static func _get_next_point_index_wrap_around(idx: int, points: Array) -> int:
	return (idx + 1) % points.size()


static func _get_previous_point_index_wrap_around(idx: int, points: Array) -> int:
	var temp = idx - 1
	while temp < 0:
		temp += points.size()
	return temp


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


static func get_vertex_idx_from_tessellated_point(points: Array, t_points: Array, t_point_idx: int) -> int:
	# if idx is 0 or negative
	if t_point_idx < 1:
		return 0
	if t_point_idx >= t_points.size():
		push_error("get_vertex_idx_from_tessellated_point:: Out of Bounds point_idx; size is %s; idx is %s" % [t_points.size(), t_point_idx])
		return points.size() - 1

	var vertex_idx = -1
	for i in range(0, t_point_idx + 1, 1):
		var tp = t_points[i]
		var p = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
	return vertex_idx


static func get_tessellated_idx_from_point(points: Array, t_points: Array, point_idx: int) -> int:
	# if idx is 0 or negative
	if point_idx < 1:
		return 0
	if point_idx >= points.size():
		push_error("get_tessellated_idx_from_point:: Out of Bounds point_idx; size is %s; idx is %s" % [points.size(), point_idx])
		return t_points.size() - 1

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


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()


func debug_print_points():
	_points.debug_print()


# Should be overridden by children
func import_from_legacy(legacy: RMSmartShape2D):
	pass


###################
# EDGE GENERATION #
###################
# """
# Get Number of TessPoints from the start and end indicies of the index_map parameter
# TODO Test this function
# """
func _edge_data_get_tess_point_count(index_map: SS2D_IndexMap) -> int:
	var count: int = 0
	var points = get_vertices()
	var t_points = get_tessellated_points()
	for i in range(index_map.indicies.size() - 1):
		var this_idx = index_map.indicies[i]
		var next_idx = index_map.indicies[i + 1]
		if this_idx > next_idx:
			count += 1
			continue
		var this_t_idx = get_tessellated_idx_from_point(points, t_points, this_idx)
		var next_t_idx = get_tessellated_idx_from_point(points, t_points, next_idx)
		var delta = next_t_idx - this_t_idx
		count += delta
	return count


# """
# This function determines if a corner quad should be generated
# if so, OUTER or INNER?
# 	The conditions deg < 0 and flip_edges are used to determine this
# 	These conditions works correctly so long as the points are in Clockwise order
# """
static func edge_should_generate_corner(pt_prev: Vector2, pt: Vector2, pt_next: Vector2, flip_edges:bool) -> bool:
	var generate_corner = SS2D_Quad.CORNER.NONE
	var ab = pt - pt_prev
	var bc = pt_next - pt
	var dot_prod = ab.dot(bc)
	var determinant = (ab.x * bc.y) - (ab.y * bc.x)
	var angle = atan2(determinant, dot_prod)
	# This angle has a range of 360 degrees
	# Is between 180 and - 180
	var deg = rad2deg(angle)
	var dir = 0
	var corner_range = 10.0
	var corner_angle = 90.0
	if abs(deg) >= corner_angle - corner_range and abs(deg) <= corner_angle + corner_range:
		var inner = false
		if deg < 0:
			inner = true
		if flip_edges:
			inner = not inner
		if inner:
			generate_corner = SS2D_Quad.CORNER.INNER
		else:
			generate_corner = SS2D_Quad.CORNER.OUTER
	return generate_corner


func _edge_generate_corner(
	pt_prev: Vector2,
	pt: Vector2,
	pt_next: Vector2,
	width_prev: float,
	width: float,
	size: float,
	edge_material: SS2D_Material_Edge,
	texture_idx: int,
	c_scale: float,
	c_offset: float
):
	var generate_corner = edge_should_generate_corner(pt_prev, pt, pt_next, flip_edges)
	if generate_corner == SS2D_Quad.CORNER.NONE:
		return null
	var corner_texture = null
	var corner_texture_normal = null
	if edge_material != null:
		if generate_corner == SS2D_Quad.CORNER.OUTER:
			corner_texture = edge_material.get_texture_corner_outer(texture_idx)
			corner_texture_normal = edge_material.get_texture_normal_corner_outer(texture_idx)
		elif generate_corner == SS2D_Quad.CORNER.INNER:
			corner_texture = edge_material.get_texture_corner_inner(texture_idx)
			corner_texture_normal = edge_material.get_texture_normal_corner_inner(texture_idx)
	#if corner_texture == null:
		#return null
	var corner_quad = build_quad_corner(
		pt_next,
		pt,
		pt_prev,
		width,
		width_prev,
		flip_edges,
		generate_corner,
		corner_texture,
		corner_texture_normal,
		Vector2(size,size),
		c_scale,
		c_offset
	)
	return corner_quad


# """
# Get the next point that doesn't share the same position with the current point
# In other words, get the next point in the array with a unique position
# """
func _get_next_unique_point_idx(idx: int, pts: Array, wrap_around: bool):
	var next_idx = _get_next_point_index(idx, pts, wrap_around)
	if next_idx == idx:
		return idx
	var pt1 = pts[idx]
	var pt2 = pts[next_idx]
	if pt1 == pt2:
		return _get_next_unique_point_idx(next_idx, pts, wrap_around)
	return next_idx


func _get_previous_unique_point_idx(idx: int, pts: Array, wrap_around: bool):
	var previous_idx = _get_previous_point_index(idx, pts, wrap_around)
	if previous_idx == idx:
		return idx
	var pt1 = pts[idx]
	var pt2 = pts[previous_idx]
	if pt1 == pt2:
		return _get_previous_unique_point_idx(previous_idx, pts, wrap_around)
	return previous_idx

func _is_edge_contiguous(index_amp:SS2D_IndexMap, verts:Array)->bool:
	return false


# """
# Will constructe an SS2D_Edge from the passed parameters
# index_map must be a SS2D_IndexMap with a SS2D_Material_Edge_Metadata for an object
# the indicies used by index_map should match up with the get_verticies() indicies

# default_quad_width is the quad width used if a texture isn't available

# c_offset is the magnitude to offset all of the points
# the direction of the offset is the surface_normal
# """
func _build_edge_with_material(index_map: SS2D_IndexMap,  c_offset: float, default_quad_width:float) -> SS2D_Edge:
	var verts_t = get_tessellated_points()
	var verts = get_vertices()
	var edge = SS2D_Edge.new()
	var is_edge_contiguous = _is_edge_contiguous(index_map, verts)
	edge.wrap_around = is_edge_contiguous
	if not index_map.is_valid():
		return edge
	var c_scale = 1.0
	var c_extends = 0.0

	var edge_material_meta: SS2D_Material_Edge_Metadata = null
	var edge_material: SS2D_Material_Edge = null
	if index_map.object != null:
		edge_material_meta = index_map.object
		if edge_material_meta == null:
			return edge
		if not edge_material_meta.render:
			return edge
		edge_material = edge_material_meta.edge_material as RefCounted
		if edge_material == null:
			return edge
		c_offset += edge_material_meta.offset

		edge.z_index = edge_material_meta.z_index
		edge.z_as_relative = edge_material_meta.z_as_relative
		edge.material = edge_material_meta.edge_material.material

	var first_idx = index_map.indicies[0]
	var last_idx = index_map.indicies.back()
	var first_idx_t = get_tessellated_idx_from_point(verts, verts_t, first_idx)
	var last_idx_t = get_tessellated_idx_from_point(verts, verts_t, last_idx)
	edge.first_point_key = _points.get_point_key_at_index(first_idx)
	edge.last_point_key = _points.get_point_key_at_index(last_idx)

	# How many tessellated points are contained within this index map?
	var tess_point_count: int = _edge_data_get_tess_point_count(index_map)


	var i = 0
	while i < tess_point_count:
		var tess_idx = (first_idx_t + i) % verts_t.size()
		var tess_idx_next = _get_next_unique_point_idx(tess_idx, verts_t, true)
		var tess_idx_prev = _get_previous_unique_point_idx(tess_idx, verts_t, true)

		# set next_point_delta
		# next_point_delta is the number of tess_pts from
		# the current tess_pt to the next unique tess_pt
		# unique meaning it has a different position from the current tess_pt
		var next_point_delta = 0
		for j in range(verts_t.size()):
			if ((tess_idx + j) % verts_t.size()) == tess_idx_next:
				next_point_delta = j
				break

		var vert_idx = get_vertex_idx_from_tessellated_point(verts, verts_t, tess_idx)
		var vert_key = get_point_key_at_index(vert_idx)
		var next_vert_idx = _get_next_point_index(vert_idx, verts, true)
		var pt = verts_t[tess_idx]
		var pt_next = verts_t[tess_idx_next]
		var pt_prev = verts_t[tess_idx_prev]

		var texture_idx = 0
		var flip_x = get_point_texture_flip(vert_key)

		var width_scale = _get_width_for_tessellated_point(verts, verts_t, tess_idx)
		var is_first_point = (vert_idx == first_idx) and not is_edge_contiguous
		var is_last_point = (vert_idx == last_idx - 1) and not is_edge_contiguous
		var is_first_tess_point = (tess_idx == first_idx_t) and not is_edge_contiguous
		var is_last_tess_point = (tess_idx == last_idx_t - 1) and not is_edge_contiguous

		var tex = null
		var tex_normal = null
		var tex_size = Vector2(default_quad_width, default_quad_width)
		var fitmode = SS2D_Material_Edge.FITMODE.SQUISH_AND_STRETCH
		if edge_material != null:
			if edge_material.randomize_texture:
				texture_idx = randi() % edge_material.textures.size()
			else :
				texture_idx = get_point_texture_index(vert_key)
			tex = edge_material.get_texture(texture_idx)
			tex_size = tex.get_size()
			tex_normal = edge_material.get_texture_normal(texture_idx)
			fitmode = edge_material.fit_mode
			# Exit if we have an edge material defined but no texture to render
			if tex == null:
				i += next_point_delta
				continue

		var new_quad = build_quad_from_two_points(
			pt,
			pt_next,
			tex,
			tex_normal,
			width_scale * c_scale * tex_size.y,
			flip_x,
			should_flip_edges(),
			is_first_point,
			is_last_point,
			c_offset,
			c_extends,
			fitmode
		)
		var new_quads = []
		new_quads.push_back(new_quad)

		# Corner Quad
		if edge_material != null and edge_material.use_corner_texture:
			if tess_idx != first_idx_t or is_edge_contiguous:
				var prev_width = _get_width_for_tessellated_point(verts, verts_t, tess_idx_prev)
				var q = _edge_generate_corner(
					pt_prev,
					pt,
					pt_next,
					prev_width,
					width_scale,
					tex_size.y,
					edge_material,
					texture_idx,
					c_scale,
					c_offset
				)
				if q != null:
					new_quads.push_front(q)

		# Taper Quad
		# Bear in mind, a point can be both first AND last
		# Consider an edge that consists of two points (one edge)
		# This first point is used to generate the quad; it is both first and last
		if is_first_tess_point and edge_material != null and edge_material.use_taper_texture:
			var taper_texture = edge_material.get_texture_taper_left(texture_idx)
			var taper_texture_normal = edge_material.get_texture_normal_taper_left(texture_idx)
			if taper_texture != null:
				var taper_size = taper_texture.get_size()
				var fit = abs(taper_size.x) <= new_quad.get_length_average()
				if fit:
					var taper_quad = new_quad.duplicate()
					taper_quad.corner = 0
					taper_quad.texture = taper_texture
					taper_quad.texture_normal = taper_texture_normal
					var delta_normal = (taper_quad.pt_d - taper_quad.pt_a).normalized()
					var offset = delta_normal * taper_size

					taper_quad.pt_d = taper_quad.pt_a + offset
					taper_quad.pt_c = taper_quad.pt_b + offset
					new_quad.pt_a = taper_quad.pt_d
					new_quad.pt_b = taper_quad.pt_c
					new_quads.push_front(taper_quad)
				# If a new taper quad doesn't fit, re-texture the new_quad
				else:
					new_quad.texture = taper_texture
					new_quad.texture_normal = taper_texture_normal
		if is_last_tess_point and edge_material != null and edge_material.use_taper_texture:
			var taper_texture = edge_material.get_texture_taper_right(texture_idx)
			var taper_texture_normal = edge_material.get_texture_normal_taper_right(texture_idx)
			if taper_texture != null:
				var taper_size = taper_texture.get_size()
				var fit = abs(taper_size.x) <= new_quad.get_length_average()
				if fit:
					var taper_quad = new_quad.duplicate()
					taper_quad.corner = 0
					taper_quad.texture = taper_texture
					taper_quad.texture_normal = taper_texture_normal
					var delta_normal = (taper_quad.pt_d - taper_quad.pt_a).normalized()
					var offset = delta_normal * taper_size
					taper_quad.pt_a = taper_quad.pt_d - offset
					taper_quad.pt_b = taper_quad.pt_c - offset
					new_quad.pt_d = taper_quad.pt_a
					new_quad.pt_c = taper_quad.pt_b
					new_quads.push_back(taper_quad)
				# If a new taper quad doesn't fit, re-texture the new_quad
				else:
					new_quad.texture = taper_texture
					new_quad.texture_normal = taper_texture_normal

		# Final point for closed shapes fix
		# Corner quads aren't always correctly when the corner is between final and first pt
		if is_last_point and is_edge_contiguous:
			var idx_mid = verts_t.size() - 1
			var idx_next = _get_next_unique_point_idx(idx_mid, verts_t, true)
			var idx_prev = _get_previous_unique_point_idx(idx_mid, verts_t, true)
			var p_p = verts_t[idx_prev]
			var p_m = verts_t[idx_mid]
			var p_n = verts_t[idx_next]
			var w_p = _get_width_for_tessellated_point(verts, verts_t, idx_prev)
			var w_m = _get_width_for_tessellated_point(verts, verts_t, idx_mid)
			var q = _edge_generate_corner(
				p_p, p_m, p_n, w_p, w_m, tex_size.y, edge_material, texture_idx, c_scale, c_offset
			)
			if q != null:
				new_quads.push_back(q)

		# Add new quads to edge
		for q in new_quads:
			edge.quads.push_back(q)
		i += next_point_delta
	if edge_material_meta != null:
		if edge_material_meta.weld:
			_weld_quad_array(edge.quads, edge.wrap_around)

	return edge

func _build_edge_with_material_thread_wrapper(args)->SS2D_Edge:
	return _build_edge_with_material(args[0], args[1], args[2])
