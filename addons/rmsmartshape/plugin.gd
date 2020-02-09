tool
extends EditorPlugin

enum MODE {
	EDIT
	CREATE
	DELETE
	SET_PIVOT
}

enum ACTION {
	NONE = 0
	MOVING = 1
}

# The Plugin's Featured Component
const ShapeClass = preload("RMSmartShape2D.gd")

# Icons
const HANDLE = preload("assets/icon_editor_handle.svg")
const ADD_HANDLE = preload("assets/icon_editor_handle_add.svg")
const CURVE_EDIT = preload("assets/icon_curve_edit.svg")
const CURVE_CREATE = preload("assets/icon_curve_create.svg")
const CURVE_DELETE = preload("assets/icon_curve_delete.svg")
const PIVOT_POINT = preload("assets/icon_editor_position.svg")
const COLLISION = preload("assets/icon_collision_polygon_2d.svg")

# Should be obvious that this is the node being edited
var edit_this:ShapeClass = null

# Toolbar Stuff
var hb:HBoxContainer = null
var tb_edit:ToolButton = null
var tb_create:ToolButton = null
var tb_delete:ToolButton = null
var tb_pivot:ToolButton = null
var tb_snap_x:SpinBox = null
var tb_snap_y:SpinBox = null
var tb_snap_offset_x:SpinBox = null
var tb_snap_offset_y:SpinBox = null
var tb_collision:ToolButton = null
var lbl_index:Label = null

# Edge Stuff
var on_edge:bool = false
var edge_point:Vector2

# Control Point Stuff
var control_point_action:int = ACTION.NONE
# Array of control points that are being affected by the control_point_action
var control_points_selected:Array = []
# Array of Vector2s, one for each control point that is being moved
var from_positions:Array = []

# Monitor change to node being edited
var edit_this_transform:Transform2D
var edit_this_collision_offset:float
var edit_this_collision_width:float
var edit_this_collision_extends:float
var edit_this_top_offset:float			# This also has an impact on open shaped collision

# Track our mode of operation
var current_mode:int = MODE.EDIT
var previous_mode:int = MODE.EDIT

# Undo stuff
var undo:UndoRedo = null
var undo_version:int = 0

# Snapping
var _snapping = Vector2(1,1)
var _snapping_offset = Vector2(0,0)

# Action Move Variables
var _mouse_motion_delta_starting_pos = Vector2(0,0)

func _ready():
	_init_undo()
	_build_toolbar()

func _init_undo():
	#Support the undo-redo actions
	undo = get_undo_redo()

func _build_toolbar():
	#Build up tool bar when editing RMSmartShape2D
	hb = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, hb)

	var sep = VSeparator.new()
	hb.add_child(sep)

	tb_snap_x = SpinBox.new()
	tb_snap_x.value = 1.0
	tb_snap_x.editable = true
	tb_snap_x.connect("value_changed", self, "_snap_changed")
	tb_snap_x.hint_tooltip = "Snap X"
	hb.add_child(tb_snap_x)

	tb_snap_y = SpinBox.new()
	tb_snap_y.value = 1.0
	tb_snap_y.editable = true
	tb_snap_y.connect("value_changed", self, "_snap_changed")
	tb_snap_y.hint_tooltip = "Snap Y"
	hb.add_child(tb_snap_y)

	tb_snap_offset_x = SpinBox.new()
	tb_snap_offset_x.editable = true
	tb_snap_offset_x.connect("value_changed", self, "_snap_offset_changed")
	tb_snap_offset_x.hint_tooltip = "Snap Offset X"
	hb.add_child(tb_snap_offset_x)

	tb_snap_offset_y = SpinBox.new()
	tb_snap_offset_y.editable = true
	tb_snap_offset_y.connect("value_changed", self, "_snap_offset_changed")
	tb_snap_offset_y.hint_tooltip = "Snap Offset Y"
	hb.add_child(tb_snap_offset_y)

	tb_edit = ToolButton.new()
	tb_edit.icon = CURVE_EDIT
	tb_edit.toggle_mode = true
	tb_edit.pressed = true
	tb_edit.connect("pressed", self, "_enter_mode", [MODE.EDIT])
	tb_edit.hint_tooltip = "Control+LMB: Set Pivot Point\nLMB+Drag: Move Point\nLMB: Click on curve to split\nRMB: Delete Point"
	hb.add_child(tb_edit)

	tb_create = ToolButton.new()
	tb_create.icon = CURVE_CREATE
	tb_create.toggle_mode = true
	tb_create.pressed = false
	tb_create.connect("pressed", self, "_enter_mode", [MODE.CREATE])
	tb_create.hint_tooltip = "LMB: Add Point, Split in Curve or Close Shape\nLMB+Drag: Move Point"
	hb.add_child(tb_create)

	tb_delete = ToolButton.new()
	tb_delete.icon = CURVE_DELETE
	tb_delete.toggle_mode = true
	tb_delete.pressed = false
	tb_delete.connect("pressed", self, "_enter_mode", [MODE.DELETE])
	tb_delete.hint_tooltip = "LMB: Delete Point\nLMB+Drag: Move Point"
	hb.add_child(tb_delete)

	tb_pivot = ToolButton.new()
	tb_pivot.icon = PIVOT_POINT
	tb_pivot.toggle_mode = true
	tb_pivot.pressed = false
	tb_pivot.connect("pressed", self, "_enter_mode", [MODE.SET_PIVOT])
	hb.add_child(tb_pivot)

	tb_collision = ToolButton.new()
	tb_collision.icon = COLLISION
	tb_collision.toggle_mode = false
	tb_collision.pressed = false
	tb_collision.hint_tooltip = "Add static body parent and collision polygon sibling\nUse this to auto generate collision."
	tb_collision.connect("pressed", self, "_add_collision")
	hb.add_child(tb_collision)

	lbl_index = Label.new()
	lbl_index.text = "Idx: "
	hb.hide()
	hb.add_child(lbl_index)

func _enter_tree():
	pass
	
func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, hb)

func _process(delta):
	if Engine.editor_hint:
		if edit_this != null:
			if is_instance_valid(edit_this) == false:
				edit_this = null
				update_overlays()
				return
			if edit_this.is_inside_tree() == false:
				edit_this = null
				update_overlays()
				return

			if edit_this_transform != edit_this.get_global_transform():
				edit_this.bake_mesh(true)  # Force the bake so that directional changes can be made
				edit_this.update()
				edit_this_transform = edit_this.get_global_transform()

func handles(object):
	if object is Resource:
		return false
		
	var rslt:bool = object is ShapeClass
	hb.hide()
	
	update_overlays()

	return rslt
	
func edit(object):
	if hb != null:
		hb.show()

	on_edge = false
	control_point_action = ACTION.NONE
	#current_point_index = -1
	deselect_control_points()
	edit_this = object as RMSmartShape2D
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
	var ct:Transform2D = edit_this.get_global_transform()
	ct.origin = np

	for i in edit_this.get_point_count():
		var pt = edit_this.get_global_transform().xform(edit_this.get_point_position(i))
		edit_this.set_point_position(i, ct.affine_inverse().xform(pt))

	edit_this.position = edit_this.get_parent().get_global_transform().affine_inverse().xform( np)
	current_mode = previous_mode
	_enter_mode(current_mode)
	update_overlays()

func make_visible(visible):
	pass

func _snap_position(pos:Vector2, snap:Vector2):
	var x = pos.x
	if snap.x != 0:
		x = pos.x - fmod(pos.x, snap.x)
	var y = pos.y
	if snap.y != 0:
		y = pos.y - fmod(pos.y, snap.y)
	return Vector2(x,y)

func _get_toolbar_status_message(idx:int)->String:
	if not is_point_index_valid(idx):
		return "Idx: None"
	return "Idx:%d T:%s F:%s W:%s" % \
		[
		idx,
		edit_this.texture_indices[idx],
		edit_this.texture_flip_indices[idx],
		edit_this.width_indices[idx]
		]

func is_single_point_index_valid()->bool:
	if control_points_selected.size() == 1:
		return is_point_index_valid(control_points_selected[0])
	return false

func is_edit_this_valid()->bool:
	if edit_this == null:
		return false
	if not is_instance_valid(edit_this):
		return false
	return true

func are_point_indices_valid(indicies:Array)->bool:
	for idx in indicies:
		if not is_point_index_valid(idx):
			return false
	return true

func is_point_index_valid(idx:int)->bool:
	if not is_edit_this_valid():
		return false
	return (idx >= 0 and idx < edit_this.texture_indices.size())

func current_point_index()->int:
	if not is_single_point_index_valid():
		return -1
	return control_points_selected[0]

func _input_handle_keyboard_event(event:InputEventKey)->bool:
	var kb:InputEventKey = event
	if kb.scancode == KEY_SPACE and is_single_point_index_valid():
		if kb.pressed:
			edit_this.set_point_texture_flip(!edit_this.get_point_texture_flip(current_point_index()), current_point_index())
			edit_this.bake_mesh()
			edit_this.update()
		return true
	return false

func _input_handle_mouse_button_event(event:InputEventMouseButton, et:Transform2D, grab_threshold:float)->bool:
	var t:Transform2D = et * edit_this.get_global_transform()
	var mb:InputEventMouseButton = event
	var viewport_mouse_position = et.affine_inverse().xform(mb.position)

###############################################################################################
	# Mouse Button released While Moving Point
	if not mb.pressed and mb.button_index == BUTTON_LEFT and control_point_action == ACTION.MOVING:
		control_point_action = ACTION.NONE
		if from_positions[0].distance_to(edit_this.get_point_position(control_points_selected[0])) > grab_threshold:
			_action_move_control_points()
			deselect_control_points()
			return true
		else:
			deselect_control_points()
			return false

###############################################################################################
	# Mouse Wheel up on valid point
	elif mb.pressed and mb.button_index == BUTTON_WHEEL_UP and is_single_point_index_valid():
		var index:int = edit_this.get_point_texture_index(current_point_index()) + 1
		var flip:bool = edit_this.get_point_texture_flip(current_point_index())
		edit_this.set_point_texture_index(index, current_point_index())
		edit_this.set_point_texture_flip(flip, current_point_index())

		edit_this.bake_mesh()
		update_overlays()
		return true

###############################################################################################
	# Mouse Wheel down on valid point
	elif mb.pressed and mb.button_index == BUTTON_WHEEL_DOWN and is_single_point_index_valid():
		var index = edit_this.get_point_texture_index(current_point_index()) - 1
		edit_this.set_point_texture_index(index, current_point_index())

		if Input.is_key_pressed(KEY_ALT):
			edit_this.set_point_texture_flip(true, current_point_index())
		else:
			edit_this.set_point_texture_flip(false, current_point_index())

		edit_this.bake_mesh()
		update_overlays()
		return true

###############################################################################################
	# Mouse left click on valid point
	elif mb.pressed and mb.button_index == BUTTON_LEFT and is_single_point_index_valid():
		# If you create a point at the same location as point idx "0"
		if current_mode == MODE.CREATE and not edit_this.closed_shape and current_point_index() == 0:
			_action_close_shape()
			select_control_points_to_move([0], viewport_mouse_position)
			return true
		else:
			select_control_points_to_move([current_point_index()], viewport_mouse_position)
			return true

###############################################################################################
	# Mouse Right click in Edit Mode -OR- LEFT Click on Delete Mode
	elif mb.pressed and ((mb.button_index == BUTTON_RIGHT and current_mode == MODE.EDIT) or (current_mode == MODE.DELETE and mb.button_index == BUTTON_LEFT)) and is_single_point_index_valid():
		var fix_close_shape = false
		undo.create_action("Delete Point")
		if edit_this.closed_shape and (current_point_index() == edit_this.get_point_count() - 1 or current_point_index() == 0):
			var pt = edit_this.get_point_position(0)
			undo.add_do_method(edit_this, "remove_point", edit_this.get_point_count() - 1)
			undo.add_do_method(edit_this, "remove_point", 0)
			undo.add_undo_method(edit_this, "add_point_to_curve", pt, 0)
			undo.add_undo_method(edit_this,"set_point_position", edit_this.get_point_count() - 1, pt)
			fix_close_shape = true

		else:
			var pt:Vector2 = edit_this.get_point_position(current_point_index())
			undo.add_do_method(edit_this, "remove_point", current_point_index())
			undo.add_undo_method(edit_this, "add_point_to_curve", pt, current_point_index())

		undo.add_do_method(self, "update_overlays")
		undo.add_undo_method(self, "update_overlays")
		undo.add_do_method(edit_this, "bake_mesh")
		undo.add_undo_method(edit_this, "bake_mesh")
		undo.commit_action()
		undo_version = undo.get_version()

		deselect_control_points()
		if fix_close_shape:
			edit_this.fix_close_shape()

		return true

###############################################################################################
	# Mouse Left click
	elif mb.pressed and mb.button_index == BUTTON_LEFT:
		#First, check if we are changing our pivot point
		if (current_mode == MODE.SET_PIVOT) or (current_mode == MODE.EDIT and mb.control):
			_action_set_pivot(mb.position, et)

		elif current_mode == MODE.CREATE and not on_edge:
			if (edit_this.closed_shape and edit_this.get_point_count() < 3) or not edit_this.closed_shape:
				var snapped_position = _snap_position(t.affine_inverse().xform(mb.position), _snapping) + _snapping_offset
				var np = snapped_position

				undo.create_action("Add Point")
				undo.add_do_method(edit_this, "add_point_to_curve", np)
				undo.add_undo_method(edit_this,"remove_point", edit_this.get_point_count())
				undo.add_do_method(edit_this, "bake_mesh")
				undo.add_undo_method(edit_this, "bake_mesh")
				undo.add_do_method(self, "update_overlays")
				undo.add_undo_method(self, "update_overlays")
				undo.commit_action()
				undo_version = undo.get_version()

				select_control_points_to_move([edit_this.get_point_count() - 1], viewport_mouse_position)
				return true

		elif (current_mode == MODE.CREATE or current_mode == MODE.EDIT) and on_edge:
			if Input.is_key_pressed(KEY_SHIFT) and current_mode == MODE.EDIT:
				var xform:Transform2D = t
				var gpoint:Vector2 = mb.position
				var insertion_point:int = -1
				var mb_length = edit_this.get_closest_offset(xform.affine_inverse().xform(gpoint))
				var length = edit_this.get_point_count()

				for i in length - 1:
					var compareLength = edit_this.get_closest_offset(edit_this.get_point_position(i + 1))
					if mb_length >= edit_this.get_closest_offset(edit_this.get_point_position(i)) and mb_length <= compareLength:
						insertion_point = i

				if insertion_point == -1:
					insertion_point = edit_this.get_point_count() - 2

				select_control_points_to_move([insertion_point, insertion_point+1], viewport_mouse_position)

			else:
				var xform:Transform2D = t
				var gpoint:Vector2 = mb.position
				var insertion_point:int = -1
				var mb_length = edit_this.get_closest_offset(xform.affine_inverse().xform(gpoint))
				var length = edit_this.get_point_count()

				for i in length - 1:
					var compareLength = edit_this.get_closest_offset(edit_this.get_point_position(i + 1))
					if mb_length >= edit_this.get_closest_offset(edit_this.get_point_position(i)) and mb_length <= compareLength:
						insertion_point = i

				if insertion_point == -1:
					insertion_point = edit_this.get_point_count() - 2

				undo.create_action("Split Curve")
				undo.add_do_method(edit_this, "add_point_to_curve", xform.affine_inverse().xform(gpoint), insertion_point + 1)
				undo.add_undo_method(edit_this, "remove_point", insertion_point + 1)
				undo.add_do_method(edit_this, "bake_mesh")
				undo.add_undo_method(edit_this, "bake_mesh")
				undo.add_do_method(self, "update_overlays")
				undo.add_undo_method(self, "update_overlays")
				undo.commit_action()
				undo_version = undo.get_version()

				on_edge = false

				select_control_points_to_move([insertion_point+1], viewport_mouse_position)
		return true
	return false

func _debug_mouse_positions(mm, t):
	#print("========================================")
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

func _input_handle_mouse_motion_event(event:InputEventMouseMotion, et:Transform2D, grab_threshold:float)->bool:
	var t:Transform2D = et * edit_this.get_global_transform()
	var mm:InputEventMouseMotion = event
	var delta_current_pos = et.affine_inverse().xform(mm.position)
	var delta = delta_current_pos - _mouse_motion_delta_starting_pos

	#_debug_mouse_positions(mm, et)

	if control_point_action == ACTION.MOVING:
		for i in range(0, control_points_selected.size(), 1):
			var idx = control_points_selected[i]
			var from = from_positions[i]
			var new_position = from + delta
			#var snapped_position = _snap_position(t.affine_inverse().xform(mm.position), _snapping) + _snapping_offset
			var snapped_position = _snap_position(new_position, _snapping) + _snapping_offset
			# Appears we are moving a point
			if edit_this.closed_shape and (idx == edit_this.get_point_count() - 1 or idx == 0):
				edit_this.set_point_position(edit_this.get_point_count() - 1, snapped_position)
				edit_this.set_point_position(0, snapped_position)
			else:
				edit_this.set_point_position(idx, snapped_position)
			edit_this.bake_mesh()
			update_overlays()
		return true


	# Handle Edge Follow
	var old_edge:bool = on_edge

	var xform:Transform2D = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform * edit_this.get_global_transform()
	var gpoint:Vector2 = mm.position

	if edit_this.get_point_count() < 2:
		return true

	# Find edge
	edge_point = xform.xform(edit_this.get_closest_point(xform.affine_inverse().xform(mm.position)))
	on_edge = false
	if edge_point.distance_to(gpoint) <= grab_threshold:
		on_edge = true

	# However, if near a control point or one of its handles then we are not on the edge
	deselect_control_points()
	for i in edit_this.get_point_count():
		var pp:Vector2 = edit_this.get_point_position(i)
		var p:Vector2 = xform.xform(pp)
		if p.distance_to(gpoint) <= grab_threshold:
			on_edge = false
			select_control_points([i])
			break

	if current_mode != MODE.CREATE and current_mode != MODE.EDIT:
		on_edge = false #Ensure we are not on the edge if not in the proper mode

	if on_edge or old_edge != on_edge:
		update_overlays()

	return false

func forward_canvas_gui_input(event):
	if edit_this == null:
		return false

	if not is_instance_valid(edit_this):
		return false

	var et = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
	var grab_threshold = get_editor_interface().get_editor_settings().get("editors/poly_editor/point_grab_radius")
	lbl_index.text = _get_toolbar_status_message(current_point_index())

	if event is InputEventKey:
		return _input_handle_keyboard_event(event)

	elif event is InputEventMouseButton:
		return _input_handle_mouse_button_event(event, et, grab_threshold)

	elif event is InputEventMouseMotion:
		return _input_handle_mouse_motion_event(event, et, grab_threshold)

	return false


func _curve_changed():
	control_point_action = ACTION.NONE
	deselect_control_points()
	update_overlays()

func _add_collision():
	call_deferred("_add_deferred_collision")

func _add_deferred_collision():
	if (edit_this.get_parent() is StaticBody2D) == false:
		var staticBody:StaticBody2D = StaticBody2D.new()
		var t:Transform2D = edit_this.transform
		staticBody.position = edit_this.position
		edit_this.position = Vector2.ZERO

		edit_this.get_parent().add_child(staticBody)
		staticBody.owner = get_editor_interface().get_edited_scene_root()

		edit_this.get_parent().remove_child(edit_this)
		staticBody.add_child(edit_this)
		edit_this.owner = get_editor_interface().get_edited_scene_root()

		var colPolygon:CollisionPolygon2D = CollisionPolygon2D.new()
		staticBody.add_child(colPolygon)
		colPolygon.owner = get_editor_interface().get_edited_scene_root()
		colPolygon.modulate.a = 0.3 #TODO: Make this a option at some point
		colPolygon.visible = false

		edit_this.collision_polygon_node = edit_this.get_path_to(colPolygon)

		edit_this.bake_collision()

func _handle_auto_collision_press():
	pass

func forward_canvas_draw_over_viewport(overlay):
	# Something might force a draw which we had no control over,
	# in this case do some updating to be sure
	if undo_version != undo.get_version():
		if undo.get_current_action_name() == "Move CanvasItem" or undo.get_current_action_name() == "Rotate CanvasItem" or undo.get_current_action_name() == "Scale CanvasItem":
			edit_this.bake_collision()
			undo_version = undo.get_version()
	
	if edit_this != null:
		var t:Transform2D = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform * edit_this.get_global_transform()
		
		# Draw Outline
		var fpt = null
		var ppt = null
		for i in edit_this.get_point_count():
			var pt = edit_this.get_point_position(i)
			if ppt != null:
				overlay.draw_line(ppt, t.xform(pt), edit_this.modulate)
			ppt = t.xform( pt )
			if fpt == null:
				fpt = ppt
		
		# Draw handles
		for i in edit_this.get_point_count():
			var hp = t.xform(edit_this.get_point_position(i))
			overlay.draw_texture(HANDLE, hp - HANDLE.get_size() * 0.5)
		
		if on_edge:
			overlay.draw_texture(ADD_HANDLE, edge_point - ADD_HANDLE.get_size() * 0.5)
			
		# Draw Highlighted Handle
		if is_single_point_index_valid():
			overlay.draw_circle(t.xform( edit_this.get_point_position(current_point_index()) ), 5, Color.white )
			overlay.draw_circle(t.xform( edit_this.get_point_position(current_point_index()) ), 3, Color.black)
		
		edit_this.update()

func _snap_changed(ignore_value):
	_snapping = Vector2(tb_snap_x.value, tb_snap_y.value)
func _snap_offset_changed(ignore_value):
	_snapping_offset = Vector2(tb_snap_offset_x.value, tb_snap_offset_y.value)

###########
# ACTIONS #
###########
func _action_set_pivot(pos:Vector2, et:Transform2D):
	var old_pos = et.xform( edit_this.get_parent().get_global_transform().xform(edit_this.position))
	undo.create_action("Set Pivot")
	var snapped_position = _snap_position(et.affine_inverse().xform(pos), _snapping) + _snapping_offset
	undo.add_do_method(self, "_set_pivot", snapped_position)
	undo.add_undo_method(self, "_set_pivot", et.affine_inverse().xform(old_pos))
	undo.add_do_method(edit_this, "bake_mesh")
	undo.add_undo_method(edit_this, "bake_mesh")
	undo.add_do_method(self, "update_overlays")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()

func _action_move_control_points():
	undo.create_action("Move Control Point")

	undo.add_do_method(edit_this, "bake_mesh")
	undo.add_do_method(self, "update_overlays")

	for i in range(0, control_points_selected.size(), 1):
		var idx = control_points_selected[i]
		var from_position = from_positions[i]
		if (idx == 0 or idx == edit_this.get_point_count() - 1) and edit_this.closed_shape:
			undo.add_undo_method(edit_this, "set_point_position", 0, from_position)
			undo.add_undo_method(edit_this, "set_point_position", edit_this.get_point_count() - 1, from_position)
		else:
			undo.add_undo_method(edit_this, "set_point_position", idx, from_position)

	undo.add_undo_method(edit_this, "bake_mesh")
	undo.add_undo_method(self, "update_overlays")
	undo.commit_action()
	undo_version = undo.get_version()

func _action_close_shape():
	undo.create_action("Close Shape")
	undo.add_do_property(edit_this, "closed_shape", true)
	undo.add_do_method(edit_this, "property_list_changed_notify")
	undo.add_undo_property(edit_this, "closed_shape", false)
	undo.add_undo_method(edit_this, "property_list_changed_notify")
	undo.commit_action()
	undo_version = undo.get_version()

func deselect_control_points():
	control_points_selected = []
	from_positions = []

func select_control_points(indices:Array, action:int=-1):
	control_points_selected = indices
	for idx in indices:
		from_positions.push_back(edit_this.get_point_position(idx))
	if action != -1:
		control_point_action = action

func select_control_points_to_move(indices:Array, _mouse_starting_pos_viewport:Vector2):
	select_control_points(indices, ACTION.MOVING)
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport
