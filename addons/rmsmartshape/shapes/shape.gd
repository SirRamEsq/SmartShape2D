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

const TUP = preload("../lib/tuple.gd")

################
#-DECLARATIONS-#
################

var _dirty: bool = false
var _edges: Array[SS2D_Edge] = []
var _meshes: Array[SS2D_Mesh] = []
var _curve: Curve2D
# Used for calculating straight edges
var _curve_no_control_points: Curve2D = Curve2D.new()
var _collision_polygon_node: CollisionPolygon2D
# Whether or not the plugin should allow editing this shape
var can_edit: bool = true

signal points_modified
signal on_dirty_update
signal make_unique_pressed(shape: SS2D_Shape)

enum ORIENTATION { COLINEAR, CLOCKWISE, C_CLOCKWISE }

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

@export_range (1, 512) var curve_bake_interval: float = 20.0 : set = set_curve_bake_interval

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

@export_group("Edges")

@export var flip_edges: bool = false : set = set_flip_edges

## Enable/disable rendering of the edges.
@export var render_edges: bool = true : set = set_render_edges

@export_group("Materials")

## Contains textures and data on how to visualize the shape.
@export var shape_material := SS2D_Material_Shape.new() : set = _set_material

# Dictionary of (Array of 2 keys) to (SS2D_Material_Edge_Metadata)
# Deprecated, exists for Support of older versions
@export var material_overrides: Dictionary = {} : set = set_material_overrides

@export_group("Tesselation")

## Controls how many subdivisions a curve segment may face before it is considered
## approximate enough.
@export_range(0, 8, 1)
var tessellation_stages: int = 5 : set = set_tessellation_stages

## Controls how many degrees the midpoint of a segment may deviate from the real
## curve, before the segment has to be subdivided.
@export_range(0.1, 8.0, 0.1, "or_greater", "or_lesser")
var tessellation_tolerence: float = 4.0 : set = set_tessellation_tolerence

@export_group("Collision")

## Controls size of generated polygon for CollisionPolygon2D.
@export_range(0.0, 64.0, 1.0, "or_greater")
var collision_size: float = 32 : set = set_collision_size

## Controls offset of generated polygon for CollisionPolygon2D.
@export_range(-64.0, 64.0, 1.0, "or_greater", "or_lesser")
var collision_offset: float = 0.0 : set = set_collision_offset

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
		if _points.is_connected("changed", self._points_modified):
			_points.disconnect("changed", self._points_modified)
		if _points.is_connected("material_override_changed", self._handle_material_override_change):
			_points.disconnect("material_override_changed", self._handle_material_override_change)
	if a == null:
		a = SS2D_Point_Array.new()
	_points = a
	_points.connect("changed", self._points_modified)
	_points.connect("material_override_changed", self._handle_material_override_change)
	clear_cached_data()
	_update_curve(_points)
	set_as_dirty()
	notify_property_list_changed()


func _refresh_action(value: String) -> void:
	if value.length() > 0:
		_points_modified()


func _make_unique_action(value: String) -> void:
	if value.length() > 0:
		emit_signal("make_unique_pressed", self)


func set_flip_edges(b: bool) -> void:
	flip_edges = b
	set_as_dirty()
	notify_property_list_changed()


func set_render_edges(b: bool) -> void:
	render_edges = b
	set_as_dirty()
	notify_property_list_changed()


func set_collision_size(s: float) -> void:
	collision_size = s
	set_as_dirty()
	notify_property_list_changed()


func set_collision_offset(s: float) -> void:
	collision_offset = s
	set_as_dirty()
	notify_property_list_changed()


func _update_curve_no_control() -> void:
	_curve_no_control_points.clear_points()
	for i in range(0, _curve.get_point_count(), 1):
		_curve_no_control_points.add_point(_curve.get_point_position(i))


# FIXME: Only used by unit test.
func set_curve(value: Curve2D) -> void:
	_curve = value
	_points.clear()
	for i in range(0, _curve.get_point_count(), 1):
		_points.add_point(_curve.get_point_position(i))
	_points_modified()
	notify_property_list_changed()


func get_curve() -> Curve2D:
	return _curve.duplicate()


func _set_editor_debug(value: bool) -> void:
	editor_debug = value
	set_as_dirty()
	notify_property_list_changed()


func set_render_node_light_masks(value: int) -> void:
	# TODO: This method should be called when user changes mask in the inspector.
	var render_parent: SS2D_Shape_Render = _get_rendering_nodes_parent()
	for c in render_parent.get_children():
		c.light_mask = value
	render_parent.light_mask = value


func set_render_node_owners(v: bool) -> void:
	if Engine.is_editor_hint():
		# Force scene tree update
		var render_parent: SS2D_Shape_Render = _get_rendering_nodes_parent()
		var new_owner: Node = null
		if v:
			new_owner = get_tree().edited_scene_root
		render_parent.set_owner(new_owner)

		# Set owner recurisvely
		for c in render_parent.get_children():
			c.set_owner(new_owner)

		# Force update
		var dummy_name := "__DUMMY__"
		if has_node(dummy_name):
			var n: Node = get_node(dummy_name)
			remove_child(n)
			n.queue_free()

		var dummy := Node2D.new()
		dummy.name = dummy_name
		add_child(dummy)
		dummy.set_owner(new_owner)


func update_render_nodes() -> void:
#	set_render_node_owners(editor_debug)
	set_render_node_light_masks(light_mask)


func set_tessellation_stages(value: int) -> void:
	tessellation_stages = value
	set_as_dirty()
	notify_property_list_changed()


func set_tessellation_tolerence(value: float) -> void:
	tessellation_tolerence = value
	set_as_dirty()
	notify_property_list_changed()


func set_curve_bake_interval(f: float) -> void:
	curve_bake_interval = f
	_curve.bake_interval = f
	notify_property_list_changed()


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
	if dict == null:
		return
	_points.set_material_overrides(dict)


#########
#-CURVE-#
#########


func _update_curve(p_array: SS2D_Point_Array) -> void:
	_curve.clear_points()
	for p_key in p_array.get_all_point_keys():
		var pos: Vector2 = p_array.get_point_position(p_key)
		var _in: Vector2 = p_array.get_point_in(p_key)
		var out: Vector2 = p_array.get_point_out(p_key)
		_curve.add_point(pos, _in, out)
	_update_curve_no_control()


func get_vertices() -> PackedVector2Array:
	var positions: PackedVector2Array = []
	for p_key in _points.get_all_point_keys():
		positions.push_back(_points.get_point_position(p_key))
	return positions


func get_tessellated_points() -> PackedVector2Array:
	# Force update curve if point array is dirty.
	if _points.is_updating():
		_update_curve(_points)
	if _curve.get_point_count() < 2:
		return PackedVector2Array()
	# Point 0 will be the same on both the curve points and the vertecies
	# Point size - 1 will be the same on both the curve points and the vertecies
	# TODO cache this result
	var points: PackedVector2Array = _curve.tessellate(tessellation_stages, tessellation_tolerence)
	points[0] = _curve.get_point_position(0)
	points[points.size() - 1] = _curve.get_point_position(_curve.get_point_count() - 1)
	return points


## Reverse order of points in point array.[br]
## I.e. [1, 2, 3, 4] will become [4, 3, 2, 1].[br]
func invert_point_order() -> void:
	_points.invert_point_order()


## Remove all points from point array.
func clear_points() -> void:
	_points.clear()


func adjust_add_point_index(index: int) -> int:
	# Don't allow a point to be added after the last point of the closed shape or before the first
	if _has_closing_point():
		if index < 0 or (index > get_point_count() - 1):
			index = maxi(get_point_count() - 1, 0)
		if index < 1:
			index = 1
	return index


# FIXME: Only unit tests use this.
func add_points(verts: PackedVector2Array, starting_index: int = -1, key: int = -1) -> Array[int]:
	starting_index = adjust_add_point_index(starting_index)
	var keys: Array[int] = []
	_points.begin_update()
	for i in range(0, verts.size(), 1):
		var v: Vector2 = verts[i]
		if starting_index != -1:
			keys.push_back(_points.add_point(v, starting_index + i, key))
		else:
			keys.push_back(_points.add_point(v, starting_index, key))
	_points.end_update()
	_points_modified()
	return keys


## Add a point.[br]
## Returns key of the added point.[br]
func add_point(pos: Vector2, index: int = -1, key: int = -1) -> int:
	return _points.add_point(pos, adjust_add_point_index(index), key)


## Is this shape closed, i.e. last point is constrained to the first point.
func is_shape_closed() -> bool:
	if _points.get_point_count() < 4:
		return false
	return _has_closing_point()


## Is this shape not yet closed but should be.[br]
## Returns [code]false[/code] for open shapes.[br]
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


## Open shape by removing edge that starts at specified point index.
func open_shape_at_edge(edge_start_idx: int) -> void:
	var last_idx: int = get_point_count() - 1
	if is_shape_closed():
		remove_point(get_point_key_at_index(last_idx))
		if edge_start_idx < last_idx:
			for i in range(edge_start_idx + 1):
				_points.set_point_index(_points.get_point_key_at_index(0), last_idx)
	else:
		push_warning("Can't open a shape that is not a closed shape.")


## Undo shape opening done by [method open_shape_at_edge].
func undo_open_shape_at_edge(edge_start_idx: int, closing_index: int) -> void:
	var last_idx := get_point_count() - 1
	if edge_start_idx < last_idx:
		for i in range(edge_start_idx + 1):
			_points.set_point_index(_points.get_point_key_at_index(last_idx), 0)
	if can_close():
		close_shape(closing_index)


func _has_closing_point() -> bool:
	if _points.get_point_count() < 2:
		return false
	var key1: int = _points.get_point_key_at_index(0)
	var key2: int = _points.get_point_key_at_index(_points.get_point_count() - 1)
	return get_point_constraint(key1, key2) == SS2D_Point_Array.CONSTRAINT.ALL


## Begin updating the shape.[br]
## Shape mesh and curve will only be updated after [method end_update] is called.
func begin_update() -> void:
	_points.begin_update()


## End updating the shape.[br]
## Mesh and curve will be updated, if changes were made to points array after
## [method begin_update] was called.
func end_update() -> void:
	_points.end_update()


## Is shape in the middle of being updated.
## Returns [code]true[/code] after [method begin_update] and before [method end_update].
func is_updating() -> bool:
	return _points.is_updating()


## Gets next key that would be generated.[br]
## E.g. when [method add_point] is called.[br]
func get_next_key() -> int:
	return _points.get_next_key()


## Reserve a key. It will not be generated again.
func reserve_key() -> int:
	return _points.reserve_key()


func _points_modified() -> void:
	_update_curve(_points)
	set_as_dirty()
	emit_signal("points_modified")


func _is_array_index_in_range(a, i: int) -> bool:
	return a.size() > i and i >= 0;


func is_index_in_range(idx: int) -> bool:
	return _points.is_index_in_range(idx)


func set_point_position(key: int, pos: Vector2) -> void:
	_points.set_point_position(key, pos)


func remove_point(key: int) -> void:
	_points.remove_point(key)


func remove_point_at_index(idx: int) -> void:
	remove_point(get_point_key_at_index(idx))


func clone(clone_point_array: bool = true) -> SS2D_Shape:
	var copy := SS2D_Shape.new()
	copy.transform = transform
	copy.modulate = modulate
	copy.shape_material = shape_material
	copy.editor_debug = editor_debug
	copy.flip_edges = flip_edges
	copy.editor_debug = editor_debug
	copy.collision_size = collision_size
	copy.collision_offset = collision_offset
	copy.tessellation_stages = tessellation_stages
	copy.tessellation_tolerence = tessellation_tolerence
	copy.curve_bake_interval = curve_bake_interval
	#copy.material_overrides = s.material_overrides
	copy.name = get_name().rstrip("0123456789")
	if clone_point_array:
		copy.set_point_array(_points.clone(true))
	return copy


#######################
#-POINT ARRAY WRAPPER-#
#######################


func has_point(key: int) -> bool:
	return _points.has_point(key)


func get_all_point_keys() -> Array[int]:
	return _points.get_all_point_keys()


func get_point_key_at_index(idx: int) -> int:
	return _points.get_point_key_at_index(idx)


func get_point_at_index(idx: int) -> SS2D_Point:
	return _points.get_point_at_index(idx)


func get_point_index(key: int) -> int:
	return _points.get_point_index(key)


## point_in controls the edge leading from the previous vertex to this one
func set_point_in(key: int, v: Vector2) -> void:
	_points.set_point_in(key, v)


## point_out controls the edge leading from this vertex to the next
func set_point_out(key: int, v: Vector2) -> void:
	_points.set_point_out(key, v)


func get_point_in(key: int) -> Vector2:
	return _points.get_point_in(key)


func get_point_out(key: int) -> Vector2:
	return _points.get_point_out(key)


func get_closest_point(to_point: Vector2) -> Vector2:
	assert(_curve != null)
	return _curve.get_closest_point(to_point)


func get_closest_point_straight_edge(to_point: Vector2) -> Vector2:
	assert(_curve != null)
	return _curve_no_control_points.get_closest_point(to_point)


func get_closest_offset_straight_edge(to_point: Vector2) -> float:
	assert(_curve != null)
	return _curve_no_control_points.get_closest_offset(to_point)


func get_closest_offset(to_point: Vector2) -> float:
	assert(_curve != null)
	return _curve.get_closest_offset(to_point)


func disable_constraints() -> void:
	_points.disable_constraints()


func enable_constraints() -> void:
	_points.enable_constraints()


func get_point_count() -> int:
	return _points.get_point_count()


func get_edges() -> Array[SS2D_Edge]:
	return _edges


func get_point_position(key: int) -> Vector2:
	return _points.get_point_position(key)


func get_point(key: int) -> SS2D_Point:
	return _points.get_point(key)


func get_point_constraints(key: int) -> Dictionary:
	return _points.get_point_constraints(key)


func get_point_constraint(key1: int, key2: int) -> SS2D_Point_Array.CONSTRAINT:
	return _points.get_point_constraint(key1, key2)


func set_constraint(key1: int, key2: int, c: SS2D_Point_Array.CONSTRAINT) -> void:
	_points.set_constraint(key1, key2, c)


func set_point(key: int, value: SS2D_Point) -> void:
	_points.set_point(key, value)


func set_point_width(key: int, w: float) -> void:
	var props: SS2D_VertexProperties = _points.get_point_properties(key)
	props.width = w
	_points.set_point_properties(key, props)


func get_point_width(key: int) -> float:
	return _points.get_point_properties(key).width


func set_point_texture_index(key: int, tex_idx: int) -> void:
	var props: SS2D_VertexProperties = _points.get_point_properties(key)
	props.texture_idx = tex_idx
	_points.set_point_properties(key, props)


func get_point_texture_index(key: int) -> int:
	return _points.get_point_properties(key).texture_idx


func set_point_texture_flip(key: int, flip: bool) -> void:
	var props: SS2D_VertexProperties = _points.get_point_properties(key)
	if props.flip != flip:
		props.flip = flip
		_points.set_point_properties(key, props)


func get_point_texture_flip(key: int) -> bool:
	return _points.get_point_properties(key).flip


func get_point_properties(key: int) -> SS2D_VertexProperties:
	return _points.get_point_properties(key)


func set_point_properties(key: int, properties: SS2D_VertexProperties) -> void:
	_points.set_point_properties(key, properties)


#########
#-GODOT-#
#########

func _init() -> void:
	_curve = Curve2D.new()
	set_point_array(SS2D_Point_Array.new())


func _enter_tree() -> void:
	# Call this again because get_node() only works when the node is inside the tree
	set_collision_polygon_node_path(collision_polygon_node_path)

	# Handle material changes if scene is (re-)entered (e.g. after switching to another)
	if shape_material != null:
		if not shape_material.is_connected("changed", self._handle_material_change):
			shape_material.connect("changed", self._handle_material_change)


func _get_rendering_nodes_parent() -> SS2D_Shape_Render:
	var render_parent_name := "_SS2D_RENDER"
	var render_parent: SS2D_Shape_Render = null
	if not has_node(render_parent_name):
		render_parent = SS2D_Shape_Render.new()
		render_parent.name = render_parent_name
		render_parent.light_mask = light_mask
		add_child(render_parent)
		if editor_debug and Engine.is_editor_hint():
			render_parent.set_owner(get_tree().edited_scene_root)
	else:
		render_parent = get_node(render_parent_name)
	return render_parent


# Returns true if the children have changed.
func _create_rendering_nodes(size: int) -> bool:
	var render_parent: SS2D_Shape_Render = _get_rendering_nodes_parent()
	var child_count := render_parent.get_child_count()
	var delta := size - child_count
	#print ("%s | %s | %s" % [child_count, size, delta])
	# Size and child_count match
	if delta == 0:
		return false

	# More children than needed
	elif delta < 0:
		var children := render_parent.get_children()
		for i in range(0, abs(delta), 1):
			var child: SS2D_Shape_Render = children[child_count - 1 - i]
			render_parent.remove_child(child)
			child.set_mesh(null)
			child.queue_free()

	# Fewer children than needed
	elif delta > 0:
		for i in range(0, delta, 1):
			var child := SS2D_Shape_Render.new()
			child.light_mask = light_mask
			render_parent.add_child(child)
			if editor_debug and Engine.is_editor_hint():
				child.set_owner(get_tree().edited_scene_root)
	return true


# Takes an array of SS2D_Meshes and returns a flat array of SS2D_Meshes.
# If a SS2D_Mesh has n meshes, will return an array contain n SS2D_Mesh.
# The returned array will consist of SS2D_Meshes each with a SS2D_Mesh::meshes array of size 1.
func _draw_flatten_meshes_array(meshes: Array[SS2D_Mesh]) -> Array[SS2D_Mesh]:
	var flat_meshes: Array[SS2D_Mesh] = []
	for ss2d_mesh in meshes:
		for godot_mesh in ss2d_mesh.meshes:
			var new_mesh: SS2D_Mesh = ss2d_mesh.duplicate(false)
			var arr: Array[ArrayMesh] = [godot_mesh]
			new_mesh.meshes = arr
			flat_meshes.push_back(new_mesh)
	return flat_meshes


func _draw() -> void:
	var flat_meshes: Array[SS2D_Mesh] = _draw_flatten_meshes_array(_meshes)
	_create_rendering_nodes(flat_meshes.size())
	var render_parent: SS2D_Shape_Render = _get_rendering_nodes_parent()
	var render_nodes := render_parent.get_children()
	#print ("RENDER | %s" % [render_nodes])
	#print ("MESHES | %s" % [flat_meshes])
	for i in range(0, flat_meshes.size(), 1):
		var m: SS2D_Mesh = flat_meshes[i]
		var render_node: SS2D_Shape_Render = render_nodes[i]
		render_node.set_mesh(m)

	if editor_debug and Engine.is_editor_hint():
		_draw_debug(sort_by_z_index(_edges))


func _draw_debug(edges: Array[SS2D_Edge]) -> void:
	for e in edges:
		for q in e.quads:
			q.render_lines(self)

		var _range := range(0, e.quads.size(), 1)
		for i in _range:
			var q := e.quads[i]
			if not (i % 3 == 0):
				continue
			q.render_points(3, 0.5, self)

		for i in _range:
			var q = e.quads[i]
			if not ((i + 1) % 3 == 0):
				continue
			q.render_points(2, 0.75, self)

		for i in _range:
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
	if is_shape_closed():
		return (are_points_clockwise() == flip_edges)
	else:
		return flip_edges


func generate_collision_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var num_points: int = _points.get_point_count()
	if num_points < 2:
		return points

	var csize: float = 1.0 if is_shape_closed() else collision_size
	var indicies: Array[int] = []
	indicies.assign(range(num_points))  # assign() also type casts the array
	var edge_data := SS2D_IndexMap.new(indicies, null)
	var edge: SS2D_Edge = _build_edge_with_material(edge_data, collision_offset - 1.0, csize)
	_weld_quad_array(edge.quads, false)

	if is_shape_closed():
		var first_quad: SS2D_Quad = edge.quads[0]
		var last_quad: SS2D_Quad = edge.quads.back()
		weld_quads(last_quad, first_quad)

	if not edge.quads.is_empty():
		# Top edge (typically point A unless corner quad)
		for quad in edge.quads:
			if quad.corner == SS2D_Quad.CORNER.NONE:
				points.push_back(quad.pt_a)
			elif quad.corner == SS2D_Quad.CORNER.OUTER:
				points.push_back(quad.pt_d)
			elif quad.corner == SS2D_Quad.CORNER.INNER:
				pass

		if not is_shape_closed():
			# Right Edge (point d, the first or final quad will never be a corner)
			points.push_back(edge.quads[edge.quads.size() - 1].pt_d)

			# Bottom Edge (typically point c)
			for quad_index in edge.quads.size():
				var quad: SS2D_Quad = edge.quads[edge.quads.size() - 1 - quad_index]
				if quad.corner == SS2D_Quad.CORNER.NONE:
					points.push_back(quad.pt_c)
				elif quad.corner == SS2D_Quad.CORNER.OUTER:
					pass
				elif quad.corner == SS2D_Quad.CORNER.INNER:
					points.push_back(quad.pt_b)

			# Left Edge (point b)
			points.push_back(edge.quads[0].pt_b)
	return points


func bake_collision() -> void:
	if not _collision_polygon_node:
		return
	var xform := _collision_polygon_node.get_global_transform().inverse() * get_global_transform()
	_collision_polygon_node.polygon = xform * generate_collision_points()


func cache_edges() -> void:
	if shape_material != null and render_edges:
		_edges = _build_edges(shape_material, get_vertices())
	else:
		_edges = []


func cache_meshes() -> void:
	if shape_material != null:
		_meshes = _build_meshes(sort_by_z_index(_edges))


func _build_meshes(edges: Array[SS2D_Edge]) -> Array[SS2D_Mesh]:
	var meshes: Array[SS2D_Mesh] = []
	if _points == null or _points.get_point_count() < 2:
		return meshes

	var produced_fill_mesh := false
	for e in edges:
		if not produced_fill_mesh and is_shape_closed():
			if e.z_index > shape_material.fill_texture_z_index:
				# Produce Fill Meshes
				for m in _build_fill_mesh(get_tessellated_points(), shape_material):
					meshes.push_back(m)
				produced_fill_mesh = true

		# Produce edge Meshes
		for m in e.get_meshes(color_encoding):
			meshes.push_back(m)
	if not produced_fill_mesh and is_shape_closed():
		for m in _build_fill_mesh(get_tessellated_points(), shape_material):
			meshes.push_back(m)
		produced_fill_mesh = true
	return meshes


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

	var uv_points := _get_uv_points(points, s_mat, tex_size)

	for i in range(0, fill_tris.size() - 1, 3):
		st.set_color(Color.WHITE)
		_add_uv_to_surface_tool(st, uv_points[fill_tris[i]])
		st.add_vertex(Vector3(points[fill_tris[i]].x, points[fill_tris[i]].y, 0))
		st.set_color(Color.WHITE)
		_add_uv_to_surface_tool(st, uv_points[fill_tris[i + 1]])
		st.add_vertex(Vector3(points[fill_tris[i + 1]].x, points[fill_tris[i + 1]].y, 0))
		st.set_color(Color.WHITE)
		_add_uv_to_surface_tool(st, uv_points[fill_tris[i + 2]])
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


static func get_points_orientation(points: PackedVector2Array) -> ORIENTATION:
	var point_count: int = points.size()
	if point_count < 3:
		return ORIENTATION.COLINEAR

	var sum := 0.0
	for i in point_count:
		var pt := points[i]
		var pt2 := points[(i + 1) % point_count]
		sum += pt.cross(pt2)

	# Colinear
	if sum == 0.0:
		return ORIENTATION.COLINEAR

	# Clockwise
	if sum > 0.0:
		return ORIENTATION.CLOCKWISE
	return ORIENTATION.C_CLOCKWISE


func are_points_clockwise() -> bool:
	var points: PackedVector2Array = get_tessellated_points()
	var orient: ORIENTATION = get_points_orientation(points)
	return orient == ORIENTATION.CLOCKWISE


func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2) -> void:
	surface_tool.set_uv(uv)
	surface_tool.set_uv2(uv)


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


# Will build a corner quad
# pt is the center of this corner quad
# width will scale the quad in line with the next point (one dimension)
# prev_width will scale the quad in line with the prev point (hte other dimension)
# custom_scale will scale the quad in both dimensions
static func build_quad_corner(
	pt_next: Vector2,
	pt: Vector2,
	pt_prev: Vector2,
	pt_width: float,
	pt_prev_width: float,
	flip_edges_: bool,
	corner_status: int,
	texture: Texture2D,
	size: Vector2,
	custom_scale: float,
	custom_offset: float
) -> SS2D_Quad:
	var new_quad := SS2D_Quad.new()

	var quad_size: Vector2 = size / 2.0
	var delta_12: Vector2 = pt - pt_prev
	var delta_23: Vector2 = pt_next - pt
	var normal_23 := Vector2(delta_23.y, -delta_23.x).normalized()
	var normal_12 := Vector2(delta_12.y, -delta_12.x).normalized()

	var offset_12: Vector2 = normal_12 * custom_scale * pt_prev_width * quad_size
	var offset_23: Vector2 = normal_23 * custom_scale * pt_width * quad_size
	var custom_offset_13: Vector2 = (normal_12 + normal_23) * custom_offset * quad_size
	if flip_edges_:
		offset_12 *= -1
		offset_23 *= -1
		custom_offset_13 *= -1

	var pt_d := pt + (offset_23) + (offset_12) + custom_offset_13
	var pt_a := pt - (offset_23) + (offset_12) + custom_offset_13
	var pt_c := pt + (offset_23) - (offset_12) + custom_offset_13
	var pt_b := pt - (offset_23) - (offset_12) + custom_offset_13
	new_quad.pt_a = pt_a
	new_quad.pt_b = pt_b
	new_quad.pt_c = pt_c
	new_quad.pt_d = pt_d

	new_quad.corner = corner_status
	new_quad.texture = texture

	return new_quad


func _get_width_for_tessellated_point(points: PackedVector2Array, t_points: PackedVector2Array, t_idx) -> float:
	var v_idx: int = get_vertex_idx_from_tessellated_point(points, t_points, t_idx)
	var v_idx_next: int = _get_next_point_index(v_idx, points)
	var w1: float = _points.get_point_properties(_points.get_point_key_at_index(v_idx)).width
	var w2: float = _points.get_point_properties(_points.get_point_key_at_index(v_idx_next)).width
	var ratio: float = get_ratio_from_tessellated_point_to_vertex(points, t_points, t_idx)
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
		weld_quads(quads[-1], quads[0])


func _merge_index_maps(imaps: Array[SS2D_IndexMap], verts: PackedVector2Array) -> Array[SS2D_IndexMap]:
	if not is_shape_closed():
		return imaps
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


func _build_edges(s_mat: SS2D_Material_Shape, verts: PackedVector2Array) -> Array[SS2D_Edge]:
	var edges: Array[SS2D_Edge] = []
	if s_mat == null:
		return edges

	var index_maps: Array[SS2D_IndexMap] = _get_meta_material_index_mapping(s_mat, verts)
	var overrides: Array[SS2D_IndexMap] = get_meta_material_index_mapping_for_overrides(s_mat, _points)

	# Remove the override indicies from the default index_maps
	for override in overrides:
		var old_to_new_imaps := {}
		for index_map in index_maps:
			var new_imaps: Array[SS2D_IndexMap] = index_map.remove_edges(override.indicies)
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
	var threads: Array[Thread] = []
	for index_map in index_maps:
		var thread := Thread.new()
		var args := [index_map, s_mat.render_offset, 0.0]
		var priority := 2
		thread.start(self._build_edge_with_material_thread_wrapper.bind(args), priority)
		threads.push_back(thread)
	for thread in threads:
		var new_edge: SS2D_Edge = thread.wait_to_finish()
		edges.push_back(new_edge)

	return edges


## Will return an array of SS2D_IndexMaps.[br]
## Each index map will map a set of indicies to a meta_material.[br]
static func get_meta_material_index_mapping_for_overrides(
	_s_material: SS2D_Material_Shape, pa: SS2D_Point_Array
) -> Array[SS2D_IndexMap]:
	var mappings: Array[SS2D_IndexMap] = []
	var overrides: Dictionary = pa.get_material_overrides()
	for key_tuple in overrides:
		var indicies: Array[int] = [pa.get_point_index(key_tuple[0]), pa.get_point_index(key_tuple[1])]
		indicies = sort_by_int_ascending(indicies)
		var m: SS2D_Material_Edge_Metadata = pa.get_material_override(key_tuple)
		var new_mapping := SS2D_IndexMap.new(indicies, m)
		mappings.push_back(new_mapping)

	return mappings


## Will return a dictionary containing array of SS2D_IndexMap.[br]
## Each element in the array is a contiguous sequence of indicies that fit inside
## the meta_material's normalrange.[br]
func _get_meta_material_index_mapping(
	s_material: SS2D_Material_Shape, verts: PackedVector2Array
) -> Array[SS2D_IndexMap]:
	return get_meta_material_index_mapping(s_material, verts, is_shape_closed())


static func get_meta_material_index_mapping(
	s_material: SS2D_Material_Shape, verts: PackedVector2Array, wrap_around: bool
) -> Array[SS2D_IndexMap]:
	var final_edges: Array[SS2D_IndexMap] = []
	var edge_building: Dictionary = {}
	for idx in range(0, verts.size() - 1, 1):
		var idx_next: int = _get_next_point_index(idx, verts, wrap_around)
		var pt: Vector2 = verts[idx]
		var pt_next: Vector2 = verts[idx_next]
		var delta: Vector2 = pt_next - pt
		var normal := Vector2(delta.y, -delta.x).normalized()

		# Get all valid edge_meta_materials for this normal value
		var edge_meta_materials := s_material.get_edge_meta_materials(normal)

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
#-MISC-#
########
func _handle_material_change() -> void:
	set_as_dirty()


func _handle_material_override_change(_tuple) -> void:
	set_as_dirty()


func set_as_dirty() -> void:
	if not _dirty:
		call_deferred("_on_dirty_update")
	_dirty = true


static func sort_by_z_index(a: Array) -> Array:
	a.sort_custom(Callable(SS2D_Common_Functions, "sort_z"))
	return a


static func sort_by_int_ascending(a: Array) -> Array:
	a.sort_custom(Callable(SS2D_Common_Functions, "sort_int_ascending"))
	return a


func clear_cached_data() -> void:
	_edges = []
	_meshes = []


func _on_dirty_update() -> void:
	if _dirty:
		update_render_nodes()
		clear_cached_data()
		bake_collision()
		if get_point_count() >= 2:
			cache_edges()
			cache_meshes()
		queue_redraw()
		_dirty = false


# TODO, Migrate these 'point index' functions to a helper library and make static?

# FIXME: unused function
#static func get_first_point_index(_points_: Variant) -> int:
#	return 0


# FIXME: unused function
#static func get_last_point_index(points: Variant) -> int:
#	return points.size() - 1


static func _get_next_point_index(
		idx: int, points: PackedVector2Array, wrap_around: bool = false
) -> int:
	if wrap_around:
		return _get_next_point_index_wrap_around(idx, points)
	return _get_next_point_index_no_wrap_around(idx, points)


static func _get_previous_point_index(
		idx: int, points: PackedVector2Array, wrap_around: bool = false
) -> int:
	if wrap_around:
		return _get_previous_point_index_wrap_around(idx, points)
	return _get_previous_point_index_no_wrap_around(idx, points)


static func _get_next_point_index_no_wrap_around(idx: int, points: PackedVector2Array) -> int:
	return mini(idx + 1, points.size() - 1)


static func _get_previous_point_index_no_wrap_around(idx: int, _points_: PackedVector2Array) -> int:
	return maxi(idx - 1, 0)


static func _get_next_point_index_wrap_around(idx: int, points: PackedVector2Array) -> int:
	return (idx + 1) % points.size()


static func _get_previous_point_index_wrap_around(idx: int, points: PackedVector2Array) -> int:
	var temp := idx - 1
	while temp < 0:
		temp += points.size()
	return temp


## Returns a float between 0.0 and 1.0.[br]
## 0.0 means that this tessellated point is at the same position as the vertex.[br]
## 0.5 means that this tessellated point is half-way between this vertex and the next.[br]
## 0.999 means that this tessellated point is basically at the next vertex.[br]
## 1.0 isn't going to happen; If a tess point is at the same position as a vert, it gets a ratio of 0.0.[br]
func get_ratio_from_tessellated_point_to_vertex(
		points: PackedVector2Array, t_points: PackedVector2Array, t_point_idx: int
) -> float:
	if t_point_idx == 0:
		return 0.0

	var vertex_idx := 0
	# The total tessellated points betwen two verts
	var tess_point_count := 0
	# The index of the passed t_point_idx relative to the starting vert
	var tess_index_count := 0
	for i in range(0, t_points.size(), 1):
		var tp: Vector2 = t_points[i]
		var p: Vector2 = points[vertex_idx]
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

	var result: float = fmod(float(tess_index_count) / float(tess_point_count), 1.0)
	return result


static func get_vertex_idx_from_tessellated_point(
		points: PackedVector2Array, t_points: PackedVector2Array, t_point_idx: int
) -> int:
	# if idx is 0 or negative
	if t_point_idx < 1:
		return 0
	if t_point_idx >= t_points.size():
		push_error("get_vertex_idx_from_tessellated_point:: Out of Bounds point_idx; size is %s; idx is %s" % [t_points.size(), t_point_idx])
		return points.size() - 1

	var vertex_idx := -1
	for i in range(0, t_point_idx + 1, 1):
		var tp: Vector2 = t_points[i]
		var p: Vector2 = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
	return vertex_idx


static func get_tessellated_idx_from_point(
		points: PackedVector2Array, t_points: PackedVector2Array, point_idx: int
) -> int:
	# if idx is 0 or negative
	if point_idx < 1:
		return 0
	if point_idx >= points.size():
		push_error("get_tessellated_idx_from_point:: Out of Bounds point_idx; size is %s; idx is %s" % [points.size(), point_idx])
		return t_points.size() - 1

	var vertex_idx := -1
	var tess_idx := 0
	for i in range(0, t_points.size(), 1):
		tess_idx = i
		var tp: Vector2 = t_points[i]
		var p: Vector2 = points[vertex_idx + 1]
		if tp == p:
			vertex_idx += 1
		if vertex_idx == point_idx:
			break
	return tess_idx


func debug_print_points():
	_points.debug_print()


###################
#-EDGE GENERATION-#
###################

## Get Number of TessPoints from the start and end indicies of the index_map parameter.
func _edge_data_get_tess_point_count(index_map: SS2D_IndexMap) -> int:
	## TODO Test this function
	var count: int = 0
	var points: PackedVector2Array = get_vertices()
	var t_points: PackedVector2Array = get_tessellated_points()
	for i in range(index_map.indicies.size() - 1):
		var this_idx := index_map.indicies[i]
		var next_idx := index_map.indicies[i + 1]
		if this_idx > next_idx:
			count += 1
			continue
		var this_t_idx: int = get_tessellated_idx_from_point(points, t_points, this_idx)
		var next_t_idx: int = get_tessellated_idx_from_point(points, t_points, next_idx)
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
	var generate_corner := edge_should_generate_corner(pt_prev, pt, pt_next, flip_edges)
	if generate_corner == SS2D_Quad.CORNER.NONE:
		return null
	var corner_texture: Texture2D = null
	if edge_material != null:
		if generate_corner == SS2D_Quad.CORNER.OUTER:
			corner_texture = edge_material.get_texture_corner_outer(texture_idx)
		elif generate_corner == SS2D_Quad.CORNER.INNER:
			corner_texture = edge_material.get_texture_corner_inner(texture_idx)
	var corner_quad: SS2D_Quad = build_quad_corner(
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


## Get the next point that doesn't share the same position with the current point.[br]
## In other words, get the next point in the array with a unique position.[br]
func _get_next_unique_point_idx(idx: int, pts: PackedVector2Array, wrap_around: bool) -> int:
	var next_idx: int = _get_next_point_index(idx, pts, wrap_around)
	if next_idx == idx:
		return idx
	var pt1: Vector2 = pts[idx]
	var pt2: Vector2 = pts[next_idx]
	if pt1 == pt2:
		return _get_next_unique_point_idx(next_idx, pts, wrap_around)
	return next_idx


func _get_previous_unique_point_idx(idx: int, pts: PackedVector2Array, wrap_around: bool) -> int:
	var previous_idx: int = _get_previous_point_index(idx, pts, wrap_around)
	if previous_idx == idx:
		return idx
	var pt1: Vector2 = pts[idx]
	var pt2: Vector2 = pts[previous_idx]
	if pt1 == pt2:
		return _get_previous_unique_point_idx(previous_idx, pts, wrap_around)
	return previous_idx


func _imap_contains_all_points(imap: SS2D_IndexMap, verts: PackedVector2Array) -> bool:
	return imap.indicies[0] == 0 and imap.indicies.back() == verts.size()-1


func _is_edge_contiguous(imap: SS2D_IndexMap, verts: PackedVector2Array) -> bool:
	if not is_shape_closed():
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
	var verts_t: PackedVector2Array = get_tessellated_points()
	var verts: PackedVector2Array = get_vertices()
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
	var first_idx_t: int = get_tessellated_idx_from_point(verts, verts_t, first_idx)
	var last_idx_t: int = get_tessellated_idx_from_point(verts, verts_t, last_idx)
	edge.first_point_key = _points.get_point_key_at_index(first_idx)
	edge.last_point_key = _points.get_point_key_at_index(last_idx)

	# How many tessellated points are contained within this index map?
	var tess_point_count: int = _edge_data_get_tess_point_count(index_map)
	var should_flip := should_flip_edges()

	var i := 0
	while i < tess_point_count:
		var tess_idx: int = (first_idx_t + i) % verts_t.size()
		var tess_idx_next: int = _get_next_unique_point_idx(tess_idx, verts_t, true)
		var tess_idx_prev: int = _get_previous_unique_point_idx(tess_idx, verts_t, true)

		# set next_point_delta
		# next_point_delta is the number of tess_pts from
		# the current tess_pt to the next unique tess_pt
		# unique meaning it has a different position from the current tess_pt
		var next_point_delta := 0
		for j in range(verts_t.size()):
			if ((tess_idx + j) % verts_t.size()) == tess_idx_next:
				next_point_delta = j
				break

		var vert_idx: int = get_vertex_idx_from_tessellated_point(
				verts, verts_t, tess_idx)
		var vert_key: int = get_point_key_at_index(vert_idx)
		var pt: Vector2 = verts_t[tess_idx]
		var pt_next: Vector2 = verts_t[tess_idx_next]
		var pt_prev: Vector2 = verts_t[tess_idx_prev]

		var texture_idx := 0
		var flip_x: bool = get_point_texture_flip(vert_key)

		var width_scale: float = _get_width_for_tessellated_point(verts, verts_t, tess_idx)
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
				texture_idx = get_point_texture_index(vert_key)
			tex = edge_material.get_texture(texture_idx)
			tex_size = tex.get_size()
			fitmode = edge_material.fit_mode
			# Exit if we have an edge material defined but no texture to render
			if tex == null:
				i += next_point_delta
				continue

		var new_quad: SS2D_Quad = build_quad_from_two_points(
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
				var prev_width: float = _get_width_for_tessellated_point(verts, verts_t, tess_idx_prev)
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

		# Taper Quad
		# Bear in mind, a point can be both first AND last
		# Consider an edge that consists of two points (one edge)
		# This first point is used to generate the quad; it is both first and last
		if is_first_tess_point and edge_material != null and edge_material.use_taper_texture:
			var taper_texture: Texture2D = edge_material.get_texture_taper_left(texture_idx)
			if taper_texture != null:
				var taper_size: Vector2 = taper_texture.get_size()
				var fit: bool = absf(taper_size.x) <= new_quad.get_length_average()
				if fit:
					var taper_quad := new_quad.duplicate()
					taper_quad.corner = 0
					taper_quad.texture = taper_texture
					var delta_normal: Vector2 = (taper_quad.pt_d - taper_quad.pt_a).normalized()
					var offset: Vector2 = delta_normal * taper_size

					taper_quad.pt_d = taper_quad.pt_a + offset
					taper_quad.pt_c = taper_quad.pt_b + offset
					new_quad.pt_a = taper_quad.pt_d
					new_quad.pt_b = taper_quad.pt_c
					new_quads.push_front(taper_quad)
				# If a new taper quad doesn't fit, re-texture the new_quad
				else:
					new_quad.texture = taper_texture
		if is_last_tess_point and edge_material != null and edge_material.use_taper_texture:
			var taper_texture: Texture2D = edge_material.get_texture_taper_right(texture_idx)
			if taper_texture != null:
				var taper_size: Vector2 = taper_texture.get_size()
				var fit: bool = absf(taper_size.x) <= new_quad.get_length_average()
				if fit:
					var taper_quad := new_quad.duplicate()
					taper_quad.corner = 0
					taper_quad.texture = taper_texture
					var delta_normal: Vector2 = (taper_quad.pt_d - taper_quad.pt_a).normalized()
					var offset: Vector2 = delta_normal * taper_size
					taper_quad.pt_a = taper_quad.pt_d - offset
					taper_quad.pt_b = taper_quad.pt_c - offset
					new_quad.pt_d = taper_quad.pt_a
					new_quad.pt_c = taper_quad.pt_b
					new_quads.push_back(taper_quad)
				# If a new taper quad doesn't fit, re-texture the new_quad
				else:
					new_quad.texture = taper_texture

		# Final point for closed shapes fix
		# Corner quads aren't always correctly when the corner is between final and first pt
		if is_last_point and is_edge_contiguous:
			var idx_mid: int = verts_t.size() - 1
			var idx_next: int = _get_next_unique_point_idx(idx_mid, verts_t, true)
			var idx_prev: int = _get_previous_unique_point_idx(idx_mid, verts_t, true)
			var p_p: Vector2 = verts_t[idx_prev]
			var p_m: Vector2 = verts_t[idx_mid]
			var p_n: Vector2 = verts_t[idx_next]
			var w_p: float = _get_width_for_tessellated_point(verts, verts_t, idx_prev)
			var w_m: float = _get_width_for_tessellated_point(verts, verts_t, idx_mid)
			var q: SS2D_Quad = _edge_generate_corner(
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


func _build_edge_with_material_thread_wrapper(args: Array) -> SS2D_Edge:
	return _build_edge_with_material(args[0], args[1], args[2])
