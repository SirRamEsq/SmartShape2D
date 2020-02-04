tool
extends EditorPlugin

enum MODE {
	MODE_EDIT
	MODE_CREATE
	MODE_DELETE
	MODE_SET_PIVOT
}

enum ACTION {
	ACTION_NONE = 0
	ACTION_MOVING_CONTROL_POINT = 1
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
var control_action:int = ACTION.ACTION_NONE
var current_point_index:int
var from_position:Vector2

# Monitor change to node being edited
var edit_this_transform:Transform2D
var edit_this_collision_offset:float
var edit_this_collision_width:float
var edit_this_collision_extends:float
var edit_this_top_offset:float			# This also has an impact on open shaped collision

# Track our mode of operation
var current_mode:int = MODE.MODE_EDIT
var previous_mode:int = MODE.MODE_EDIT

# Undo stuff
var undo:UndoRedo = null
var undo_version:int = 0

# Snapping
var _snapping = Vector2(0,0)
var _snapping_offset = Vector2(0,0)

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
	tb_snap_x.editable = true
	tb_snap_x.connect("value_changed", self, "_snap_changed")
	tb_snap_x.hint_tooltip = "Snap X"
	hb.add_child(tb_snap_x)

	tb_snap_y = SpinBox.new()
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
	tb_edit.connect("pressed", self, "_enter_mode", [MODE.MODE_EDIT])
	tb_edit.hint_tooltip = "Control+LMB: Set Pivot Point\nLMB+Drag: Move Point\nLMB: Click on curve to split\nRMB: Delete Point"
	hb.add_child(tb_edit)

	tb_create = ToolButton.new()
	tb_create.icon = CURVE_CREATE
	tb_create.toggle_mode = true
	tb_create.pressed = false
	tb_create.connect("pressed", self, "_enter_mode", [MODE.MODE_CREATE])
	tb_create.hint_tooltip = "LMB: Add Point, Split in Curve or Close Shape\nLMB+Drag: Move Point"
	hb.add_child(tb_create)

	tb_delete = ToolButton.new()
	tb_delete.icon = CURVE_DELETE
	tb_delete.toggle_mode = true
	tb_delete.pressed = false
	tb_delete.connect("pressed", self, "_enter_mode", [MODE.MODE_DELETE])
	tb_delete.hint_tooltip = "LMB: Delete Point\nLMB+Drag: Move Point"
	hb.add_child(tb_delete)

	tb_pivot = ToolButton.new()
	tb_pivot.icon = PIVOT_POINT
	tb_pivot.toggle_mode = true
	tb_pivot.pressed = false
	tb_pivot.connect("pressed", self, "_enter_mode", [MODE.MODE_SET_PIVOT])
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
	if Engine.editor_hint == true:
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
	control_action = ACTION.ACTION_NONE
	current_point_index = -1
	
	edit_this = object as RMSmartShape2D
	
	update_overlays()

func _untoggle_all():
	for tb in [tb_edit, tb_create, tb_delete, tb_pivot]:
		tb.pressed=false

func _enter_mode(mode:int):
	_untoggle_all()

	if mode == MODE.MODE_EDIT:
		tb_edit.pressed = true
	if mode == MODE.MODE_CREATE:
		tb_create.pressed = true
	if mode == MODE.MODE_DELETE:
		tb_delete.pressed = true
	if mode == MODE.MODE_SET_PIVOT:
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

func forward_canvas_gui_input(event):
	if edit_this == null:
		return false

	if not is_instance_valid(edit_this):
		return false

	var et = get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform
	var t:Transform2D = et * edit_this.get_global_transform()
	var nt:Transform2D = edit_this.get_global_transform() * et

	var grab_threshold = get_editor_interface().get_editor_settings().get("editors/poly_editor/point_grab_radius")

	if current_point_index == -1:
		lbl_index.text = "Idx: None"
	else:
		lbl_index.text = "Idx:%d Tex:%s Flip:%s Width:%s" % \
			[
			current_point_index,
			edit_this.texture_indices[current_point_index],
			edit_this.texture_flip_indices[current_point_index],
			edit_this.width_indices[current_point_index]
			]

	if event is InputEventKey:
		var kb:InputEventKey = event
		if kb.scancode == KEY_SPACE and current_point_index != -1:
			if kb.pressed:
				edit_this.set_point_texture_flip(!edit_this.get_point_texture_flip(current_point_index), current_point_index)
				edit_this.bake_mesh()
				edit_this.update()
			return true

	if event is InputEventMouseButton:
		var mb:InputEventMouseButton = event
		if mb.pressed == false and mb.button_index == BUTTON_LEFT and control_action == ACTION.ACTION_MOVING_CONTROL_POINT:
			control_action = ACTION.ACTION_NONE
			
			if from_position.distance_to(edit_this.get_point_position(current_point_index)) > grab_threshold:
				undo.create_action("Move Control Point")
				
				undo.add_do_method(edit_this, "bake_mesh")
				undo.add_do_method(self, "update_overlays")
				
				if (current_point_index == 0 or current_point_index == edit_this.get_point_count() - 1) and edit_this.closed_shape:
					undo.add_undo_method(edit_this, "set_point_position", 0, from_position)
					undo.add_undo_method(edit_this, "set_point_position", edit_this.get_point_count() - 1, from_position)
				else:
					undo.add_undo_method(edit_this, "set_point_position", current_point_index, from_position)
				
				undo.add_undo_method(edit_this, "bake_mesh")
				undo.add_undo_method(self, "update_overlays")
				undo.commit_action()
				undo_version = undo.get_version()
				current_point_index = -1
				return true
				
			current_point_index = -1
		
		if mb.pressed == true and mb.button_index == BUTTON_WHEEL_UP and current_point_index != -1:
			var index:int = edit_this.get_point_texture_index(current_point_index) + 1
			var flip:bool = edit_this.get_point_texture_flip(current_point_index)
			edit_this.set_point_texture_index(index, current_point_index)
			edit_this.set_point_texture_flip(flip, current_point_index)
				
			edit_this.bake_mesh()
			update_overlays()
			return true
			
		if mb.pressed == true and mb.button_index == BUTTON_WHEEL_DOWN and current_point_index != -1:
			var index = edit_this.get_point_texture_index(current_point_index) - 1
			edit_this.set_point_texture_index(index, current_point_index)
			
			if Input.is_key_pressed(KEY_ALT):
				edit_this.set_point_texture_flip(true, current_point_index)
			else:
				edit_this.set_point_texture_flip(false, current_point_index)
			
			edit_this.bake_mesh()
			update_overlays()
			return true

			
		if mb.pressed == true and mb.button_index == BUTTON_LEFT and current_point_index != -1:
			if current_mode == MODE.MODE_CREATE and edit_this.closed_shape == false and current_point_index == 0:
				undo.create_action("Close Shape")
				undo.add_do_property(edit_this, "closed_shape", true)
				undo.add_do_method(edit_this, "property_list_changed_notify")
				undo.add_undo_property(edit_this, "closed_shape", false)
				undo.add_undo_method(edit_this, "property_list_changed_notify")
				undo.commit_action()
				undo_version = undo.get_version()
				
				control_action = ACTION.ACTION_MOVING_CONTROL_POINT
				from_position = edit_this.get_point_position(0)
				return true
			else:
				control_action = ACTION.ACTION_MOVING_CONTROL_POINT
				from_position = edit_this.get_point_position(current_point_index)
				return true
		elif mb.pressed == true and ((mb.button_index == BUTTON_RIGHT and current_mode == MODE.MODE_EDIT) or (current_mode == MODE.MODE_DELETE and mb.button_index == BUTTON_LEFT)) and current_point_index != -1:
			var close_this:bool = false
			undo.create_action("Delete Point")
			if edit_this.closed_shape == true and (current_point_index == edit_this.get_point_count() - 1 or current_point_index == 0):
				var pt = edit_this.get_point_position(0)

				undo.add_do_method(edit_this, "remove_point", edit_this.get_point_count() - 1)
				undo.add_do_method(edit_this, "remove_point", 0)
				undo.add_undo_method(edit_this, "add_point_to_curve", pt, 0)
				undo.add_undo_method(edit_this,"set_point_position", edit_this.get_point_count() - 1, pt)
				
				close_this = true
			else:
				var pt:Vector2 = edit_this.get_point_position(current_point_index)
				undo.add_do_method(edit_this, "remove_point", current_point_index)
				undo.add_undo_method(edit_this, "add_point_to_curve", pt, current_point_index)
		
			undo.add_do_method(self, "update_overlays")
			undo.add_undo_method(self, "update_overlays")
			undo.add_do_method(edit_this, "bake_mesh")
			undo.add_undo_method(edit_this, "bake_mesh")
			undo.commit_action()
			undo_version = undo.get_version()
			
			current_point_index = -1
			
			if close_this:
				_close_shape()
			
			return true
		elif mb.pressed == true and mb.button_index == BUTTON_LEFT:
			#First, check if we are changing our pivot point
			if (current_mode == MODE.MODE_SET_PIVOT) or (current_mode == MODE.MODE_EDIT and mb.control == true):
				var old_pos = et.xform( edit_this.get_parent().get_global_transform().xform(edit_this.position))
				undo.create_action("Set Pivot")
				var snapped_position = _snap_position(et.affine_inverse().xform(mb.position), _snapping) + _snapping_offset
				undo.add_do_method(self, "_set_pivot", snapped_position)
				undo.add_undo_method(self, "_set_pivot", et.affine_inverse().xform(old_pos))
				undo.add_do_method(edit_this, "bake_mesh")
				undo.add_undo_method(edit_this, "bake_mesh")
				undo.add_do_method(self, "update_overlays")
				undo.add_undo_method(self, "update_overlays")
				undo.commit_action()
				undo_version = undo.get_version()
				return true
			
			if current_mode == MODE.MODE_CREATE and on_edge == false:
				if (edit_this.closed_shape == true and edit_this.get_point_count() < 3) or edit_this.closed_shape == false:
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
					
					if edit_this.closed_shape and edit_this.get_point_count() == 3:
						_close_shape()
						
					current_point_index = edit_this.get_point_count() - 1
					from_position = edit_this.get_point_position(current_point_index)
					control_action = ACTION.ACTION_MOVING_CONTROL_POINT
						
					return true
				
			if (current_mode == MODE.MODE_CREATE or current_mode == MODE.MODE_EDIT) and on_edge == true:
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
				
				current_point_index = insertion_point + 1
				from_position = edit_this.get_point_position(current_point_index)
				control_action = ACTION.ACTION_MOVING_CONTROL_POINT
				
				return true
				
				
	if event is InputEventMouseMotion:
		var mm:InputEventMouseMotion = event
		
		if control_action == ACTION.ACTION_MOVING_CONTROL_POINT:
			var snapped_position = _snap_position(t.affine_inverse().xform(mm.position), _snapping) + _snapping_offset
			# Appears we are moving a point
			if edit_this.closed_shape == true and (current_point_index == edit_this.get_point_count() - 1 or current_point_index == 0):
				edit_this.set_point_position(edit_this.get_point_count() - 1, snapped_position)
				edit_this.set_point_position(0, snapped_position)
			else:
				edit_this.set_point_position(current_point_index, snapped_position)
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
		current_point_index = -1
		for i in edit_this.get_point_count():
			var pp:Vector2 = edit_this.get_point_position(i)
			var p:Vector2 = xform.xform(pp)
			if p.distance_to(gpoint) <= grab_threshold:
				on_edge = false
				current_point_index = i
				break
				
		if current_mode != MODE.MODE_CREATE and current_mode != MODE.MODE_EDIT:
			on_edge = false #Ensure we are not on the edge if not in the proper mode
			
		if on_edge == true or old_edge != on_edge:
			update_overlays()
			return true

	return false
	
func _close_shape():
	if edit_this.closed_shape and edit_this.get_point_position(0) != edit_this.get_point_position(edit_this.get_point_count() - 1):
		edit_this.add_point_to_curve(edit_this.get_point_position(0))
		edit_this.bake_mesh()
		update_overlays()
	if edit_this.closed_shape == false and edit_this.get_point_position(0) == edit_this.get_point_position(edit_this.get_point_count() - 1):
		edit_this.remove_point(edit_this.get_point_count()-1)
		edit_this.bake_mesh()
		update_overlays()

func _curve_changed():
	control_action = ACTION.ACTION_NONE
	current_point_index = -1
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
		
		if on_edge==true:
			overlay.draw_texture(ADD_HANDLE, edge_point - ADD_HANDLE.get_size() * 0.5)
			
		# Draw Highlighted Handle
		if current_point_index != -1:
			overlay.draw_circle(t.xform( edit_this.get_point_position(current_point_index) ), 5, Color.white )
			overlay.draw_circle(t.xform( edit_this.get_point_position(current_point_index) ), 3, Color.black)
		
		edit_this.update()

func _snap_changed(ignore_value):
	_snapping = Vector2(tb_snap_x.value, tb_snap_y.value)
func _snap_offset_changed(ignore_value):
	_snapping_offset = Vector2(tb_snap_offset_x.value, tb_snap_offset_y.value)
