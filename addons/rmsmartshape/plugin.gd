tool
extends EditorPlugin

"""
- Snapping using the build in functionality isn't going to happen
	- https://github.com/godotengine/godot/issues/11180
	- https://godotengine.org/qa/18051/tool-script-in-3-0
"""

# Icons
const ICON_HANDLE = preload("assets/icon_editor_handle.svg")
const ICON_HANDLE_CONTROL = preload("assets/icon_editor_handle_control.svg")
const ICON_ADD_HANDLE = preload("assets/icon_editor_handle_add.svg")
const ICON_CURVE_EDIT = preload("assets/icon_curve_edit.svg")
const ICON_CURVE_CREATE = preload("assets/icon_curve_create.svg")
const ICON_CURVE_DELETE = preload("assets/icon_curve_delete.svg")
const ICON_PIVOT_POINT = preload("assets/icon_editor_position.svg")
const ICON_COLLISION = preload("assets/icon_collision_polygon_2d.svg")
const ICON_SNAP = preload("assets/icon_editor_snap.svg")

enum MODE { EDIT_VERT, EDIT_EDGE, SET_PIVOT }

enum ACTION_VERT {
	NONE = 0,
	MOVE_VERT = 1,
	MOVE_CONTROL = 2,
	MOVE_CONTROL_IN = 3,
	MOVE_CONTROL_OUT = 4
}


# Data related to an action being taken on points
class ActionDataVert:
	func _init(_keys: Array, positions: Array, positions_in: Array, positions_out: Array, t: int):
		type = t
		keys = _keys
		starting_positions = positions
		starting_positions_control_in = positions_in
		starting_positions_control_out = positions_out

	func to_string() -> String:
		var s = "%s: %s = %s"
		return s % [type, keys, starting_positions]

	#Type of Action from the ACTION_VERT enum
	var type: int = ACTION_VERT.NONE

	# The affected Verticies and their initial positions
	var keys = []
	var starting_positions = []
	var starting_positions_control_in = []
	var starting_positions_control_out = []


# PRELOADS
var GUI_SNAP_POPUP = preload("scenes/SnapPopup.tscn")
var GUI_POINT_INFO_PANEL = preload("scenes/GUI_InfoPanel.tscn")
var gui_point_info_panel = GUI_POINT_INFO_PANEL.instance()
var gui_snap_settings = GUI_SNAP_POPUP.instance()

# This is the shape node being edited
var shape: RMSS2D_Shape_Base = null

# Toolbar Stuff
var tb_hb: HBoxContainer = null
var tb_vert_edit: ToolButton = null
var tb_edge_edit: ToolButton = null
var tb_pivot: ToolButton = null
var tb_collision: ToolButton = null
var tb_snap: MenuButton = null
# The PopupMenu that belongs to tb_snap
var tb_snap_popup: PopupMenu = null

# Edge Stuff
var on_edge: bool = false
var edge_point: Vector2

# Track our mode of operation
var current_mode: int = MODE.EDIT_VERT
var previous_mode: int = MODE.EDIT_VERT

# Undo stuff
var undo: UndoRedo = null
var undo_version: int = 0

var current_action = ActionDataVert.new([], [], [], [], ACTION_VERT.NONE)
var cached_shape_global_transform: Transform2D

# Action Move Variables
var _mouse_motion_delta_starting_pos = Vector2(0, 0)

#######
# GUI #
#######


func gui_display_snap_settings():
	var win_size = OS.get_window_size()
	gui_snap_settings.popup_centered_ratio(0.5)
	gui_snap_settings.set_as_minsize()
	# Get Centered
	gui_snap_settings.rect_position = (win_size / 2.0) - gui_snap_settings.rect_size / 2.0
	# Move up
	gui_snap_settings.rect_position.y = (win_size.y / 8.0)


func _snapping_item_selected(id: int):
	if id == 0:
		tb_snap_popup.set_item_checked(id, not tb_snap_popup.is_item_checked(id))
	elif id == 2:
		gui_display_snap_settings()


func _gui_build_toolbar():
	tb_hb = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb)

	var sep = VSeparator.new()
	tb_hb.add_child(sep)

	tb_vert_edit = ToolButton.new()
	tb_vert_edit.icon = ICON_CURVE_EDIT
	tb_vert_edit.toggle_mode = true
	tb_vert_edit.pressed = true
	tb_vert_edit.connect("pressed", self, "_enter_mode", [MODE.EDIT_VERT])
	tb_vert_edit.hint_tooltip = RMSS2D_Strings.EN_TOOLTIP_EDIT
	tb_hb.add_child(tb_vert_edit)

	tb_edge_edit = ToolButton.new()
	tb_edge_edit.icon = ICON_CURVE_EDIT
	tb_edge_edit.toggle_mode = true
	tb_edge_edit.pressed = true
	tb_edge_edit.connect("pressed", self, "_enter_mode", [MODE.EDIT_EDGE])
	tb_edge_edit.hint_tooltip = RMSS2D_Strings.EN_TOOLTIP_EDIT
	tb_hb.add_child(tb_edge_edit)

	tb_pivot = ToolButton.new()
	tb_pivot.icon = ICON_PIVOT_POINT
	tb_pivot.toggle_mode = true
	tb_pivot.pressed = false
	tb_pivot.connect("pressed", self, "_enter_mode", [MODE.SET_PIVOT])
	tb_pivot.hint_tooltip = RMSS2D_Strings.EN_TOOLTIP_PIVOT
	tb_hb.add_child(tb_pivot)

	tb_collision = ToolButton.new()
	tb_collision.icon = ICON_COLLISION
	tb_collision.toggle_mode = false
	tb_collision.pressed = false
	tb_collision.hint_tooltip = RMSS2D_Strings.EN_TOOLTIP_COLLISION
	tb_collision.connect("pressed", self, "_add_collision")
	tb_hb.add_child(tb_collision)

	tb_snap = MenuButton.new()
	tb_snap_popup = tb_snap.get_popup()
	tb_snap.icon = ICON_SNAP
	tb_snap_popup.add_check_item("Snapping Enabled?")
	tb_snap_popup.add_separator()
	tb_snap_popup.add_item("Configure Snap...")
	tb_snap_popup.hide_on_checkable_item_selection = false
	tb_hb.add_child(tb_snap)
	tb_snap_popup.connect("id_pressed", self, "_snapping_item_selected")

	tb_hb.hide()


func _gui_update_info_panel():
	var idx = current_point_index()
	if not is_key_valid(idx):
		gui_point_info_panel.visible = false
		return
	gui_point_info_panel.visible = true
	# Shrink panel
	gui_point_info_panel.rect_size = Vector2(1, 1)

	gui_point_info_panel.set_idx(idx)
	gui_point_info_panel.set_texture_idx(shape.get_point_texture_index(idx))
	gui_point_info_panel.set_width(shape.get_point_width(idx))
	gui_point_info_panel.set_flip(shape.get_point_texture_flip(idx))


func forward_canvas_gui_input(event):
	if not is_shape_valid():
		return false

	var et = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
	var grab_threshold = get_editor_interface().get_editor_settings().get(
		"editors/poly_editor/point_grab_radius"
	)
	var return_value = false

	if event is InputEventKey:
		return_value = _input_handle_keyboard_event(event)

	elif event is InputEventMouseButton:
		return_value = _input_handle_mouse_button_event(event, et, grab_threshold)

	elif event is InputEventMouseMotion:
		return_value = _input_handle_mouse_motion_event(event, et, grab_threshold)

	_gui_update_info_panel()
	return return_value


#########
# GODOT #
#########
func _init():
	pass


func _ready():
	undo = get_undo_redo()
	# Support the undo-redo actions
	_gui_build_toolbar()
	add_child(gui_point_info_panel)
	gui_point_info_panel.visible = false
	add_child(gui_snap_settings)


func _enter_tree():
	pass


func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb)


func _process(delta):
	if not Engine.editor_hint or not is_shape_valid():
		return

	if not shape.is_inside_tree():
		shape = null
		update_overlays()
		return
	# Force update if global transforma has been changed
	if cached_shape_global_transform != shape.get_global_transform():
		shape.set_as_dirty()
		cached_shape_global_transform = shape.get_global_transform()


func handles(object):
	if object is Resource:
		return false

	tb_hb.hide()
	update_overlays()

	var rslt: bool = object is RMSS2D_Shape_Closed or object is RMSS2D_Shape_Open
	return rslt


func edit(object):
	if tb_hb != null:
		tb_hb.show()

	on_edge = false
	deselect_control_points()
	if shape != null:
		shape.disconnect("points_modified", self, "_on_shape_point_modified")
	shape = object as RMSS2D_Shape_Base
	shape.connect("points_modified", self, "_on_shape_point_modified")
	update_overlays()


func make_visible(visible):
	pass


############
# SNAPPING #
############
func use_snap() -> bool:
	return tb_snap_popup.is_item_checked(0)


func get_snap_offset() -> Vector2:
	return gui_snap_settings.get_snap_offset()


func get_snap_step() -> Vector2:
	return gui_snap_settings.get_snap_step()


func _snap_position(pos: Vector2, snap_offset: Vector2, snap_step: Vector2, force: bool = false) -> Vector2:
	if not use_snap() and not force:
		return pos
	var x = pos.x
	if snap_step.x != 0:
		x = pos.x - fmod(pos.x, snap_step.x)

	var y = pos.y
	if snap_step.y != 0:
		y = pos.y - fmod(pos.y, snap_step.y)

	return Vector2(x, y) + snap_offset


##########
# PLUGIN #
##########
func _on_shape_point_modified():
	_action_invert_orientation()


func _enter_mode(mode: int):
	for tb in [tb_vert_edit, tb_edge_edit, tb_pivot]:
		tb.pressed = false

	previous_mode = current_mode
	current_mode = mode
	match mode:
		MODE.EDIT_VERT:
			tb_vert_edit.pressed = true
		MODE.EDIT_EDGE:
			tb_edge_edit.pressed = true
		MODE.SET_PIVOT:
			tb_pivot.pressed = true
		_:
			tb_vert_edit.pressed = true


func _set_pivot(point: Vector2):
	var et = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform

	var np: Vector2 = point
	var ct: Transform2D = shape.get_global_transform()
	ct.origin = np

	for i in shape.get_point_count():
		var key = shape.get_point_key_at_index(i)
		var pt = shape.get_global_transform().xform(shape.get_point_position(key))
		shape.set_point_position(key, ct.affine_inverse().xform(pt))

	shape.position = shape.get_parent().get_global_transform().affine_inverse().xform(np)
	_enter_mode(current_mode)
	update_overlays()


func _add_collision():
	call_deferred("_add_deferred_collision")


func _add_deferred_collision():
	if not shape.get_parent() is StaticBody2D:
		var static_body: StaticBody2D = StaticBody2D.new()
		var t: Transform2D = shape.transform
		static_body.position = shape.position
		shape.position = Vector2.ZERO

		shape.get_parent().add_child(static_body)
		static_body.owner = get_editor_interface().get_edited_scene_root()

		shape.get_parent().remove_child(shape)
		static_body.add_child(shape)
		shape.owner = get_editor_interface().get_edited_scene_root()

		var poly: CollisionPolygon2D = CollisionPolygon2D.new()
		static_body.add_child(poly)
		poly.owner = get_editor_interface().get_edited_scene_root()
		# TODO: Make this a option at some point
		poly.modulate.a = 0.3
		poly.visible = false
		shape.collision_polygon_node_path = shape.get_path_to(poly)
		shape.set_as_dirty()


#########
# VERTS #
#########
func is_single_vert_selected() -> bool:
	if current_action.keys.size() == 1:
		return is_key_valid(current_action.keys[0])
	return false


func is_shape_valid() -> bool:
	if shape == null:
		return false
	if not is_instance_valid(shape):
		return false
	return true


func are_keys_valid(keys: Array) -> bool:
	for key in keys:
		if not is_key_valid(key):
			return false
	return true


func is_key_valid(key: int) -> bool:
	if not is_shape_valid():
		return false
	return shape.has_point(key)


func is_index_valid(idx: int) -> bool:
	if not is_shape_valid():
		return false
	return shape.is_index_in_range(idx)


func current_point_index() -> int:
	if not is_single_vert_selected():
		return -1
	return shape.get_point_index(current_action.keys[0])


func current_point_key() -> int:
	if not is_single_vert_selected():
		return -1
	return current_action.keys[0]


func _get_intersecting_control_point_in(mouse_pos: Vector2, grab_threshold: float) -> Array:
	var points = []
	var xform: Transform2D = (
		get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
		* shape.get_global_transform()
	)
	for i in range(0, shape.get_point_count(), 1):
		var key = shape.get_point_key_at_index(i)
		var vec = shape.get_point_position(key)
		var c_in = vec + shape.get_point_in(key)
		c_in = xform.xform(c_in)
		if c_in.distance_to(mouse_pos) <= grab_threshold:
			points.push_back(i)

	return points


func _get_intersecting_control_point_out(mouse_pos: Vector2, grab_threshold: float) -> Array:
	var points = []
	var xform: Transform2D = (
		get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
		* shape.get_global_transform()
	)
	for i in range(0, shape.get_point_count(), 1):
		var key = shape.get_point_key_at_index(i)
		var vec = shape.get_point_position(key)
		var c_out = vec + shape.get_point_out(key)
		c_out = xform.xform(c_out)
		if c_out.distance_to(mouse_pos) <= grab_threshold:
			points.push_back(i)

	return points


###########
# ACTIONS #
###########
func _action_set_pivot(pos: Vector2, et: Transform2D):
	var old_pos = et.xform(shape.get_parent().get_global_transform().xform(shape.position))
	undo.create_action("Set Pivot")
	var snapped_position = _snap_position(
		et.affine_inverse().xform(pos), get_snap_offset(), get_snap_step()
	)
	undo.add_do_method(self, "_set_pivot", snapped_position)
	undo.add_undo_method(self, "_set_pivot", et.affine_inverse().xform(old_pos))
	undo.add_do_method(shape, "set_as_dirty")
	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()


func _action_move_verticies():
	undo.create_action("Move Vertex")

	for i in range(0, current_action.keys.size(), 1):
		var key = current_action.keys[i]
		var from_position = current_action.starting_positions[i]
		var this_position = shape.get_point_position(key)
		undo.add_do_method(shape, "set_point_position", key, this_position)
		undo.add_undo_method(shape, "set_point_position", key, from_position)

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()


func _action_move_control_points(_in: bool, _out: bool):
	if not _in and not _out:
		return
	undo.create_action("Move Control Point")

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")

	for i in range(0, current_action.keys.size(), 1):
		var key = current_action.keys[i]
		var from_position_in = current_action.starting_positions_control_in[i]
		var from_position_out = current_action.starting_positions_control_out[i]
		if _in:
			undo.add_undo_method(shape, "set_point_in", key, from_position_in)
		if _out:
			undo.add_undo_method(shape, "set_point_out", key, from_position_out)

	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()


func _action_delete_point_in(key: int):
	var from_position_in = shape.get_point_in(key)
	undo.create_action("Delete Control Point In")

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")

	undo.add_undo_method(shape, "set_point_in", key, from_position_in)
	shape.set_point_in(key, Vector2(0, 0))

	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	_action_invert_orientation()


func _action_delete_point_out(key: int):
	var from_position_out = shape.get_point_out(key)
	undo.create_action("Delete Control Point Out")

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")

	undo.add_undo_method(shape, "set_point_out", key, from_position_out)
	shape.set_point_out(key, Vector2(0, 0))

	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	_action_invert_orientation()


func _action_delete_point():
	undo.create_action("Delete Point")
	var pt: Vector2 = shape.get_point_position(current_point_key())
	var current_index = current_point_index()
	undo.add_do_method(shape, "remove_point", current_point_key())
	undo.add_undo_method(shape, "add_point", pt, current_index)

	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.add_do_method(shape, "set_as_dirty")
	undo.add_undo_method(shape, "set_as_dirty")
	undo.commit_action()
	undo_version = undo.get_version()
	_action_invert_orientation()


func _action_add_point(new_point: Vector2) -> int:
	"""
	Will return key of added point
	"""
	undo.create_action("Add Point: %s" % new_point)
	undo.add_do_method(shape, "add_point", new_point)
	undo.add_undo_method(
		shape, "remove_point_at_index", shape.get_last_point_index(shape.get_vertices()) + 1
	)
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	var key = shape.get_point_at_index(shape.get_point_count() - 1)
	_action_invert_orientation()
	return key


func _action_split_curve(idx: int, gpoint: Vector2, xform: Transform2D):
	"""
	Will split the shape at the given index
	The key of the new point will be returned
	If the orientation is changed, idx will be updated
	"""
	idx = shape.adjust_add_point_index(idx)
	undo.create_action("Split Curve")
	undo.add_do_method(shape, "add_point", xform.affine_inverse().xform(gpoint), idx)
	undo.add_undo_method(shape, "remove_point_at_index", idx)
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	var key = shape.get_point_key_at_index(idx)
	_action_invert_orientation()
	return key


func _should_invert_orientation() -> bool:
	if shape == null:
		return false
	if shape is RMSS2D_Shape_Open:
		return false
	return not shape.are_points_clockwise() and shape.get_point_count() >= 3


func _action_invert_orientation() -> bool:
	"""
	Will reverse the orientation of the shape verticies
	This does not create or commit an undo action on its own
	It's meant to be included with another action
	Therefore, the function should be called between a block like so:
		undo.create_action("xxx")
		_action_invert_orientation()-
		undo.commit_action()
	"""
	if _should_invert_orientation():
		undo.create_action("Invert Orientation")
		undo.add_do_method(shape, "invert_point_order")
		undo.add_undo_method(shape, "invert_point_order")

		undo.add_do_method(current_action, "invert", shape.get_point_count())
		undo.add_undo_method(current_action, "invert", shape.get_point_count())
		undo.commit_action()
		undo_version = undo.get_version()
		return true
	return false


func deselect_control_points():
	current_action = ActionDataVert.new([], [], [], [], ACTION_VERT.NONE)


func select_verticies(keys: Array, action: int) -> ActionDataVert:
	var from_positions = []
	var from_positions_c_in = []
	var from_positions_c_out = []
	for key in keys:
		from_positions.push_back(shape.get_point_position(key))
		from_positions_c_in.push_back(shape.get_point_in(key))
		from_positions_c_out.push_back(shape.get_point_out(key))
	return ActionDataVert.new(
		keys, from_positions, from_positions_c_in, from_positions_c_out, action
	)


func select_vertices_to_move(keys: Array, _mouse_starting_pos_viewport: Vector2):
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport
	current_action = select_verticies(keys, ACTION_VERT.MOVE_VERT)


func select_control_points_to_move(
	keys: Array, _mouse_starting_pos_viewport: Vector2, action = ACTION_VERT.MOVE_CONTROL
):
	current_action = select_verticies(keys, action)
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport


#############
# RENDERING #
#############
func forward_canvas_draw_over_viewport(overlay: Control):
	if not is_shape_valid():
		return

	# Something might force a draw which we had no control over,
	# in this case do some updating to be sure
	if undo_version != undo.get_version():
		if (
			undo.get_current_action_name() == "Move CanvasItem"
			or undo.get_current_action_name() == "Rotate CanvasItem"
			or undo.get_current_action_name() == "Scale CanvasItem"
		):
			shape.set_as_dirty()
			undo_version = undo.get_version()

	var t: Transform2D = (
		get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
		* shape.get_global_transform()
	)
	var verts = shape.get_vertices()
	var points = shape.get_tessellated_points()
	var length = points.size()

	# Draw Outline
	var fpt = null
	var ppt = null
	for i in length:
		var pt = points[i]
		if ppt != null:
			overlay.draw_line(ppt, t.xform(pt), shape.modulate)
		ppt = t.xform(pt)
		if fpt == null:
			fpt = ppt

	# Draw handles
	for i in range(0, verts.size(), 1):
		var key = shape.get_point_key_at_index(i)
		var smooth = false
		var hp = t.xform(verts[i])
		overlay.draw_texture(ICON_HANDLE, hp - ICON_HANDLE.get_size() * 0.5)

		# Draw handles for control-point-out
		# Drawing the point-out for the last point makes no sense, as there's no point ahead of it
		if i < verts.size() - 1:
			var pointout = t.xform(verts[i] + shape.get_point_out(key))
			if hp != pointout:
				smooth = true
				_draw_control_point_line(overlay, hp, pointout, ICON_HANDLE_CONTROL)

		# Draw handles for control-point-in
		# Drawing the point-in for point 0 makes no sense, as there's no point behind it
		if i > 0:
			var pointin = t.xform(verts[i] + shape.get_point_in(key))
			if hp != pointin:
				smooth = true
				_draw_control_point_line(overlay, hp, pointin, ICON_HANDLE_CONTROL)

	if on_edge:
		overlay.draw_texture(ICON_ADD_HANDLE, edge_point - ICON_ADD_HANDLE.get_size() * 0.5)

	# Draw Highlighted Handle
	if is_single_vert_selected():
		overlay.draw_circle(t.xform(verts[current_point_index()]), 5, Color.white)
		overlay.draw_circle(t.xform(verts[current_point_index()]), 3, Color.black)

	shape.update()


func _draw_control_point_line(c: Control, vert: Vector2, cp: Vector2, tex: Texture):
	# Draw the line with a dark and light color to be visible on all backgrounds
	var color_dark = Color(0, 0, 0, 0.5)
	var color_light = Color(1, 1, 1, 0.5)
	var width = 1.0
	c.draw_line(vert, cp, color_dark, width)
	c.draw_line(vert, cp, color_light, width)
	c.draw_texture(tex, cp - tex.get_size() * 0.5)


#########
# INPUT #
#########


func _input_handle_right_click_press(mb_position: Vector2, grab_threshold: float) -> bool:
	# Mouse over a single vertex?
	if is_single_vert_selected():
		_action_delete_point()
		deselect_control_points()
		return true
	else:
		# Mouse over a control point?
		var points_in = _get_intersecting_control_point_in(mb_position, grab_threshold)
		var points_out = _get_intersecting_control_point_out(mb_position, grab_threshold)
		if not points_in.empty():
			_action_delete_point_in(points_in[0])
			return true
		elif not points_out.empty():
			_action_delete_point_out(points_out[0])
			return true
	return false


func _input_handle_left_click(
	mb: InputEventMouseButton,
	vp_m_pos: Vector2,
	t: Transform2D,
	et: Transform2D,
	grab_threshold: float
) -> bool:
	# Set Pivot?
	if (current_mode == MODE.SET_PIVOT) or (mb.control):
		_action_set_pivot(mb.position, et)
		return true

	# Highlighting a vert to move or add control points to
	if is_single_vert_selected():
		if Input.is_key_pressed(KEY_SHIFT):
			select_control_points_to_move([current_point_key()], vp_m_pos)
			return true
		else:
			select_vertices_to_move([current_point_key()], vp_m_pos)
			return true

	# Split the Edge?
	if _input_split_edge(mb, vp_m_pos, t):
		return true

	if not on_edge:
		# Any nearby control points to move?
		if _input_move_control_points(mb, vp_m_pos, grab_threshold):
			return true

		# Create new point
		var snapped_pos = _snap_position(
			t.affine_inverse().xform(mb.position), get_snap_offset(), get_snap_step()
		)
		select_vertices_to_move([_action_add_point(snapped_pos)], vp_m_pos)
		return true
	return false


func _input_handle_mouse_wheel(btn: int) -> bool:
	if Input.is_key_pressed(KEY_SHIFT):
		var width = shape.get_point_width(current_point_key())
		var width_step = 0.1
		if btn == BUTTON_WHEEL_DOWN:
			width_step *= -1
		var new_width = width + width_step
		shape.set_point_width(new_width, current_point_key())

	else:
		var texture_idx_step = 1
		if btn == BUTTON_WHEEL_DOWN:
			texture_idx_step *= -1

		var tex_idx: int = shape.get_point_texture_index(current_point_key()) + texture_idx_step
		shape.set_point_texture_index(current_point_key(), tex_idx)

	shape.set_as_dirty()
	update_overlays()
	_gui_update_info_panel()

	return true


func _is_valid_keyboard_scancode(kb: InputEventKey) -> bool:
	match kb.scancode:
		KEY_SPACE:
			return true
		KEY_SHIFT:
			return true
	return false


func _input_handle_keyboard_event(event: InputEventKey) -> bool:
	var kb: InputEventKey = event
	if _is_valid_keyboard_scancode(kb):
		if is_single_vert_selected():
			if kb.pressed and kb.scancode == KEY_SPACE:
				shape.set_point_texture_flip(
					! shape.get_point_texture_flip(current_point_key()), current_point_key()
				)
				shape.set_as_dirty()
				shape.update()
				_gui_update_info_panel()
		return true
	return false


func _input_handle_mouse_button_event(
	event: InputEventMouseButton, et: Transform2D, grab_threshold: float
) -> bool:
	var rslt: bool = false
	var t: Transform2D = et * shape.get_global_transform()
	var mb: InputEventMouseButton = event
	var viewport_mouse_position = et.affine_inverse().xform(mb.position)
	var mouse_wheel_spun = (
		mb.pressed
		and (mb.button_index == BUTTON_WHEEL_DOWN or mb.button_index == BUTTON_WHEEL_UP)
	)

	#######################################
	# Mouse Button released
	if not mb.pressed and mb.button_index == BUTTON_LEFT:
		if current_action.type == ACTION_VERT.MOVE_VERT:
			if (
				current_action.starting_positions[0].distance_to(
					shape.get_point_position(current_action.keys[0])
				)
				> grab_threshold
			):
				_action_move_verticies()
				rslt = true
		var type = current_action.type
		var _in = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_IN
		var _out = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_OUT
		if _in or _out:
			_action_move_control_points(_in, _out)
			rslt = true
		deselect_control_points()
		return rslt

	# PRESSED RIGHT CLICK
	elif mb.pressed and mb.button_index == BUTTON_RIGHT:
		return _input_handle_right_click_press(mb.position, grab_threshold)

	#########################################
	# Mouse Wheel on valid point
	elif mouse_wheel_spun and is_single_vert_selected():
		return _input_handle_mouse_wheel(mb.button_index)

	#########################################
	# Mouse left click on valid point
	elif mb.pressed and mb.button_index == BUTTON_LEFT:
		return _input_handle_left_click(mb, viewport_mouse_position, t, et, grab_threshold)

	return false


func _input_split_edge(mb: InputEventMouseButton, vp_m_pos: Vector2, t: Transform2D) -> bool:
	if not on_edge:
		return false
	var gpoint: Vector2 = mb.position
	var insertion_point: int = -1
	var mb_length = shape.get_closest_offset(t.affine_inverse().xform(gpoint))

	for i in range(0, shape.get_point_count(), 1):
		var key = shape.get_point_key_at_index(i)
		var key_next = shape.get_point_key_at_index(i + 1)
		var compareLength = shape.get_closest_offset(shape.get_point_position(key_next))
		if (
			mb_length >= shape.get_closest_offset(shape.get_point_position(key))
			and mb_length <= compareLength
		):
			insertion_point = i + 1

	if insertion_point == -1:
		insertion_point = shape.get_point_count() - 1

	var key = _action_split_curve(insertion_point, gpoint, t)
	select_vertices_to_move([key], vp_m_pos)
	on_edge = false

	return true


func _input_move_control_points(mb: InputEventMouseButton, vp_m_pos: Vector2, grab_threshold: float) -> bool:
	var points_in = _get_intersecting_control_point_in(mb.position, grab_threshold)
	var points_out = _get_intersecting_control_point_out(mb.position, grab_threshold)
	if not points_in.empty():
		select_control_points_to_move([points_in[0]], vp_m_pos, ACTION_VERT.MOVE_CONTROL_IN)
		return true
	elif not points_out.empty():
		select_control_points_to_move([points_out[0]], vp_m_pos, ACTION_VERT.MOVE_CONTROL_OUT)
		return true
	return false


func _input_handle_mouse_motion_event(
	event: InputEventMouseMotion, et: Transform2D, grab_threshold: float
) -> bool:
	var t: Transform2D = et * shape.get_global_transform()
	var mm: InputEventMouseMotion = event
	var delta_current_pos = et.affine_inverse().xform(mm.position)
	#print(mm.position)
	gui_point_info_panel.rect_position = mm.position + Vector2(256, -24)
	var delta = delta_current_pos - _mouse_motion_delta_starting_pos

	var type = current_action.type
	var _in = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_IN
	var _out = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_OUT

	#_debug_mouse_positions(mm, et)

	if type == ACTION_VERT.MOVE_VERT:
		return _input_motion_move_verts(delta)

	elif _in or _out:
		return _input_motion_move_control_points(delta, _in, _out)

	# Handle Edge Follow
	var old_edge: bool = on_edge
	on_edge = _input_motion_is_on_edge(mm, grab_threshold)
	if on_edge or old_edge != on_edge:
		deselect_control_points()
		update_overlays()

	return false


func _input_motion_move_verts(delta: Vector2) -> bool:
	for i in range(0, current_action.keys.size(), 1):
		var key = current_action.keys[i]
		var from = current_action.starting_positions[i]
		var new_position = from + delta
		var snapped_position = _snap_position(new_position, get_snap_offset(), get_snap_step())
		shape.set_point_position(key, snapped_position)
		update_overlays()
	return true


func _input_motion_move_control_points(delta: Vector2, _in: bool, _out: bool) -> bool:
	var rslt = false
	for i in range(0, current_action.keys.size(), 1):
		var key = current_action.keys[i]
		var from = current_action.starting_positions[i]
		var out_multiplier = 1
		# Invert the delta for position_out if moving both at once
		if _out:
			out_multiplier = -1
		var new_position_in = delta + current_action.starting_positions_control_in[i]
		var new_position_out = (
			(delta * out_multiplier)
			+ current_action.starting_positions_control_out[i]
		)
		var snapped_position_in = _snap_position(
			new_position_in, get_snap_offset(), get_snap_step()
		)
		var snapped_position_out = _snap_position(
			new_position_out, get_snap_offset(), get_snap_step()
		)
		if _in:
			shape.set_point_in(key, snapped_position_in)
			rslt = true
		if _out:
			shape.set_point_out(key, snapped_position_out)
			rslt = true
		shape.set_as_dirty()
		update_overlays()
	return false


func _input_motion_is_on_edge(mm: InputEventMouseMotion, grab_threshold: float) -> bool:
	var xform: Transform2D = (
		get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
		* shape.get_global_transform()
	)
	var gpoint: Vector2 = mm.position
	if shape.get_point_count() < 2:
		return false
	if current_mode != MODE.EDIT_VERT:
		return false

	# Find edge
	var is_on_edge = false
	var closest_point = shape.get_closest_point(xform.affine_inverse().xform(mm.position))
	if closest_point != null:
		edge_point = xform.xform(closest_point)
		if edge_point.distance_to(gpoint) <= grab_threshold:
			is_on_edge = true

		# However, if near a control point or one of its handles then we are not on the edge
		for k in shape.get_all_point_keys():
			var pp: Vector2 = shape.get_point_position(k)
			var p: Vector2 = xform.xform(pp)
			if p.distance_to(gpoint) <= grab_threshold:
				is_on_edge = false
				current_action = select_verticies([k], ACTION_VERT.NONE)
				break
	return is_on_edge


#########
# DEBUG #
#########
func _debug_mouse_positions(mm, t):
	print("========================================")
	print("MouseDelta:%s" % str(_mouse_motion_delta_starting_pos))
	print("= MousePositions =")
	print("Position:  %s" % str(mm.position))
	print("Relative:  %s" % str(mm.relative))
	print("= Transforms =")
	print("Transform: %s" % str(t))
	print("Inverse:   %s" % str(t.affine_inverse()))
	print("= Transformed Mouse positions =")
	print("Position:  %s" % str(t.affine_inverse().xform(mm.position)))
	print("Relative:  %s" % str(t.affine_inverse().xform(mm.relative)))
	print("MouseDelta:%s" % str(t.affine_inverse().xform(_mouse_motion_delta_starting_pos)))
