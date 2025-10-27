@tool
@icon("../assets/closed_shape.png")
extends Node2D
class_name SS2D_Shape

## Represents the base functionality for all smart shapes.

# Functions consist of the following categories:[br]
#  - Setters / Getters
#  - Curve
#  - Curve Wrapper
#  - Godot
#  - Misc
#
# To use search to jump between categories, use the regex: # .+ #

################
#-DECLARATIONS-#
################

const CLICK_RECT_TAG := "__ss2d_click_rect__"

var _dirty: bool = false
var _edges: Array[SS2D_Edge] = []
var _collision_polygon_node: CollisionPolygon2D
# Whether or not the plugin should allow editing this shape
var can_edit: bool = true
var _renderer: SS2D_Renderer
var _click_rect: ColorRect
var _first_update: bool = true

signal points_modified
signal on_dirty_update
signal make_unique_pressed(shape: SS2D_Shape)

enum CollisionGenerationMethod {
	## Uses the shape curve to generate a collision polygon.
	Default,
	## Uses the edge generation algorithm to create a collision representation that sometimes
	## matches the shape's visuals more accurately.
	## This method is much slower and less consistent than [enum Default]. It should not be used
	## unless absolutely needed.
	Legacy,
	## Same as [enum Default] but only generates edge collisions and keeps the inside open.
	## Only relevant for closed shapes. Behaves the same as [enum Default] for open shapes.
	Hollow,
}

enum CollisionUpdateMode {
	## Only update collisions in editor. If the corresponding CollisionPolygon2D is part of the same
	## scene, it will be saved automatically by Godot, hence no additional regeneration at runtime
	## is necessary, which reduces the loading times.
	## Does not work if the CollisionPolygon2D is part of an instanced scene, as only the scene root
	## node will be saved by Godot.
	Editor,
	## Only update collisions during runtime. Improves the shape-editing performance in editor but
	## increases loading times as collision generation is deferred to runtime.
	Runtime,
	## Update collisions both in editor and during runtime. This is the default behavior in older
	## SS2D versions.
	EditorAndRuntime,
}

###########
#-EXPORTS-#
###########

# Execute to refresh shape rendered geometry and textures.
@warning_ignore("unused_private_class_variable")
@export_placeholder("ActionProperty") var _refresh: String = "" : set = _refresh_action
#   ActionProperty will add a button to inspector to execute this action.
#   When non-empty string is passed into setter, action is considerd executed.

## Visualize generated quads and edges.
@export var editor_debug: bool = false : set = _set_editor_debug

## @deprecated
@export_range(1, 512) var curve_bake_interval: float = 20.0 :
	set(value):
		if value != _points.curve_bake_interval:
			SS2D_PluginFunctionality.show_point_array_deprecation_warning("curve_bake_interval")
			_points.curve_bake_interval = value
	get:
		return _points.curve_bake_interval

## How to treat color data. See [enum SS2D_Edge.COLOR_ENCODING].
@export var color_encoding: SS2D_Edge.COLOR_ENCODING = SS2D_Edge.COLOR_ENCODING.COLOR : set = set_color_encoding

@export_group("Geometry")

# Execute to make shape point geometry unique (not materials).
@warning_ignore("unused_private_class_variable")
@export_placeholder("ActionProperty") var _make_unique: String = "" : set = _make_unique_action
#   ActionProperty will add a button to inspector to execute this action.
#   When non-empty string is passed into setter, action is considerd executed.

## Resource that holds shape point geometry (aka point array).
@export var _points: SS2D_Point_Array : set = set_point_array

## Caches generated meshes for faster loading times.
@export_storage var _meshes: Array[SS2D_Mesh] = []

@export_group("Edges")

@export var flip_edges: bool = false : set = set_flip_edges

## Enable/disable rendering of the edges.
@export var render_edges: bool = true : set = set_render_edges

@export_group("Materials")

## Contains textures and data on how to visualize the shape.
@export var shape_material := SS2D_Material_Shape.new() : set = _set_material

## Dictionary of (Array of 2 keys) to (SS2D_Material_Edge_Metadata)
## Deprecated, exists for Support of older versions
## @deprecated
@export var material_overrides: Dictionary = {} : set = set_material_overrides

@export_group("Tesselation")

## Controls how many subdivisions a curve segment may face before it is considered
## approximate enough.
## @deprecated
@export_range(0, 8, 1)
var tessellation_stages: int = 3 :
	set(value):
		if value != _points.tessellation_stages:
			SS2D_PluginFunctionality.show_point_array_deprecation_warning("tesselation_stages")
			_points.tessellation_stages = value
	get:
		return _points.tessellation_stages

## Controls how many degrees the midpoint of a segment may deviate from the real
## curve, before the segment has to be subdivided.
## @deprecated
@export_range(0.1, 16.0, 0.1, "or_greater", "or_lesser")
var tessellation_tolerence: float = 6.0 :
	set(value):
		if value != _points.tessellation_tolerance:
			SS2D_PluginFunctionality.show_point_array_deprecation_warning("tesselation_tolerance")
			_points.tessellation_tolerance = value
	get:
		return _points.tessellation_tolerance

@export_group("Collision")

## Controls which method should be used to generate the collision shape.
@export var collision_generation_method := CollisionGenerationMethod.Default : set = set_collision_generation_method

## Controls when to update collisions.
@export var collision_update_mode := CollisionUpdateMode.Editor : set = set_collision_update_mode

## Controls size of generated polygon for CollisionPolygon2D.
@export var collision_size: float = 32 : set = set_collision_size

## Controls offset of generated polygon for CollisionPolygon2D.
@export var collision_offset: float = 0.0 : set = set_collision_offset

## NodePath to CollisionPolygon2D node for which polygon data will be generated.
@export_node_path("CollisionPolygon2D") var collision_polygon_node_path: NodePath : set = set_collision_polygon_node_path

#####################
#-SETTERS / GETTERS-#
#####################

func set_collision_polygon_node_path(value: NodePath) -> void:
	collision_polygon_node_path = value
	set_as_dirty()

	if not is_inside_tree():
		return

	if collision_polygon_node_path.is_empty():
		_collision_polygon_node = null
		return

	_collision_polygon_node = get_node(collision_polygon_node_path) as CollisionPolygon2D

	if not _collision_polygon_node:
		push_error("collision_polygon_node_path should point to proper CollisionPolygon2D node.")


func get_collision_polygon_node() -> CollisionPolygon2D:
	return _collision_polygon_node


func get_point_array() -> SS2D_Point_Array:
	return _points


func set_point_array(a: SS2D_Point_Array) -> void:
	if _points != null:
		if _points.is_connected("update_finished", self._points_modified):
			_points.disconnect("update_finished", self._points_modified)
		if _points.material_override_changed.is_connected(_handle_material_override_change):
			_points.material_override_changed.disconnect(_handle_material_override_change)
	if a == null:
		a = SS2D_Point_Array.new()
	_points = a
	_points.connect("update_finished", self._points_modified)
	_points.material_override_changed.connect(_handle_material_override_change)
	set_as_dirty()
	notify_property_list_changed()


func _refresh_action(value: String) -> void:
	if value.length() > 0:
		_points_modified()


func _make_unique_action(value: String) -> void:
	if value.length() > 0:
		make_unique_pressed.emit(self)


func set_flip_edges(b: bool) -> void:
	flip_edges = b
	set_as_dirty()
	notify_property_list_changed()


func set_render_edges(b: bool) -> void:
	render_edges = b
	set_as_dirty()
	notify_property_list_changed()


func set_collision_generation_method(value: CollisionGenerationMethod) -> void:
	collision_generation_method = value
	set_as_dirty()


func set_collision_update_mode(value: CollisionUpdateMode) -> void:
	collision_update_mode = value
	set_as_dirty()


func set_collision_size(s: float) -> void:
	collision_size = s
	set_as_dirty()


func set_collision_offset(s: float) -> void:
	collision_offset = s
	set_as_dirty()


## Deprecated. Use get_point_array().set_from_curve() instead.
## @deprecated
func set_curve(curve: Curve2D) -> void:
	SS2D_PluginFunctionality.show_deprecation_warning("set_curve()", "get_point_array().set_from_curve()")
	_points.set_from_curve(curve)


## Deprecated. Use get_point_array().get_curve() instead.
## @deprecated
func get_curve() -> Curve2D:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_curve()")
	return _points.get_curve()


func _set_editor_debug(value: bool) -> void:
	editor_debug = value
	queue_redraw()


## Deprecated. Use get_point_array().tessellation_stages instead.
## @deprecated
func set_tessellation_stages(value: int) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_tessellation_stages()")
	_points.tessellation_stages = value


## Deprecated. Use get_point_array().tessellation_tolerance instead.
## @deprecated
func set_tessellation_tolerence(value: float) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_tessellation_tolerance()")
	_points.tessellation_tolerance = value


## Deprecated. Use get_point_array().curve_bake_interval instead.
## @deprecated
func set_curve_bake_interval(f: float) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_curve_bake_interval()")
	_points.curve_bake_interval = f


func set_color_encoding(i: SS2D_Edge.COLOR_ENCODING) -> void:
	color_encoding = i
	notify_property_list_changed()
	set_as_dirty()


func _set_material(value: SS2D_Material_Shape) -> void:
	if (
		shape_material != null
		and shape_material.is_connected("changed", self._handle_material_change)
	):
		shape_material.disconnect("changed", self._handle_material_change)

	shape_material = value
	if shape_material != null:
		shape_material.connect("changed", self._handle_material_change)
	set_as_dirty()
	notify_property_list_changed()


func set_material_overrides(dict: Dictionary) -> void:
	material_overrides = {}
	if dict.is_empty():
		return
	_points.set_material_overrides(dict)


#########
#-CURVE-#
#########

## Deprecated. Use get_point_array().get_vertices() instead.
## @deprecated
func get_vertices() -> PackedVector2Array:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_vertices()")
	return _points.get_vertices()


## Deprecated. Use get_point_array().get_tessellated_points() instead.
## @deprecated
func get_tessellated_points() -> PackedVector2Array:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_tessellated_points()")
	return _points.get_tessellated_points()


## Deprecated. Use get_point_array().invert_point_order() instead.
## @deprecated
func invert_point_order() -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("invert_point_order()")
	_points.invert_point_order()


## Deprecated. Use get_point_array().clear() instead.
## @deprecated
func clear_points() -> void:
	SS2D_PluginFunctionality.show_deprecation_warning("clear_points()", "shape.get_point_array().clear()")
	_points.clear()


## Deprecated. This is now integrated in get_point_array().add_point().
## @deprecated
func adjust_add_point_index(index: int) -> int:
	SS2D_PluginFunctionality.show_deprecation_warning("adjust_add_point_index()", "")
	return _points._adjust_add_point_index(index)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func add_points(verts: PackedVector2Array, starting_index: int = -1, key: int = -1) -> PackedInt32Array:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("add_points()")
	return _points.add_points(verts, starting_index, key)


## Deprecated. Use get_point_array().add_point() instead.
## @deprecated
func add_point(pos: Vector2, index: int = -1, key: int = -1) -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("add_point()")
	return _points.add_point(pos, adjust_add_point_index(index), key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func is_shape_closed() -> bool:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("is_shape_closed()")
	return _points.is_shape_closed()


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func can_close() -> bool:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("can_close()")
	return _points.can_close()


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func close_shape(key: int = -1) -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("close_shape()")
	return _points.close_shape(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func open_shape_at_edge(edge_start_idx: int) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("open_shape_at_edge()")
	_points.open_shape_at_edge(edge_start_idx)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func undo_open_shape_at_edge(edge_start_idx: int, closing_index: int) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("undo_open_shape_at_edge()")
	_points.undo_open_shape_at_edge(edge_start_idx, closing_index)


## Deprecated. Use get_point_array().begin_update() instead.
## @deprecated
func begin_update() -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("begin_update()")
	_points.begin_update()


## Deprecated. Use get_point_array().end_update() instead.
## @deprecated
func end_update() -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("end_update()")
	_points.end_update()


## Deprecated. Use get_point_array().is_updating() instead.
## @deprecated
func is_updating() -> bool:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("is_updating()")
	return _points.is_updating()


## Deprecated. Use get_point_array().get_next_key() instead.
## @deprecated
func get_next_key() -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_next_key()")
	return _points.get_next_key()


## Deprecated. Use get_point_array().reserve_key() instead.
## @deprecated
func reserve_key() -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("reserve_key()")
	return _points.reserve_key()


func _points_modified() -> void:
	set_as_dirty()
	points_modified.emit()


func _is_array_index_in_range(a: Array, i: int) -> bool:
	return a.size() > i and i >= 0;


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func is_index_in_range(idx: int) -> bool:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("is_index_in_range()")
	return _points.is_index_in_range(idx)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func set_point_position(key: int, pos: Vector2) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_point_position()")
	_points.set_point_position(key, pos)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func remove_point(key: int) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("remove_point()")
	_points.remove_point(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func remove_point_at_index(idx: int) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("remove_point_at_index()")
	_points.remove_point_at_index(idx)


func clone(clone_point_array: bool = true) -> SS2D_Shape:
	var copy := SS2D_Shape.new()
	copy.transform = transform
	copy.modulate = modulate
	copy.shape_material = shape_material
	copy.editor_debug = editor_debug
	copy.flip_edges = flip_edges
	copy.collision_size = collision_size
	copy.collision_offset = collision_offset
	#copy.material_overrides = s.material_overrides
	copy.name = get_name().rstrip("0123456789")
	if clone_point_array:
		copy.set_point_array(_points.clone(true))
	return copy


#######################
#-POINT ARRAY WRAPPER-#
#######################

## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func has_point(key: int) -> bool:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("has_point()")
	return _points.has_point(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_all_point_keys() -> PackedInt32Array:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_all_point_keys()")
	return _points.get_all_point_keys()


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_key_at_index(idx: int) -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_key_at_index()")
	return _points.get_point_key_at_index(idx)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_at_index(idx: int) -> SS2D_Point:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_at_index()")
	return _points.get_point_at_index(idx)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_index(key: int) -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_index()")
	return _points.get_point_index(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func set_point_in(key: int, v: Vector2) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_point_in()")
	_points.set_point_in(key, v)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func set_point_out(key: int, v: Vector2) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_point_out()")
	_points.set_point_out(key, v)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_in(key: int) -> Vector2:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_in()")
	return _points.get_point_in(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_out(key: int) -> Vector2:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_out()")
	return _points.get_point_out(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_closest_point(to_point: Vector2) -> Vector2:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_closest_point()")
	return _points.get_closest_point(to_point)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_closest_point_straight_edge(to_point: Vector2) -> Vector2:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_closest_point_straight_edge()")
	return _points.get_closest_point_straight_edge(to_point)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_closest_offset_straight_edge(to_point: Vector2) -> float:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_closest_offset_straight_edge()")
	return _points.get_closest_offset_straight_edge(to_point)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_closest_offset(to_point: Vector2) -> float:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_closest_offset()")
	return _points.get_closest_offset(to_point)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func disable_constraints() -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("disable_constraints()")
	_points.disable_constraints()


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func enable_constraints() -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("enable_constraints()")
	_points.enable_constraints()


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_count() -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_count()")
	return _points.get_point_count()


func get_edges() -> Array[SS2D_Edge]:
	return _edges


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_position(key: int) -> Vector2:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_position()")
	return _points.get_point_position(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point(key: int) -> SS2D_Point:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point()")
	return _points.get_point(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_constraints(key: int) -> Dictionary:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_constraints()")
	return _points.get_point_constraints(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_constraint(key1: int, key2: int) -> SS2D_Point_Array.CONSTRAINT:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_constraint()")
	return _points.get_point_constraint(key1, key2)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func set_constraint(key1: int, key2: int, c: SS2D_Point_Array.CONSTRAINT) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_constraint()")
	_points.set_constraint(key1, key2, c)


## Deprecated.
## @deprecated
func set_point(key: int, value: SS2D_Point) -> void:
	SS2D_PluginFunctionality.show_deprecation_warning("set_point()", "")
	_points.set_point(key, value)


## Deprecated. Use respective property in get_point_array().get_point() instead.
## @deprecated
func set_point_width(key: int, w: float) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_point_width()")
	_points.get_point(key).width = w


## Deprecated. Use respective property in get_point_array().get_point() instead.
## @deprecated
func get_point_width(key: int) -> float:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_width()")
	return _points.get_point(key).width


## Deprecated. Use respective property in get_point_array().get_point() instead.
## @deprecated
func set_point_texture_index(key: int, tex_idx: int) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_point_texture_index()")
	_points.get_point(key).texture_idx = tex_idx


## Deprecated. Use respective property in get_point_array().get_point() instead.
## @deprecated
func get_point_texture_index(key: int) -> int:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_texture_index()")
	return _points.get_point(key).texture_idx


## Deprecated. Use respective property in get_point_array().get_point() instead.
## @deprecated
func set_point_texture_flip(key: int, flip: bool) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_point_texture_flip()")
	_points.get_point(key).flip = flip


## Deprecated. Use respective property in get_point_array().get_point() instead.
## @deprecated
func get_point_texture_flip(key: int) -> bool:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_texture_flip()")
	return _points.get_point(key).flip


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func get_point_properties(key: int) -> SS2D_VertexProperties:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_point_properties()")
	return _points.get_point_properties(key)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func set_point_properties(key: int, properties: SS2D_VertexProperties) -> void:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("set_point_properties()")
	_points.set_point_properties(key, properties)


#########
#-GODOT-#
#########

func _init() -> void:
	set_point_array(SS2D_Point_Array.new())


func _enter_tree() -> void:
	# Call this again because get_node() only works when the node is inside the tree
	set_collision_polygon_node_path(collision_polygon_node_path)

	# Handle material changes if scene is (re-)entered (e.g. after switching to another)
	if shape_material != null:
		if not shape_material.is_connected("changed", self._handle_material_change):
			shape_material.connect("changed", self._handle_material_change)


func _ready() -> void:
	# This must run in _ready() because the shape node itself must be ready and registered at the RenderingServer.
	_renderer = SS2D_Renderer.new(self)

	if Engine.is_editor_hint():
		_setup_click_rect()

	_on_dirty_update()

func _draw() -> void:
	if editor_debug and Engine.is_editor_hint():
		_draw_debug(SS2D_Shape.sort_by_z_index(_edges))


func _draw_debug(edges: Array[SS2D_Edge]) -> void:
	for e in edges:
		for q in e.quads:
			q.render_lines(self)

		var _range := range(0, e.quads.size(), 1)
		for i: int in _range:
			var q := e.quads[i]
			if not (i % 3 == 0):
				continue
			q.render_points(3, 0.5, self)

		for i: int in _range:
			var q := e.quads[i]
			if not ((i + 1) % 3 == 0):
				continue
			q.render_points(2, 0.75, self)

		for i: int in _range:
			var q := e.quads[i]
			if not ((i + 2) % 3 == 0):
				continue
			q.render_points(1, 1.0, self)


func _exit_tree() -> void:
	if shape_material != null:
		if shape_material.is_connected("changed", self._handle_material_change):
			shape_material.disconnect("changed", self._handle_material_change)


############
#-GEOMETRY-#
############


func should_flip_edges() -> bool:
	if _points.is_shape_closed():
		return (_points.are_points_clockwise() == flip_edges)
	else:
		return flip_edges


func bake_collision() -> void:
	if not _collision_polygon_node:
		return

	if collision_update_mode == CollisionUpdateMode.Editor and not Engine.is_editor_hint() \
			or collision_update_mode == CollisionUpdateMode.Runtime and Engine.is_editor_hint():
		return

	if _points.get_point_count() < 2:
		_collision_polygon_node.polygon = PackedVector2Array()
		return

	var generated_points: PackedVector2Array
	var input_points := _points.get_tessellated_points()
	var gen := SS2D_CollisionGen.new()
	gen.collision_size = collision_size
	gen.collision_offset = collision_offset

	match collision_generation_method:
		CollisionGenerationMethod.Legacy:
			generated_points = gen.generate_legacy(self)

		CollisionGenerationMethod.Hollow:
			if _points.is_shape_closed():
				generated_points = gen.generate_hollow(input_points)
			else:
				generated_points = gen.generate_open(input_points)

		CollisionGenerationMethod.Default:
			if _points.is_shape_closed():
				generated_points = gen.generate_filled(input_points)
			else:
				generated_points = gen.generate_open(input_points)

	# Always apply xform afterwards so node scaling also affects collision offset and size
	var xform := _collision_polygon_node.get_global_transform().affine_inverse() * get_global_transform()
	generated_points = xform * generated_points

	if generated_points.size() > 1 and generated_points[0] == generated_points[-1]:
		generated_points.resize(generated_points.size() - 1)

	_collision_polygon_node.polygon = generated_points


func _build_meshes() -> void:
	if _points == null or shape_material == null or _points.get_point_count() < 2:
		_edges.clear()
		_meshes.clear()
		return

	# Reuse SS2D_Mesh objects to reduce VCS noise due to ever-changing IDs even if there was no change.
	var mesh_idx: int = 0

	mesh_idx = _build_fill_mesh(_points.get_tessellated_points(), shape_material, _meshes, mesh_idx)

	if render_edges:
		# TODO: Do not create individual meshes for each edge, corner, taper, etc. Merge meshes with same properties.
		_edges = _build_edges(shape_material, _points.get_vertices())

		for e in _edges:
			mesh_idx = e.get_meshes(color_encoding, _meshes, mesh_idx)
	else:
		_edges.clear()

	_meshes.resize(mesh_idx)  # Trim if larger


## Generates a fill mesh if applicable and stores it in the given mesh buffer.
## Only visible meshes are generated, meshes without a texture are skipped.
## Returns the resulting buffer index, i.e. the next index after the last added mesh.
func _build_fill_mesh(points: PackedVector2Array, s_mat: SS2D_Material_Shape, mesh_buffer: Array[SS2D_Mesh], buffer_idx: int) -> int:
	if not _points.is_shape_closed() or \
			s_mat == null or \
			s_mat.fill_textures.is_empty() or \
			points.size() < 3:
		return buffer_idx

	# TODO: Support all fill textures not just the first
	var tex: Texture2D = s_mat.fill_textures[0]

	if tex == null:
		return buffer_idx

	var tex_size: Vector2 = tex.get_size()
	points = Geometry2D.offset_polygon(points, tex_size.x * s_mat.fill_mesh_offset).front()
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(points)

	if indices.is_empty():
		push_error("'%s': Couldn't Triangulate shape" % name)
		return buffer_idx

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_INDEX] = indices

	var uv_points: PackedVector2Array = _get_uv_points(points, s_mat, tex_size)
	arrays[Mesh.ARRAY_TEX_UV] = uv_points
	arrays[Mesh.ARRAY_TEX_UV2] = uv_points

	var colors := PackedColorArray()
	colors.resize(points.size())
	colors.fill(Color.WHITE)
	arrays[Mesh.ARRAY_COLOR] = colors

	var st := SurfaceTool.new()
	st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_normals()
	st.generate_tangents()

	var mesh := SS2D_Common_Functions.mesh_buffer_get_or_create(mesh_buffer, buffer_idx)
	st.commit(mesh.mesh)
	mesh.texture = tex
	mesh.material = s_mat.fill_mesh_material
	mesh.z_index = s_mat.fill_texture_z_index
	mesh.show_behind_parent = s_mat.fill_texture_show_behind_parent
	buffer_idx += 1

	return buffer_idx


func _get_uv_points(
	points: PackedVector2Array,
	s_material: SS2D_Material_Shape,
	tex_size: Vector2
) -> PackedVector2Array:
	var transformation: Transform2D = global_transform

	# If relative position ... undo translation from global_transform
	if not s_material.fill_texture_absolute_position:
		transformation = transformation.translated(-global_position)

	# Scale
	var tex_scale := 1.0 / s_material.fill_texture_scale
	transformation = transformation.scaled(Vector2(tex_scale, tex_scale))

	# If relative rotation ... undo rotation from global_transform
	if not s_material.fill_texture_absolute_rotation:
		transformation = transformation.rotated(-global_rotation)

	# Rotate the desired extra amount
	transformation = transformation.rotated(-deg_to_rad(s_material.fill_texture_angle_offset))

	# Shift the desired amount (adjusted so it's scale independent)
	transformation = transformation.translated(-s_material.fill_texture_offset / s_material.fill_texture_scale)

	# Convert local space to UV
	transformation = transformation.scaled(Vector2(1 / tex_size.x, 1 / tex_size.y))

	return transformation * points


## Given three colinear points p, q, r, the function checks if point q lies on line segment 'pr'.[br]
## See: https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/
static func on_segment(p: Vector2, q: Vector2, r: Vector2) -> bool:
	return (
		q.x <= maxf(p.x, r.x)
		and q.x >= minf(p.x, r.x)
		and q.y <= maxf(p.y, r.y)
		and q.y >= minf(p.y, r.y)
	)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
static func get_points_orientation(points: PackedVector2Array) -> SS2D_Point_Array.ORIENTATION:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("get_points_orientation()")
	return SS2D_Point_Array.get_points_orientation(points)


## Deprecated. Use respective function in get_point_array() instead.
## @deprecated
func are_points_clockwise() -> bool:
	SS2D_PluginFunctionality.show_point_array_deprecation_warning("are_points_clockwise()")
	return _points.are_points_clockwise()


static func build_quad_from_two_points(
	pt: Vector2,
	pt_next: Vector2,
	tex: Texture2D,
	width: float,
	flip_x: bool,
	flip_y: bool,
	first_point: bool,
	last_point: bool,
	custom_offset: float,
	custom_extends: float,
	fit_texture: SS2D_Material_Edge.FITMODE
) -> SS2D_Quad:
	# Create new quad
	var quad := SS2D_Quad.new()
	quad.texture = tex
	quad.color = Color(1.0, 1.0, 1.0, 1.0)
	quad.flip_texture = flip_x
	quad.fit_texture = fit_texture

	# Calculate the normal
	var delta: Vector2 = pt_next - pt
	var delta_normal := delta.normalized()
	var normal_direction := Vector2(delta.y, -delta.x).normalized()
	var normal_length: float = width
	var normal_with_magnitude: Vector2 = normal_direction * (normal_length * 0.5)
	if flip_y:
		normal_with_magnitude *= -1
	var offset: Vector2 = normal_with_magnitude * custom_offset

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


## Builds a corner quad. [br]
## - [param pt] is the center of this corner quad. [br]
## - [param width] will scale the quad in line with the next point (one dimension). [br]
## - [param prev_width] will scale the quad in line with the prev point (hte other dimension). [br]
## - [param custom_scale] will scale the quad in both dimensions. [br]
static func build_quad_corner(
	pt_next: Vector2,
	pt: Vector2,
	pt_prev: Vector2,
	pt_width: float,
	pt_prev_width: float,
	flip_edges_: bool,
	corner_status: int,
	tex: Texture2D,
	size: Vector2,
	custom_scale: float,
	custom_offset: float
) -> SS2D_Quad:
	var new_quad := SS2D_Quad.new()

	#             :BUILD PLAN:
	#   OUTER CORNER        INNER CORNER
	#
	#   0------A-----D             0-----0
	#   |  1   :  2  |             |  3  :
	#   0......B.....C             |     :
	#          :     |     0-------D-----A
	#          :  3  |     |  1    |  2  :
	#          0-----0     0.......C.....B
	#
	#  1-previous, 2-current, 3-next (points)

	var quad_size: Vector2 = size * 0.5
	var dir_12: Vector2 = (pt - pt_prev).normalized()
	var dir_23: Vector2 = (pt_next - pt).normalized()
	var offset_12: Vector2 = dir_12 * custom_scale * pt_width * quad_size
	var offset_23: Vector2 = dir_23 * custom_scale * pt_prev_width * quad_size
	var custom_offset_13: Vector2 = (dir_12 - dir_23) * custom_offset * quad_size

	if flip_edges_:
		offset_12 *= -1
		offset_23 *= -1
		custom_offset_13 *= -1

	# Should we mirror internal ABCD vertices relative to quad center.
	# - Historically, quad internal vertices are flipped for inner corner quads (see illustration).
	# - Value: 1.0 for outer, -1.0 for inner (mirrored).
	var mirror: float = -1.0 if corner_status == SS2D_Quad.CORNER.INNER else 1.0

	new_quad.pt_a = pt + (-offset_12 - offset_23 + custom_offset_13) * mirror
	new_quad.pt_b = pt + (-offset_12 + offset_23 + custom_offset_13) * mirror
	new_quad.pt_c = pt + (offset_12 + offset_23 + custom_offset_13) * mirror
	new_quad.pt_d = pt + (offset_12 - offset_23 + custom_offset_13) * mirror

	new_quad.corner = corner_status
	new_quad.texture = tex

	return new_quad


func _get_width_for_tessellated_point(
	points: PackedVector2Array,
	t_idx: int
) -> float:
	var v_idx := _points.get_tesselation_vertex_mapping().tess_to_vertex_index(t_idx)
	var v_idx_next := SS2D_PluginFunctionality.get_next_point_index(v_idx, points)
	var w1: float = _points.get_point(_points.get_point_key_at_index(v_idx)).width
	var w2: float = _points.get_point(_points.get_point_key_at_index(v_idx_next)).width
	var ratio: float = get_ratio_from_tessellated_point_to_vertex(t_idx)
	return lerp(w1, w2, ratio)


## Mutates two quads to be welded.[br]
## Returns the midpoint of the weld.[br]
static func weld_quads(a: SS2D_Quad, b: SS2D_Quad, custom_scale: float = 1.0) -> Vector2:
	var midpoint := Vector2(0, 0)
	# If both quads are not a corner
	if a.corner == SS2D_Quad.CORNER.NONE and b.corner == SS2D_Quad.CORNER.NONE:
		var needed_height: float = (a.get_height_average() + b.get_height_average()) / 2.0

		var pt1: Vector2 = (a.pt_d + b.pt_a) * 0.5
		var pt2: Vector2 = (a.pt_c + b.pt_b) * 0.5

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
	quads: Array[SS2D_Quad], weld_first_and_last: bool, start_idx: int = 0
) -> void:
	if quads.is_empty():
		return

	for index in range(start_idx, quads.size() - 1, 1):
		var this_quad: SS2D_Quad = quads[index]
		var next_quad: SS2D_Quad = quads[index + 1]
		if not this_quad.ignore_weld_next:
			SS2D_Shape.weld_quads(this_quad, next_quad)
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
				var new_index: int = maxi(index - 1, 0)
				_weld_quad_array(quads, weld_first_and_last, new_index)
				return

	if weld_first_and_last:
		if not quads[-1].ignore_weld_next:
			SS2D_Shape.weld_quads(quads[-1], quads[0])


func _merge_index_maps(imaps: Array[SS2D_IndexMap], verts: PackedVector2Array) -> Array[SS2D_IndexMap]:
	if not _points.is_shape_closed():
		return imaps
	# See if any edges have both the first (0) and last idx (size)
	# Merge them into one if so
	var final_edges: Array[SS2D_IndexMap] = imaps.duplicate()
	var edges_by_material: Dictionary = SS2D_IndexMap.index_map_array_sort_by_object(final_edges)
	# Erase any with null material
	edges_by_material.erase(null)
	for mat: Variant in edges_by_material:
		var edge_first_idx: SS2D_IndexMap = null
		var edge_last_idx: SS2D_IndexMap = null
		for e: SS2D_IndexMap in edges_by_material[mat]:
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
				var indicies := edge_last_idx.indicies + edge_first_idx.indicies
				var merged_edge := SS2D_IndexMap.new(indicies, mat)
				final_edges.push_back(merged_edge)
	return final_edges


func _build_edges(s_mat: SS2D_Material_Shape, verts: PackedVector2Array) -> Array[SS2D_Edge]:
	var edges: Array[SS2D_Edge] = []
	if s_mat == null:
		return edges

	var index_maps: Array[SS2D_IndexMap] = _get_meta_material_index_mapping(s_mat, verts)
	var overrides: Array[SS2D_IndexMap] = SS2D_Shape.get_meta_material_index_mapping_for_overrides(s_mat, _points)

	# Remove the override indicies from the default index_maps
	for override in overrides:
		var old_to_new_imaps := {}
		for index_map in index_maps:
			var new_imaps: Array[SS2D_IndexMap] = index_map.remove_edges(override.indicies)
			old_to_new_imaps[index_map] = new_imaps
		for k: SS2D_IndexMap in old_to_new_imaps:
			index_maps.erase(k)
			for new_imap: SS2D_IndexMap in old_to_new_imaps[k]:
				index_maps.push_back(new_imap)

	# Merge index maps
	index_maps = _merge_index_maps(index_maps, verts)

	# Add the overrides to the mappings to be rendered
	index_maps.append_array(overrides)

	for index_map in index_maps:
		edges.push_back(_build_edge_with_material(index_map, s_mat.render_offset, 0.0))

	return edges


## Will return an array of SS2D_IndexMaps.[br]
## Each index map will map a set of indicies to a meta_material.[br]
static func get_meta_material_index_mapping_for_overrides(
	_s_material: SS2D_Material_Shape, pa: SS2D_Point_Array
) -> Array[SS2D_IndexMap]:
	var mappings: Array[SS2D_IndexMap] = []
	for key_tuple in pa.get_material_overrides():
		var indices := SS2D_IndexTuple.sort_ascending(Vector2i(pa.get_point_index(key_tuple.x), pa.get_point_index(key_tuple.y)))
		var m: SS2D_Material_Edge_Metadata = pa.get_material_override(key_tuple)
		var new_mapping := SS2D_IndexMap.new(PackedInt32Array([ indices.x, indices.y ]), m)
		mappings.push_back(new_mapping)

	return mappings


## Will return a dictionary containing array of SS2D_IndexMap.[br]
## Each element in the array is a contiguous sequence of indicies that fit inside
## the meta_material's normalrange.[br]
func _get_meta_material_index_mapping(
	s_material: SS2D_Material_Shape, verts: PackedVector2Array
) -> Array[SS2D_IndexMap]:
	return SS2D_Shape.get_meta_material_index_mapping(s_material, verts, _points.is_shape_closed())


static func get_meta_material_index_mapping(
	s_material: SS2D_Material_Shape, verts: PackedVector2Array, wrap_around: bool
) -> Array[SS2D_IndexMap]:
	var final_edges: Array[SS2D_IndexMap] = []
	var edge_building: Dictionary = {}  # Dict[SS2D_Material_Edge_Metadata, SS2D_IndexMap]
	for idx in range(0, verts.size() - 1, 1):
		var idx_next: int = SS2D_PluginFunctionality.get_next_point_index(idx, verts, wrap_around)
		var pt: Vector2 = verts[idx]
		var pt_next: Vector2 = verts[idx_next]
		var delta: Vector2 = pt_next - pt
		var normal := Vector2(delta.y, -delta.x).normalized()

		# Get all valid edge_meta_materials for this normal value
		var edge_meta_materials := s_material.get_edge_meta_materials(normal)

		# Append to existing edges being built. Add new ones if needed
		for e in edge_meta_materials:
			var imap: SS2D_IndexMap = edge_building.get(e)

			# Is exsiting, append
			if imap:
				if not idx_next in imap.indicies:
					imap.indicies.push_back(idx_next)
			# Isn't existing, make a new mapping
			else:
				edge_building[e] = SS2D_IndexMap.new([idx, idx_next], e)

		# Closeout and stop building edges that are no longer viable
		for e: SS2D_Material_Edge_Metadata in edge_building.keys():
			if not edge_meta_materials.has(e):
				final_edges.push_back(edge_building[e])
				edge_building.erase(e)

	# Closeout all edge building
	for e: SS2D_Material_Edge_Metadata in edge_building.keys():
		final_edges.push_back(edge_building[e])

	return final_edges

########
#-MISC-#
########
func _handle_material_change() -> void:
	set_as_dirty()


func _handle_material_override_change(_tuple: Vector2i) -> void:
	set_as_dirty()


func set_as_dirty() -> void:
	if not _dirty and is_node_ready():
		call_deferred("_on_dirty_update")
	_dirty = true


static func sort_by_z_index(a: Array) -> Array:
	a.sort_custom(Callable(SS2D_Common_Functions, "sort_z"))
	return a


static func sort_by_int_ascending(a: Array) -> Array:
	a.sort_custom(Callable(SS2D_Common_Functions, "sort_int_ascending"))
	return a


func _on_dirty_update() -> void:
	if _dirty:
		force_update()
		on_dirty_update.emit()


func force_update() -> void:
	if not is_node_ready():
		return

	bake_collision()  # TODO: Get rid of CollisionUpdateMode and use _first_update as well.

	if not _first_update or not _meshes:
		_build_meshes()

	_renderer.render(_meshes)
	queue_redraw()  # Debug drawing
	_update_click_rect()

	_first_update = false
	_dirty = false


## Returns a float between 0.0 and 1.0.[br]
## 0.0 means that this tessellated point is at the same position as the vertex.[br]
## 0.5 means that this tessellated point is half-way between this vertex and the next.[br]
## 0.999 means that this tessellated point is basically at the next vertex.[br]
## 1.0 isn't going to happen; If a tess point is at the same position as a vert, it gets a ratio of 0.0.[br]
func get_ratio_from_tessellated_point_to_vertex(t_point_idx: int) -> float:
	# Index of the starting vertex
	var point_idx := _points.get_tesselation_vertex_mapping().tess_to_vertex_index(t_point_idx)
	# Index of the first tesselated point with the same vertex
	var tess_point_first_idx: int = _points.get_tesselation_vertex_mapping().vertex_to_tess_indices(point_idx)[0]
	# The total tessellated points with the same vertex
	var tess_point_count := _points.get_tesselation_vertex_mapping().vertex_to_tess_indices(point_idx).size()
	# The index of the passed t_point_idx relative to the starting vert
	var tess_index_count := t_point_idx - tess_point_first_idx
	return tess_index_count / float(tess_point_count)


func debug_print_points() -> void:
	_points.debug_print()


###################
#-EDGE GENERATION-#
###################

## Get Number of TessPoints from the start and end indicies of the index_map parameter.
func _edge_data_get_tess_point_count(index_map: SS2D_IndexMap) -> int:
	## TODO Test this function
	var count: int = 0
	for i in range(index_map.indicies.size() - 1):
		var this_idx := index_map.indicies[i]
		var next_idx := index_map.indicies[i + 1]
		if this_idx > next_idx:
			count += 1
			continue
		var this_t_idx: int = _points.get_tesselation_vertex_mapping().vertex_to_tess_indices(this_idx)[0]
		var next_t_idx: int = _points.get_tesselation_vertex_mapping().vertex_to_tess_indices(next_idx)[0]
		var delta: int = next_t_idx - this_t_idx
		count += delta
	return count


## This function determines if a corner quad should be generated.[br]
## if so, OUTER or INNER? [br]
## - The conditions deg < 0 and flip_edges are used to determine this.[br]
## - These conditions works correctly so long as the points are in Clockwise order.[br]
static func edge_should_generate_corner(pt_prev: Vector2, pt: Vector2, pt_next: Vector2, flip_edges_: bool) -> SS2D_Quad.CORNER:
	var generate_corner := SS2D_Quad.CORNER.NONE
	var ab: Vector2 = pt - pt_prev
	var bc: Vector2 = pt_next - pt
	var dot_prod: float = ab.dot(bc)
	var determinant: float = (ab.x * bc.y) - (ab.y * bc.x)
	var angle := atan2(determinant, dot_prod)
	# This angle has a range of 360 degrees
	# Is between 180 and - 180
	var deg := rad_to_deg(angle)
	var corner_range := 10.0
	var corner_angle := 90.0
	if absf(deg) >= corner_angle - corner_range and absf(deg) <= corner_angle + corner_range:
		var inner := false
		if deg < 0:
			inner = true
		if flip_edges_:
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
) -> SS2D_Quad:
	var generate_corner := SS2D_Shape.edge_should_generate_corner(pt_prev, pt, pt_next, flip_edges)
	if generate_corner == SS2D_Quad.CORNER.NONE:
		return null
	var corner_texture: Texture2D = null
	if edge_material != null:
		if generate_corner == SS2D_Quad.CORNER.OUTER:
			corner_texture = edge_material.get_texture_corner_outer(texture_idx)
		elif generate_corner == SS2D_Quad.CORNER.INNER:
			corner_texture = edge_material.get_texture_corner_inner(texture_idx)
	var corner_quad: SS2D_Quad = SS2D_Shape.build_quad_corner(
		pt_next,
		pt,
		pt_prev,
		width,
		width_prev,
		flip_edges,
		generate_corner,
		corner_texture,
		Vector2(size, size),
		c_scale,
		c_offset
	)
	return corner_quad


func _imap_contains_all_points(imap: SS2D_IndexMap, verts: PackedVector2Array) -> bool:
	return imap.indicies[0] == 0 and imap.indicies[-1] == verts.size()-1


func _is_edge_contiguous(imap: SS2D_IndexMap, verts: PackedVector2Array) -> bool:
	if not _points.is_shape_closed():
		return false
	return _imap_contains_all_points(imap, verts)


# Will construct an SS2D_Edge from the passed parameters.
# index_map must be a SS2D_IndexMap with a SS2D_Material_Edge_Metadata for an object
# the indicies used by index_map should match up with the get_verticies() indicies
#
# default_quad_width is the quad width used if a texture isn't available
#
# c_offset is the magnitude to offset all of the points
# the direction of the offset is the surface_normal
func _build_edge_with_material(
	index_map: SS2D_IndexMap,  c_offset: float, default_quad_width: float
) -> SS2D_Edge:
	var verts_t: PackedVector2Array = _points.get_tessellated_points()
	var verts: PackedVector2Array = _points.get_vertices()
	var edge := SS2D_Edge.new()
	var is_edge_contiguous: bool = _is_edge_contiguous(index_map, verts)
	edge.wrap_around = is_edge_contiguous
	if not index_map.is_valid():
		return edge
	var c_scale := 1.0
	var c_extends := 0.0

	var edge_material_meta: SS2D_Material_Edge_Metadata = null
	var edge_material: SS2D_Material_Edge = null
	if index_map.object != null:
		edge_material_meta = index_map.object
		if edge_material_meta == null:
			return edge
		if not edge_material_meta.render:
			return edge
		edge_material = edge_material_meta.edge_material
		if edge_material == null:
			return edge
		c_offset += edge_material_meta.offset

		edge.z_index = edge_material_meta.z_index
		edge.z_as_relative = edge_material_meta.z_as_relative
		edge.material = edge_material_meta.edge_material.material

	var first_idx: int = index_map.indicies[0]
	var last_idx: int = index_map.indicies[-1]
	var first_idx_t: int = _points.get_tesselation_vertex_mapping().vertex_to_tess_indices(first_idx)[0]
	var last_idx_t: int = _points.get_tesselation_vertex_mapping().vertex_to_tess_indices(last_idx)[-1]
	edge.first_point_key = _points.get_point_key_at_index(first_idx)
	edge.last_point_key = _points.get_point_key_at_index(last_idx)

	var should_flip := should_flip_edges()

	# How many tessellated points are contained within this index map?
	var tess_point_count: int = _edge_data_get_tess_point_count(index_map)

	var i := 0
	var texture_idx := 0
	var sharp_taper_next: SS2D_Quad = null
	var is_not_corner: bool = true
	var taper_sharp: bool = edge_material_meta != null and edge_material_meta.taper_sharp_corners
	while i < tess_point_count:
		var tess_idx: int = (first_idx_t + i) % verts_t.size()
		var tess_idx_next: int = SS2D_PluginFunctionality.get_next_unique_point_idx(tess_idx, verts_t, true)
		var tess_idx_prev: int = SS2D_PluginFunctionality.get_previous_unique_point_idx(tess_idx, verts_t, true)

		# set next_point_delta
		# next_point_delta is the number of tess_pts from
		# the current tess_pt to the next unique tess_pt
		# unique meaning it has a different position from the current tess_pt
		var next_point_delta := 0
		for j in range(verts_t.size()):
			if ((tess_idx + j) % verts_t.size()) == tess_idx_next:
				next_point_delta = j
				break

		var vert_idx: int = _points.get_tesselation_vertex_mapping().tess_to_vertex_index(tess_idx)
		var vert_key: int = _points.get_point_key_at_index(vert_idx)
		var vert_props := _points.get_point(vert_key)
		var pt: Vector2 = verts_t[tess_idx]
		var pt_next: Vector2 = verts_t[tess_idx_next]
		var pt_prev: Vector2 = verts_t[tess_idx_prev]
		var flip_x: bool = vert_props.flip

		var width_scale: float = _get_width_for_tessellated_point(verts, tess_idx)
		var is_first_point: bool = (vert_idx == first_idx) and not is_edge_contiguous
		var is_last_point: bool = (vert_idx == last_idx - 1) and not is_edge_contiguous
		var is_first_tess_point: bool = (tess_idx == first_idx_t) and not is_edge_contiguous
		var is_last_tess_point: bool = (tess_idx == last_idx_t - 1) and not is_edge_contiguous

		var tex: Texture2D = null
		var tex_size := Vector2(default_quad_width, default_quad_width)
		var fitmode := SS2D_Material_Edge.FITMODE.SQUISH_AND_STRETCH
		if edge_material != null:
			if edge_material.randomize_texture:
				texture_idx = randi() % edge_material.textures.size()
			else :
				texture_idx = vert_props.texture_idx
			tex = edge_material.get_texture(texture_idx)
			tex_size = tex.get_size()
			fitmode = edge_material.fit_mode
			# Exit if we have an edge material defined but no texture to render
			if tex == null:
				i += next_point_delta
				continue

		var new_quad: SS2D_Quad = SS2D_Shape.build_quad_from_two_points(
			pt,
			pt_next,
			tex,
			width_scale * c_scale * tex_size.y,
			flip_x,
			should_flip,
			is_first_point,
			is_last_point,
			c_offset,
			c_extends,
			fitmode
		)
		var new_quads: Array[SS2D_Quad] = []
		new_quads.push_back(new_quad)

		# Corner Quad
		if edge_material != null and edge_material.use_corner_texture:
			if tess_idx != first_idx_t or is_edge_contiguous:
				var prev_width: float = _get_width_for_tessellated_point(verts, tess_idx_prev)
				var q: SS2D_Quad = _edge_generate_corner(
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
					is_not_corner = false
				else:
					is_not_corner = true

		# Taper Quad
		# Bear in mind, a point can be both first AND last
		# Consider an edge that consists of two points (one edge)
		# This first point is used to generate the quad; it is both first and last
		var did_taper_left: bool = false
		var did_taper_right: bool = false
		if is_first_tess_point and edge_material != null and edge_material.use_taper_texture:
			did_taper_left = true
			var taper_quad := _taper_quad(new_quad, edge_material, texture_idx, false, false)
			if taper_quad != null:
				new_quads.push_front(taper_quad)
		if is_last_tess_point and edge_material != null and edge_material.use_taper_texture:
			did_taper_right = true
			var taper_quad := _taper_quad(new_quad, edge_material, texture_idx, true, false)
			if taper_quad != null:
				new_quads.push_back(taper_quad)

		# Taper sharp corners
		if taper_sharp:
			var ang_threshold := PI * 0.5
			if sharp_taper_next != null and is_not_corner:
				var taper := _taper_quad(sharp_taper_next, edge_material, texture_idx, true, true)
				if taper != null:
					taper.ignore_weld_next = true
					edge.quads.push_back(taper)
				else:
					sharp_taper_next.ignore_weld_next = true
			sharp_taper_next = null
			var vert := verts[vert_idx]
			var prev_vert := verts[wrapi(vert_idx - 1, 0, verts.size() - 1)]
			var next_vert := verts[wrapi(vert_idx + 1, 0, verts.size() - 1)]
			if not did_taper_left and is_not_corner:
				var ang_from := prev_vert.angle_to_point(vert)
				var ang_to := vert.angle_to_point(next_vert)
				var ang_dif := angle_difference(ang_from, ang_to)
				if absf(ang_dif) > ang_threshold:
					var taper := _taper_quad(new_quad, edge_material, texture_idx, false, true)
					if taper != null:
						new_quads.push_front(taper)
			if not did_taper_right:
				var next_next_vert := verts[wrapi(vert_idx + 2, 0, verts.size() - 1)]
				var ang_from := vert.angle_to_point(next_vert)
				var ang_to := next_vert.angle_to_point(next_next_vert)
				var ang_dif := angle_difference(ang_from, ang_to)
				if absf(ang_dif) > ang_threshold:
					sharp_taper_next = new_quad

		# Final point for closed shapes fix
		# Corner quads aren't always correctly when the corner is between final and first pt
		if is_last_point and is_edge_contiguous:
			var idx_mid: int = verts_t.size() - 1
			var idx_next: int = SS2D_PluginFunctionality.get_next_unique_point_idx(idx_mid, verts_t, true)
			var idx_prev: int = SS2D_PluginFunctionality.get_previous_unique_point_idx(idx_mid, verts_t, true)
			var p_p: Vector2 = verts_t[idx_prev]
			var p_m: Vector2 = verts_t[idx_mid]
			var p_n: Vector2 = verts_t[idx_next]
			var w_p: float = _get_width_for_tessellated_point(verts, idx_prev)
			var w_m: float = _get_width_for_tessellated_point(verts, idx_mid)
			var q: SS2D_Quad = _edge_generate_corner(
				p_p, p_m, p_n, w_p, w_m, tex_size.y, edge_material, texture_idx, c_scale, c_offset
			)
			if q != null:
				new_quads.push_back(q)

		# Add new quads to edge
		for q in new_quads:
			edge.quads.push_back(q)
		i += next_point_delta

	# leftover final taper for the last sharp corner if required
	if taper_sharp:
		if sharp_taper_next != null and edge.quads[0].corner == SS2D_Quad.CORNER.NONE:
			var taper := _taper_quad(sharp_taper_next, edge_material, texture_idx, true, true)
			if taper != null:
				taper.ignore_weld_next = true
				edge.quads.push_back(taper)
			else:
				sharp_taper_next.ignore_weld_next = true
		sharp_taper_next = null

	if edge_material_meta != null:
		if edge_material_meta.weld:
			_weld_quad_array(edge.quads, edge.wrap_around)

	return edge


# get the appropriate tapering texture based on direction and whether the current taper is a sharp
# corner taper or normal material edge taper
func get_taper_tex(edge_mat: SS2D_Material_Edge, tex_idx: int, facing_right: bool, corner_taper: bool) -> Texture2D:
	if facing_right:
		if corner_taper:
			return edge_mat.get_texture_taper_corner_right(tex_idx)
		else:
			return edge_mat.get_texture_taper_right(tex_idx)
	else:
		if corner_taper:
			return edge_mat.get_texture_taper_corner_left(tex_idx)
		else:
			return edge_mat.get_texture_taper_left(tex_idx)


func _taper_quad(
	quad: SS2D_Quad,
	edge_mat: SS2D_Material_Edge,
	tex_idx: int,
	facing_right: bool,
	corner_taper: bool
) -> SS2D_Quad:
	var taper_texture: Texture2D = get_taper_tex(edge_mat, tex_idx, facing_right, corner_taper)
	if taper_texture != null:
		var taper_size: Vector2 = taper_texture.get_size()
		var fit: bool = absf(taper_size.x) <= quad.get_length_average()
		if fit:
			var taper_quad := quad.duplicate()
			taper_quad.corner = SS2D_Quad.CORNER.NONE
			taper_quad.texture = taper_texture
			var delta_normal: Vector2 = (taper_quad.pt_d - taper_quad.pt_a).normalized()
			var offset: Vector2 = delta_normal * taper_size
			if facing_right:
				taper_quad.pt_a = taper_quad.pt_d - offset
				taper_quad.pt_b = taper_quad.pt_c - offset
				quad.pt_d = taper_quad.pt_a
				quad.pt_c = taper_quad.pt_b
			else:
				taper_quad.pt_d = taper_quad.pt_a + offset
				taper_quad.pt_c = taper_quad.pt_b + offset
				quad.pt_a = taper_quad.pt_d
				quad.pt_b = taper_quad.pt_c

			taper_quad.is_tapered = true
			return taper_quad
		# If a new taper quad doesn't fit, re-texture the new_quad
		else:
			quad.is_tapered = true
			quad.texture = taper_texture
	return null


## Create an invisible rect that catches mouse clicks in editor so we can get clickable shapes.
## It is not very accurate but good enough. MeshInstance2D also only performs a bounding box check.
func _setup_click_rect() -> void:
	# NOTE: When duplicating the shape (ctrl+d), Godot will also duplicate the click rect node
	# and update its owner to current scene root, which makes it appear in editor.
	# Hence we need to check if the node already exists and delete it.
	# Updating its owner again to hide it, does not work for some reason.
	# add_child() with INTERNAL_MODE_FRONT seems to prevent this whole issue in 4.5 but not in 4.4.

	for i in get_child_count(true):
		var node := get_child(i)

		if node.has_meta(CLICK_RECT_TAG):
			node.queue_free()
			break

	_click_rect = ColorRect.new()
	_click_rect.modulate = Color.TRANSPARENT
	_click_rect.set_meta(CLICK_RECT_TAG, true)
	add_child(_click_rect, false, INTERNAL_MODE_FRONT)
	_click_rect.owner = self  # Needed to make it clickable


## Computes a bounding box of the tesselated curve and assigns it to the click rect.
func _update_click_rect() -> void:
	if not _click_rect:
		return

	if _points.get_point_count() == 0:
		_click_rect.size = Vector2.ZERO
		return

	var points := _points.get_tessellated_points()
	var rect_min: Vector2 = points[0]
	var rect_max: Vector2 = points[0]

	for i in range(1, points.size()):
		var p := points[i]
		rect_min.x = min(rect_min.x, p.x)
		rect_min.y = min(rect_min.y, p.y)
		rect_max.x = max(rect_max.x, p.x)
		rect_max.y = max(rect_max.y, p.y)

	_click_rect.size = rect_max - rect_min
	_click_rect.position = rect_min
