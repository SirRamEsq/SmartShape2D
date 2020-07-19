tool
extends EditorPlugin

"""
- Snapping using the build in functionality isn't going to happen
	- https://github.com/godotengine/godot/issues/11180
	- https://godotengine.org/qa/18051/tool-script-in-3-0
"""

enum MODE {
	EDIT,
	CREATE,
	DELETE,
	SET_PIVOT
}

enum ACTION {
	NONE = 0,
	MOVING_VERT = 1,
	# Moving both control points
	MOVING_CONTROL = 2,
	# Moving control in
	MOVING_CONTROL_IN = 3,
	# Moving control out
	MOVING_CONTROL_OUT = 4
}

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

var GUI_SNAP_POPUP = preload("scenes/SnapPopup.tscn")
var GUI_INFO_PANEL = preload("scenes/GUI_InfoPanel.tscn")
var gui_info_panel = GUI_INFO_PANEL.instance()


# This is the shape node being edited
var shape:RMSS2D_Shape_Base = null

# Toolbar Stuff
var tb_hb:HBoxContainer = null
var tb_edit:ToolButton = null
var tb_create:ToolButton = null
var tb_delete:ToolButton = null
var tb_pivot:ToolButton = null
var tb_collision:ToolButton = null
var tb_snapping:MenuButton = null

# Edge Stuff
var on_edge:bool = false
var edge_point:Vector2

func _invert_idx(idx:int, array_size:int):
	return array_size - idx - 1

# Data related to an action being taken
class ActionData:
	func _init(_indices:Array, positions:Array, positions_in:Array, positions_out:Array, t:int):
		type = t
		indices = _indices
		starting_positions = positions
		starting_positions_control_in = positions_in
		starting_positions_control_out = positions_out

	func invert(array_size:int):
		for i in range(0, indices.size(), 1):
			var new_idx = array_size - indices[i] - 1
			indices[i] = new_idx

	func to_string()->String:
		var s = "%s: %s\n%s"
		return s % [type, indices, starting_positions]

	#Type of Action ("Action" Enum)
	var type:int = 0

	# The affected Verticies and their initial positions
	var indices = []
	var starting_positions = []
	var starting_positions_control_in = []
	var starting_positions_control_out = []

var current_action = ActionData.new([], [], [], [], ACTION.NONE)
var cached_shape_global_transform:Transform2D

# Track our mode of operation
var current_mode:int = MODE.EDIT
var previous_mode:int = MODE.EDIT

# Undo stuff
var undo:UndoRedo = null
var undo_version:int = 0

# Action Move Variables
var _mouse_motion_delta_starting_pos = Vector2(0,0)

var snap_popup_menu
var snap_popup_settings
func display_snap_popup():
	var win_size = OS.get_window_size()
	snap_popup_settings.popup_centered_ratio(0.5)
	snap_popup_settings.set_as_minsize()
	# Get Centered
	snap_popup_settings.rect_position = (win_size / 2.0) - snap_popup_settings.rect_size / 2.0
	# Move up
	snap_popup_settings.rect_position.y = (win_size.y / 8.0)

func _create_snap_configure_popup():
	if snap_popup_settings == null:
		print("creating popup")
		snap_popup_settings = GUI_SNAP_POPUP.instance()
		#snap_popup_settings.popup_exclusive = true
		add_child(snap_popup_settings)


func _snapping_item_selected(id:int):
	print(id)
	if id == 0:
		snap_popup_menu.set_item_checked(id, not snap_popup_menu.is_item_checked(id))
	elif id == 2:
		display_snap_popup()


func _ready():
	_init_undo()
	_create_snap_configure_popup()
	_build_toolbar()
	add_child(gui_info_panel)
	gui_info_panel.visible = false

func _init_undo():
	# Support the undo-redo actions
	undo = get_undo_redo()

func _build_toolbar():
	# Build up tool bar when editing RMSmartShape2D
	tb_hb = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb)

	var sep = VSeparator.new()
	tb_hb.add_child(sep)

	tb_edit = ToolButton.new()
	tb_edit.icon = ICON_CURVE_EDIT
	tb_edit.toggle_mode = true
	tb_edit.pressed = true
	tb_edit.connect("pressed", self, "_enter_mode", [MODE.EDIT])
	tb_edit.hint_tooltip = RMSS2D_Strings.EN_TOOLTIP_EDIT
	tb_hb.add_child(tb_edit)

	tb_create = ToolButton.new()
	tb_create.icon = ICON_CURVE_CREATE
	tb_create.toggle_mode = true
	tb_create.pressed = false
	tb_create.connect("pressed", self, "_enter_mode", [MODE.CREATE])
	tb_create.hint_tooltip = RMSS2D_Strings.EN_TOOLTIP_CREATE
	tb_hb.add_child(tb_create)

	tb_delete = ToolButton.new()
	tb_delete.icon = ICON_CURVE_DELETE
	tb_delete.toggle_mode = true
	tb_delete.pressed = false
	tb_delete.connect("pressed", self, "_enter_mode", [MODE.DELETE])
	tb_delete.hint_tooltip = RMSS2D_Strings.EN_TOOLTIP_DELETE
	tb_hb.add_child(tb_delete)

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

	tb_snapping = MenuButton.new()
	snap_popup_menu = tb_snapping.get_popup()
	tb_snapping.icon = ICON_SNAP
	snap_popup_menu.add_check_item("Snapping Enabled?")
	snap_popup_menu.add_separator()
	snap_popup_menu.add_item("Configure Snap...")
	snap_popup_menu.hide_on_checkable_item_selection = false
	tb_hb.add_child(tb_snapping)
	snap_popup_menu.connect("id_pressed", self, "_snapping_item_selected")

	tb_hb.hide()

func _enter_tree():
	pass

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb)

func _process(delta):
	if Engine.editor_hint:
		if shape != null:
			if not is_instance_valid(shape):
				shape = null
				update_overlays()
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

	var rslt:bool = object is RMSS2D_Shape_Closed or object is RMSS2D_Shape_Open
	tb_hb.hide()
	update_overlays()

	return rslt

func edit(object):
	if tb_hb != null:
		tb_hb.show()

	on_edge = false
	deselect_control_points()
	if shape != null:
		shape.disconnect ("points_modified", self, "_on_shape_point_modified")
	shape = object as RMSS2D_Shape_Base
	shape.connect("points_modified", self, "_on_shape_point_modified")
	update_overlays()

func _untoggle_all():
	for tb in [tb_edit, tb_create, tb_delete, tb_pivot]:
		tb.pressed=false

func _enter_mode(mode:int):
	_untoggle_all()

	if mode == MODE.EDIT:
		tb_edit.pressed = true
	if mode == MODE.CREATE:
		tb_create.pressed = true
	if mode == MODE.DELETE:
		tb_delete.pressed = true
	if mode == MODE.SET_PIVOT:
		previous_mode = current_mode
		tb_pivot.pressed = true

	current_mode = mode

func _set_pivot(point:Vector2):
	var et = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform

	var np:Vector2 = point
	var ct:Transform2D = shape.get_global_transform()
	ct.origin = np

	for i in shape.get_point_count():
		var pt = shape.get_global_transform().xform(shape.get_point_position(i))
		shape.set_point_position(i, ct.affine_inverse().xform(pt))

	shape.position = shape.get_parent().get_global_transform().affine_inverse().xform( np)
	current_mode = previous_mode
	_enter_mode(current_mode)
	update_overlays()

func make_visible(visible):
	pass

func _snap_position(pos:Vector2, snap_offset:Vector2, snap_step:Vector2) -> Vector2:
	if not use_snap():
		return pos
	var x = pos.x
	if snap_step.x != 0:
		x = pos.x - fmod(pos.x, snap_step.x)

	var y = pos.y
	if snap_step.y != 0:
		y = pos.y - fmod(pos.y, snap_step.y)

	return Vector2(x,y) + snap_offset

func update_gui_info_panel():
	var idx = current_point_index()
	if not is_point_index_valid(idx):
		gui_info_panel.visible = false
		return
	gui_info_panel.visible = true
	# Shrink panel
	gui_info_panel.rect_size = Vector2(1,1)

	gui_info_panel.set_idx(idx)
	gui_info_panel.set_texture_idx(shape.get_point_texture_index(idx))
	gui_info_panel.set_width(shape.get_point_width(idx))
	gui_info_panel.set_flip(shape.get_point_texture_flip(idx))

func is_single_point_index_valid()->bool:
	if current_action.indices.size() == 1:
		return is_point_index_valid(current_action.indices[0])
	return false

func is_shape_valid()->bool:
	if shape == null:
		return false
	if not is_instance_valid(shape):
		return false
	return true

func are_point_indices_valid(indices:Array)->bool:
	for idx in indices:
		if not is_point_index_valid(idx):
			return false
	return true

func is_point_index_valid(idx:int)->bool:
	if not is_shape_valid():
		return false
	return (idx >= 0 and idx < shape.get_point_count())

func current_point_index()->int:
	if not is_single_point_index_valid():
		return -1
	return current_action.indices[0]

func _is_valid_keyboard_scancode(kb:InputEventKey)->bool:
	match(kb.scancode):
		KEY_SPACE:
			return true
		KEY_SHIFT:
			return true
	return false

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


func forward_canvas_gui_input(event):
	if shape == null:
		return false

	if not is_instance_valid(shape):
		return false

	var et = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
	var grab_threshold = get_editor_interface().get_editor_settings().get("editors/poly_editor/point_grab_radius")
	update_gui_info_panel()

	if event is InputEventKey:
		return _input_handle_keyboard_event(event)

	elif event is InputEventMouseButton:
		return _input_handle_mouse_button_event(event, et, grab_threshold)

	elif event is InputEventMouseMotion:
		return _input_handle_mouse_motion_event(event, et, grab_threshold)

	return false


func _curve_changed():
	deselect_control_points()
	update_overlays()

func _add_collision():
	call_deferred("_add_deferred_collision")

func _add_deferred_collision():
	if (shape.get_parent() is StaticBody2D) == false:
		var staticBody:StaticBody2D = StaticBody2D.new()
		var t:Transform2D = shape.transform
		staticBody.position = shape.position
		shape.position = Vector2.ZERO

		shape.get_parent().add_child(staticBody)
		staticBody.owner = get_editor_interface().get_edited_scene_root()

		shape.get_parent().remove_child(shape)
		staticBody.add_child(shape)
		shape.owner = get_editor_interface().get_edited_scene_root()

		var colPolygon:CollisionPolygon2D = CollisionPolygon2D.new()
		staticBody.add_child(colPolygon)
		colPolygon.owner = get_editor_interface().get_edited_scene_root()
		# TODO: Make this a option at some point
		colPolygon.modulate.a = 0.3
		colPolygon.visible = false

		shape.collision_polygon_node_path = shape.get_path_to(colPolygon)

		shape.set_as_dirty()

func _handle_auto_collision_press():
	pass


func use_snap()->bool:
	return snap_popup_menu.is_item_checked(0)

func get_snap_offset()->Vector2:
	return snap_popup_settings.get_snap_offset()

func get_snap_step()->Vector2:
	return snap_popup_settings.get_snap_step()

###########
# ACTIONS #
###########
func _action_set_pivot(pos:Vector2, et:Transform2D):
	var old_pos = et.xform( shape.get_parent().get_global_transform().xform(shape.position))
	undo.create_action("Set Pivot")
	var snapped_position = _snap_position(et.affine_inverse().xform(pos), get_snap_offset(), get_snap_step())
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

	for i in range(0, current_action.indices.size(), 1):
		var idx = current_action.indices[i]
		var from_position = current_action.starting_positions[i]
		var this_position = shape.get_point_position(idx)
		undo.add_do_method(shape, "set_point_position", idx, this_position)
		undo.add_undo_method(shape, "set_point_position", idx, from_position)

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()

func _action_move_control_points(_in:bool, _out:bool):
	if not _in and not _out:
		return
	undo.create_action("Move Control Point")

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")

	for i in range(0, current_action.indices.size(), 1):
		var idx = current_action.indices[i]
		var from_position_in = current_action.starting_positions_control_in[i]
		var from_position_out = current_action.starting_positions_control_out[i]
		if _in:
			undo.add_undo_method(shape, "set_point_in", idx, from_position_in)
		if _out:
			undo.add_undo_method(shape, "set_point_out", idx, from_position_out)

	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()

func _action_delete_point_in(idx:int):
	var from_position_in = shape.get_point_in(idx)
	undo.create_action("Delete Control Point In")

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")

	undo.add_undo_method(shape, "set_point_in", idx, from_position_in)
	shape.set_point_in(idx, Vector2(0,0))

	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	_action_invert_orientation()

func _action_delete_point_out(idx:int):
	var from_position_out = shape.get_point_out(idx)
	undo.create_action("Delete Control Point Out")

	undo.add_do_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")

	undo.add_undo_method(shape, "set_point_out", idx, from_position_out)
	shape.set_point_out(idx, Vector2(0,0))

	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	_action_invert_orientation()

func _action_delete_point():
	var fix_close_shape = false
	undo.create_action("Delete Point")
	var pt:Vector2 = shape.get_point_position(current_point_index())
	undo.add_do_method(shape, "remove_point", current_point_index())
	undo.add_undo_method(shape, "add_point_to_curve", pt, current_point_index())

	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.add_do_method(shape, "set_as_dirty")
	undo.add_undo_method(shape, "set_as_dirty")
	undo.commit_action()
	undo_version = undo.get_version()
	if fix_close_shape:
		shape.fix_close_shape()
	_action_invert_orientation()

func _action_add_point(new_point:Vector2)->int:
	"""
	Will return index of added point
	"""
	undo.create_action("Add Point: %s" % new_point)
	undo.add_do_method(shape, "add_point_to_curve", new_point)
	undo.add_undo_method(shape,"remove_point", shape.get_point_count())
	undo.add_do_method(shape, "set_as_dirty")
	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	if _action_invert_orientation():
		return 0
	return shape.get_point_count() - 1


func _action_split_curve(idx:int, gpoint:Vector2, xform:Transform2D):
	"""
	Will split the shape at the given index
	The idx of the new point will be returned
	If the orientation is changed, idx will be updated
	"""
	undo.create_action("Split Curve")
	undo.add_do_method(shape, "add_point_to_curve", xform.affine_inverse().xform(gpoint), idx)
	undo.add_undo_method(shape, "remove_point", idx)
	undo.add_do_method(shape, "set_as_dirty")
	undo.add_undo_method(shape, "set_as_dirty")
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()
	if _action_invert_orientation():
		return _invert_idx(idx, shape.get_point_count())
	return idx

func _should_invert_orientation()->bool:
	if shape == null:
		return false
	if shape is RMSS2D_Shape_Open:
		return false
	return not shape.are_points_clockwise() and shape.get_point_count() >= 3

func _action_invert_orientation()->bool:
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
		undo.add_undo_method(shape,"invert_point_order")

		undo.add_do_method(current_action, "invert", shape.get_point_count())
		undo.add_undo_method(current_action, "invert", shape.get_point_count())
		undo.commit_action()
		undo_version = undo.get_version()
		return true
	return false



func deselect_control_points():
	current_action = ActionData.new([], [], [], [], ACTION.NONE)

func select_verticies(indices:Array, action:int)->ActionData:
	var from_positions = []
	var from_positions_c_in = []
	var from_positions_c_out = []
	for idx in indices:
		from_positions.push_back(shape.get_point_position(idx))
		from_positions_c_in.push_back(shape.get_point_in(idx))
		from_positions_c_out.push_back(shape.get_point_out(idx))
	return ActionData.new(indices, from_positions, from_positions_c_in, from_positions_c_out, action)

func select_vertices_to_move(indices:Array, _mouse_starting_pos_viewport:Vector2):
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport
	current_action = select_verticies(indices, ACTION.MOVING_VERT)


func select_control_points_to_move(indices:Array, _mouse_starting_pos_viewport:Vector2, action=ACTION.MOVING_CONTROL):
	current_action = select_verticies(indices, action)
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport



#############
# RENDERING #
#############
func forward_canvas_draw_over_viewport(overlay:Control):
	# Something might force a draw which we had no control over,
	# in this case do some updating to be sure
	if undo_version != undo.get_version():
		if undo.get_current_action_name() == "Move CanvasItem" or undo.get_current_action_name() == "Rotate CanvasItem" or undo.get_current_action_name() == "Scale CanvasItem":
			shape.set_as_dirty()
			undo_version = undo.get_version()

	if shape != null:
		var t:Transform2D = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform * shape.get_global_transform()
		var baked = shape.get_vertices()
		var points = shape.get_tessellated_points()
		var length = points.size()

		# Draw Outline
		var fpt = null
		var ppt = null
		for i in length:
			var pt = points[i]
			if ppt != null:
				overlay.draw_line(ppt, t.xform(pt), shape.modulate)
			ppt = t.xform( pt )
			if fpt == null:
				fpt = ppt

		# Draw handles
		for i in range(0, baked.size(), 1):
			#print ("%s:%s" % [str(i), str(baked.size())])
			#print ("%s:%s | %s | %s" % [str(i), str(shape.get_point_position(i)), str(shape.get_point_in(i)), str(shape.get_point_out(i))])
			var smooth = false
			var hp = t.xform(baked[i])
			overlay.draw_texture(ICON_HANDLE, hp - ICON_HANDLE.get_size() * 0.5)

			# Draw handles for control-point-out
			# Drawing the point-out for the last point makes no sense, as there's no point ahead of it
			if i < baked.size() - 1:
				var pointout = t.xform(baked[i] + shape.get_point_out(i));
				if hp != pointout:
					smooth = true;
					_draw_control_point_line(overlay, hp, pointout, ICON_HANDLE_CONTROL)

			# Draw handles for control-point-in
			# Drawing the point-in for point 0 makes no sense, as there's no point behind it
			if i > 0:
				var pointin = t.xform(baked[i] + shape.get_point_in(i));
				if hp != pointin:
					smooth = true;
					_draw_control_point_line(overlay, hp, pointin, ICON_HANDLE_CONTROL)

		if on_edge:
			overlay.draw_texture(ICON_ADD_HANDLE, edge_point - ICON_ADD_HANDLE.get_size() * 0.5)

		# Draw Highlighted Handle
		if is_single_point_index_valid():
			overlay.draw_circle(t.xform( baked[current_point_index()] ), 5, Color.white )
			overlay.draw_circle(t.xform( baked[current_point_index()] ), 3, Color.black)

		shape.update()

func _draw_control_point_line(overlay:Control, point:Vector2, control_point:Vector2, texture:Texture=ICON_HANDLE):
	# Draw the line with a dark and light color to be visible on all backgrounds
	var color_dark = Color(0, 0, 0, 0.5)
	var color_light = Color(1, 1, 1, 0.5)
	var width = 1.0
	overlay.draw_line(point, control_point, color_dark, width)
	overlay.draw_line(point, control_point, color_light, width)
	#overlay.draw_texture_rect(curve_handle, Rect2(pointout - curve_handle_size * 0.5, curve_handle_size), false, Color(1, 1, 1, 0.75));
	overlay.draw_texture(texture, control_point - texture.get_size() * 0.5)

func _get_intersecting_control_point_in(mouse_pos:Vector2, grab_threshold:float)->Array:
	var points = []
	var xform:Transform2D = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform * shape.get_global_transform()
	for i in range(0, shape.get_point_count(), 1):
		var vec = shape.get_point_position(i)
		var c_in = vec + shape.get_point_in(i)
		c_in = xform.xform(c_in)
		if c_in.distance_to(mouse_pos) <= grab_threshold:
			points.push_back(i)

	return points

func _get_intersecting_control_point_out(mouse_pos:Vector2, grab_threshold:float)->Array:
	var points = []
	var xform:Transform2D = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform * shape.get_global_transform()
	for i in range(0, shape.get_point_count(), 1):
		var vec = shape.get_point_position(i)
		var c_out = vec + shape.get_point_out(i)
		c_out = xform.xform(c_out)
		if c_out.distance_to(mouse_pos) <= grab_threshold:
			points.push_back(i)

	return points

func _on_shape_point_modified():
	_action_invert_orientation()

func _input_handle_keyboard_event(event:InputEventKey)->bool:
	var kb:InputEventKey = event
	if _is_valid_keyboard_scancode(kb):
		if is_single_point_index_valid():
			if kb.pressed and kb.scancode == KEY_SPACE:
				shape.set_point_texture_flip(!shape.get_point_texture_flip(current_point_index()), current_point_index())
				shape.set_as_dirty()
				shape.update()
				update_gui_info_panel()
		return true
	return false

func _input_handle_mouse_button_event(event:InputEventMouseButton, et:Transform2D, grab_threshold:float)->bool:
	var rslt:bool = false
	var t:Transform2D = et * shape.get_global_transform()
	var mb:InputEventMouseButton = event
	var viewport_mouse_position = et.affine_inverse().xform(mb.position)

	#######################################
	# Mouse Button released
	if not mb.pressed and mb.button_index == BUTTON_LEFT:
		if current_action.type == ACTION.MOVING_VERT:
			if current_action.starting_positions[0].distance_to(shape.get_point_position(current_action.indices[0])) > grab_threshold:
				_action_move_verticies()
				rslt = true
		var type = current_action.type
		var _in = type == ACTION.MOVING_CONTROL or type == ACTION.MOVING_CONTROL_IN
		var _out = type == ACTION.MOVING_CONTROL or type == ACTION.MOVING_CONTROL_OUT
		if _in or _out:
			_action_move_control_points(_in, _out)
			rslt = true
		deselect_control_points()
		return rslt


	#########################################
	# Mouse Right click in Edit Mode -OR- LEFT Click on Delete Mode
	elif mb.pressed and ((mb.button_index == BUTTON_RIGHT and current_mode == MODE.EDIT) or (current_mode == MODE.DELETE and mb.button_index == BUTTON_LEFT)):
		if is_single_point_index_valid():
			_action_delete_point()
			deselect_control_points()
			rslt = true
		else:
			var points_in = _get_intersecting_control_point_in(mb.position, grab_threshold)
			var points_out = _get_intersecting_control_point_out(mb.position, grab_threshold)
			if not points_in.empty():
				_action_delete_point_in(points_in[0])
				rslt = true
			elif not points_out.empty():
				_action_delete_point_out(points_out[0])
				rslt = true
		return rslt

	#########################################
	# Mouse Wheel up on valid point
	elif mb.pressed and mb.button_index == BUTTON_WHEEL_UP and is_single_point_index_valid():
		if Input.is_key_pressed(KEY_SHIFT):
			var width = shape.get_point_width(current_point_index())
			var new_width = width + 0.1
			shape.set_point_width(new_width, current_point_index())

			shape.set_as_dirty()
			update_overlays()
			update_gui_info_panel()
			
			rslt = true
		else:
			var index:int = shape.get_point_texture_index(current_point_index()) + 1
			var flip:bool = shape.get_point_texture_flip(current_point_index())
			shape.set_point_texture_index(current_point_index(), index)
			shape.set_point_texture_flip(flip, current_point_index())

			shape.set_as_dirty()
			update_overlays()
			update_gui_info_panel()
			
			rslt = true
		return rslt

	#########################################
	# Mouse Wheel down on valid point
	elif mb.pressed and mb.button_index == BUTTON_WHEEL_DOWN and is_single_point_index_valid():
		if Input.is_key_pressed(KEY_SHIFT):
			var width = shape.get_point_width(current_point_index())
			var new_width = width - 0.1
			shape.set_point_width(new_width, current_point_index())

			shape.set_as_dirty()
			update_overlays()
			update_gui_info_panel()
			
			rslt = true
		else:
			var index = shape.get_point_texture_index(current_point_index()) - 1
			shape.set_point_texture_index(current_point_index(), index)

			shape.set_as_dirty()
			update_overlays()
			update_gui_info_panel()
			
			rslt = true
		return rslt

	#########################################
	# Mouse left click on valid point
	elif mb.pressed and mb.button_index == BUTTON_LEFT and is_single_point_index_valid():
		if Input.is_key_pressed(KEY_SHIFT) and current_mode == MODE.EDIT:
			select_control_points_to_move([current_point_index()], viewport_mouse_position)
			return true
		# If you create a point at the same location as point idx "0"
		elif current_mode == MODE.CREATE and current_point_index() == 0:
			return false
		else:
			select_vertices_to_move([current_point_index()], viewport_mouse_position)
			return true


	#########################################
	# Mouse Left click
	elif mb.pressed and mb.button_index == BUTTON_LEFT:
		#First, check if we are changing our pivot point
		if (current_mode == MODE.SET_PIVOT) or (current_mode == MODE.EDIT and mb.control):
			_action_set_pivot(mb.position, et)
			return true

		elif current_mode == MODE.EDIT and not on_edge:
			var points_in = _get_intersecting_control_point_in(mb.position, grab_threshold)
			var points_out = _get_intersecting_control_point_out(mb.position, grab_threshold)
			if not points_in.empty():
				select_control_points_to_move([points_in[0]], viewport_mouse_position, ACTION.MOVING_CONTROL_IN)
				return true
			elif not points_out.empty():
				select_control_points_to_move([points_out[0]], viewport_mouse_position, ACTION.MOVING_CONTROL_OUT)
				return true

		elif current_mode == MODE.CREATE and not on_edge:
			var snapped_pos = _snap_position(t.affine_inverse().xform(mb.position), get_snap_offset(), get_snap_step())
			select_vertices_to_move([_action_add_point(snapped_pos)], viewport_mouse_position)

			return true

		elif (current_mode == MODE.CREATE or current_mode == MODE.EDIT) and on_edge:
			# Grab Edge (2 points)
			if Input.is_key_pressed(KEY_SHIFT) and current_mode == MODE.EDIT:
				var xform:Transform2D = t
				var gpoint:Vector2 = mb.position
				var insertion_point:int = -1
				var mb_length = shape.get_closest_offset(xform.affine_inverse().xform(gpoint))
				var length = shape.get_point_count()

				for i in length - 1:
					var compareLength = shape.get_closest_offset(shape.get_point_position(i + 1))
					if mb_length >= shape.get_closest_offset(shape.get_point_position(i)) and mb_length <= compareLength:
						insertion_point = i

				if insertion_point == -1:
					insertion_point = shape.get_point_count() - 2

				select_vertices_to_move([insertion_point, insertion_point+1], viewport_mouse_position)
				return true

			else:
				var xform:Transform2D = t
				var gpoint:Vector2 = mb.position
				var insertion_point:int = -1
				var mb_length = shape.get_closest_offset(xform.affine_inverse().xform(gpoint))
				var length = shape.get_point_count()

				for i in length - 1:
					var compareLength = shape.get_closest_offset(shape.get_point_position(i + 1))
					if mb_length >= shape.get_closest_offset(shape.get_point_position(i)) and mb_length <= compareLength:
						insertion_point = i

				if insertion_point == -1:
					insertion_point = shape.get_point_count() - 2
				var idx = insertion_point+1

				idx = _action_split_curve(idx, gpoint, xform)
				select_vertices_to_move([idx], viewport_mouse_position)
				on_edge = false

				return true

	return false

func _input_handle_mouse_motion_event(event:InputEventMouseMotion, et:Transform2D, grab_threshold:float)->bool:
	var t:Transform2D = et * shape.get_global_transform()
	var mm:InputEventMouseMotion = event
	var delta_current_pos = et.affine_inverse().xform(mm.position)
	#print(mm.position)
	gui_info_panel.rect_position = mm.position + Vector2(256,-24)
	var delta = delta_current_pos - _mouse_motion_delta_starting_pos
	var rslt:bool = false

	var type = current_action.type
	var _in = type == ACTION.MOVING_CONTROL or type == ACTION.MOVING_CONTROL_IN
	var _out = type == ACTION.MOVING_CONTROL or type == ACTION.MOVING_CONTROL_OUT

	#_debug_mouse_positions(mm, et)

	if type == ACTION.MOVING_VERT:
		for i in range(0, current_action.indices.size(), 1):
			var idx = current_action.indices[i]
			var from = current_action.starting_positions[i]
			var new_position = from + delta
			var snapped_position = _snap_position(new_position, get_snap_offset(), get_snap_step())
			shape.set_point_position(idx, snapped_position)
			rslt = true
			update_overlays()
		return rslt

	elif _in or _out:
		for i in range(0, current_action.indices.size(), 1):
			var idx = current_action.indices[i]
			var from = current_action.starting_positions[i]
			var out_multiplier = 1
			# Invert the delta for position_out if moving both at once
			if type == ACTION.MOVING_CONTROL:
				out_multiplier = -1
			var new_position_in = delta + current_action.starting_positions_control_in[i]
			var new_position_out = (delta * out_multiplier) + current_action.starting_positions_control_out[i]
			#var snapped_position = _snap_position(t.affine_inverse().xform(mm.position), get_snap_offset(), get_snap_step())
			var snapped_position_in = _snap_position(new_position_in, get_snap_offset(), get_snap_step())
			var snapped_position_out = _snap_position(new_position_out, get_snap_offset(), get_snap_step())
			if _in:
				shape.set_point_in(idx, snapped_position_in)
				rslt = true
			if _out:
				shape.set_point_out(idx, snapped_position_out)
				rslt = true
			shape.set_as_dirty()
			update_overlays()
		return rslt


	# Handle Edge Follow
	var old_edge:bool = on_edge

	var xform:Transform2D = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform * shape.get_global_transform()
	var gpoint:Vector2 = mm.position

	if shape.get_point_count() < 2:
		return rslt

	# Find edge
	var closest_point = shape.get_closest_point(xform.affine_inverse().xform(mm.position))
	if closest_point != null:
		edge_point = xform.xform(closest_point)
		on_edge = false
		if edge_point.distance_to(gpoint) <= grab_threshold:
			on_edge = true

		# However, if near a control point or one of its handles then we are not on the edge
		deselect_control_points()
		for i in shape.get_point_count():
			var pp:Vector2 = shape.get_point_position(i)
			var p:Vector2 = xform.xform(pp)
			if p.distance_to(gpoint) <= grab_threshold:
				on_edge = false
				current_action = select_verticies([i], ACTION.NONE)
				break

		if current_mode != MODE.CREATE and current_mode != MODE.EDIT:
			# Ensure we are not on the edge if not in the proper mode
			on_edge = false

		if on_edge or old_edge != on_edge:
			update_overlays()

	return rslt
