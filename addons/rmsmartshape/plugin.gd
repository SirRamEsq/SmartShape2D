tool
extends EditorPlugin

"""
Common Abbreviations
et = editor transform (viewport's canvas transform)

- Snapping using the build in functionality isn't going to happen
	- https://github.com/godotengine/godot/issues/11180
	- https://godotengine.org/qa/18051/tool-script-in-3-0
"""

# Icons
const ICON_HANDLE = preload("assets/icon_editor_handle.svg")
const ICON_HANDLE_SELECTED = preload("assets/icon_editor_handle_selected.svg")
const ICON_HANDLE_BEZIER = preload("assets/icon_editor_handle_bezier.svg")
const ICON_HANDLE_CONTROL = preload("assets/icon_editor_handle_control.svg")
const ICON_ADD_HANDLE = preload("assets/icon_editor_handle_add.svg")
const ICON_CURVE_EDIT = preload("assets/icon_curve_edit.svg")
const ICON_CURVE_CREATE = preload("assets/icon_curve_create.svg")
const ICON_CURVE_DELETE = preload("assets/icon_curve_delete.svg")
const ICON_PIVOT_POINT = preload("assets/icon_editor_position.svg")
const ICON_COLLISION = preload("assets/icon_collision_polygon_2d.svg")
const ICON_INTERP_LINEAR = preload("assets/InterpLinear.svg")
const ICON_SNAP = preload("assets/icon_editor_snap.svg")
const ICON_IMPORT_CLOSED = preload("assets/closed_shape.png")
const ICON_IMPORT_OPEN = preload("assets/open_shape.png")
const FUNC = preload("plugin-functionality.gd")

enum MODE { EDIT_VERT, EDIT_EDGE, SET_PIVOT, CREATE_VERT }

enum ACTION_VERT {
	NONE = 0,
	MOVE_VERT = 1,
	MOVE_CONTROL = 2,
	MOVE_CONTROL_IN = 3,
	MOVE_CONTROL_OUT = 4,
	MOVE_WIDTH_HANDLE = 5
}


# Data related to an action being taken on points
class ActionDataVert:
	#Type of Action from the ACTION_VERT enum
	var type: int = ACTION_VERT.NONE
	# The affected Verticies and their initial positions
	var keys = []
	var starting_width = []
	var starting_positions = []
	var starting_positions_control_in = []
	var starting_positions_control_out = []

	func _init(
		_keys: Array,
		positions: Array,
		positions_in: Array,
		positions_out: Array,
		width: Array,
		t: int
	):
		type = t
		keys = _keys
		starting_positions = positions
		starting_positions_control_in = positions_in
		starting_positions_control_out = positions_out
		starting_width = width

	func are_verts_selected() -> bool:
		return keys.size() > 0

	func to_string() -> String:
		var s = "%s: %s = %s"
		return s % [type, keys, starting_positions]

	func is_single_vert_selected() -> bool:
		if keys.size() == 1:
			return true
		return false

	func current_point_key() -> int:
		if not is_single_vert_selected():
			return -1
		return keys[0]

	func current_point_index(s: SS2D_Shape_Base) -> int:
		if not is_single_vert_selected():
			return -1
		return s.get_point_index(keys[0])


# PRELOADS
var GUI_SNAP_POPUP = preload("scenes/SnapPopup.tscn")
var GUI_POINT_INFO_PANEL = preload("scenes/GUI_InfoPanel.tscn")
var GUI_EDGE_INFO_PANEL = preload("scenes/GUI_Edge_InfoPanel.tscn")
var gui_point_info_panel = GUI_POINT_INFO_PANEL.instance()
var gui_edge_info_panel = GUI_EDGE_INFO_PANEL.instance()
var gui_snap_settings = GUI_SNAP_POPUP.instance()

# This is the shape node being edited
var shape = null
# For when a legacy shape is selected
var legacy_shape = null

# Toolbar Stuff
var tb_hb: HBoxContainer = null
var tb_hb_legacy_import: HBoxContainer = null
var tb_import: ToolButton = null
var tb_vert_create: ToolButton = null
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
var edge_data: SS2D_Edge = null

# Width Handle Stuff
var on_width_handle: bool = false
const WIDTH_HANDLE_OFFSET: float = 60.0
var closest_key: int
var closest_edge_keys: Array = [-1, -1]
var width_scaling: float

# Track our mode of operation
var current_mode: int = MODE.CREATE_VERT
var previous_mode: int = MODE.CREATE_VERT

# Undo stuff
var undo: UndoRedo = null
var undo_version: int = 0

var current_action = ActionDataVert.new([], [], [], [], [], ACTION_VERT.NONE)
var cached_shape_global_transform: Transform2D

# Action Move Variables
var _mouse_motion_delta_starting_pos = Vector2(0, 0)

# Track the property plugin
var plugin

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
	if id == 1:
		tb_snap_popup.set_item_checked(id, not tb_snap_popup.is_item_checked(id))
	elif id == 3:
		gui_display_snap_settings()


func _gui_build_toolbar():
	tb_hb = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb)
	tb_hb_legacy_import = HBoxContainer.new()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb_legacy_import)
	tb_import = ToolButton.new()
	tb_import.icon = ICON_IMPORT_CLOSED
	tb_import.toggle_mode = false
	tb_import.pressed = false
	tb_import.hint_tooltip = SS2D_Strings.EN_TOOLTIP_IMPORT
	tb_import.connect("pressed", self, "_import_legacy")
	tb_hb_legacy_import.add_child(tb_import)

	var sep = VSeparator.new()
	tb_hb.add_child(sep)

	tb_vert_create = create_tool_button(ICON_CURVE_CREATE, SS2D_Strings.EN_TOOLTIP_CREATE_VERT)
	tb_vert_create.connect("pressed", self, "_enter_mode", [MODE.CREATE_VERT])
	tb_vert_create.pressed = true

	tb_vert_edit = create_tool_button(ICON_CURVE_EDIT, SS2D_Strings.EN_TOOLTIP_EDIT_VERT)
	tb_vert_edit.connect("pressed", self, "_enter_mode", [MODE.EDIT_VERT])

	tb_edge_edit = create_tool_button(ICON_INTERP_LINEAR, SS2D_Strings.EN_TOOLTIP_EDIT_EDGE)
	tb_edge_edit.connect("pressed", self, "_enter_mode", [MODE.EDIT_EDGE])

	tb_pivot = create_tool_button(ICON_PIVOT_POINT, SS2D_Strings.EN_TOOLTIP_EDIT_VERT)
	tb_pivot.connect("pressed", self, "_enter_mode", [MODE.SET_PIVOT])

	tb_collision = create_tool_button(ICON_COLLISION, SS2D_Strings.EN_TOOLTIP_COLLISION)
	tb_collision.connect("pressed", self, "_add_collision")

	tb_snap = MenuButton.new()
	tb_snap.hint_tooltip = SS2D_Strings.EN_TOOLTIP_SNAP
	tb_snap_popup = tb_snap.get_popup()
	tb_snap.icon = ICON_SNAP
	tb_snap_popup.add_check_item("Use Grid Snap")
	tb_snap_popup.add_check_item("Snap Relative")
	tb_snap_popup.add_separator()
	tb_snap_popup.add_item("Configure Snap...")
	tb_snap_popup.hide_on_checkable_item_selection = false
	tb_hb.add_child(tb_snap)
	tb_snap_popup.connect("id_pressed", self, "_snapping_item_selected")

	tb_hb.hide()
	tb_hb_legacy_import.hide()


func create_tool_button(icon, tooltip):
	var tb = ToolButton.new()
	tb.toggle_mode = true
	tb.icon = icon
	tb.hint_tooltip = tooltip
	tb_hb.add_child(tb)
	return tb


func _gui_update_vert_info_panel():
	var idx = current_action.current_point_index(shape)
	var key = current_action.current_point_key()
	if not is_key_valid(shape, key):
		gui_point_info_panel.visible = false
		return
	gui_point_info_panel.visible = true
	# Shrink panel
	gui_point_info_panel.rect_size = Vector2(1, 1)

	var properties = shape.get_point_properties(key)
	gui_point_info_panel.set_idx(idx)
	gui_point_info_panel.set_texture_idx(properties.texture_idx)
	gui_point_info_panel.set_width(properties.width)
	gui_point_info_panel.set_flip(properties.flip)


func _gui_update_edge_info_panel():
	# Don't update if already visible
	if gui_edge_info_panel.visible:
		return
	var indicies = [-1, -1]
	var override = null
	if on_edge:
		var t: Transform2D = get_et() * shape.get_global_transform()
		var offset = shape.get_closest_offset_straight_edge(t.affine_inverse().xform(edge_point))
		var keys = _get_edge_point_keys_from_offset(offset, true)
		indicies = [shape.get_point_index(keys[0]), shape.get_point_index(keys[1])]
		if shape.has_material_override(keys):
			override = shape.get_material_override(keys)
	gui_edge_info_panel.set_indicies(indicies)
	if override != null:
		gui_edge_info_panel.set_material_override(true)
		gui_edge_info_panel.load_values_from_meta_material(override)
	else:
		gui_edge_info_panel.set_material_override(false)

	# Shrink panel to minimum size
	gui_edge_info_panel.rect_size = Vector2(1, 1)


func _gui_update_info_panels():
	match current_mode:
		MODE.EDIT_VERT:
			_gui_update_vert_info_panel()
			gui_edge_info_panel.visible = false
		MODE.EDIT_EDGE:
			_gui_update_edge_info_panel()
			gui_point_info_panel.visible = false


#########
# GODOT #
#########


# Called when saving
# https://docs.godotengine.org/en/3.2/classes/class_editorplugin.html?highlight=switch%20scene%20tab
func apply_changes():
	gui_point_info_panel.visible = false
	gui_edge_info_panel.visible = false


func _init():
	pass


func _ready():
	undo = get_undo_redo()
	# Support the undo-redo actions
	_gui_build_toolbar()
	add_child(gui_point_info_panel)
	gui_point_info_panel.visible = false
	add_child(gui_edge_info_panel)
	gui_edge_info_panel.visible = false
	gui_edge_info_panel.connect("set_material_override", self, "_on_set_edge_material_override")
	gui_edge_info_panel.connect("set_render", self, "_on_set_edge_material_override_render")
	gui_edge_info_panel.connect("set_weld", self, "_on_set_edge_material_override_weld")
	gui_edge_info_panel.connect("set_z_index", self, "_on_set_edge_material_override_z_index")
	gui_edge_info_panel.connect("set_edge_material", self, "_on_set_edge_material")
	add_child(gui_snap_settings)


func _enter_tree():
	plugin = preload("res://addons/rmsmartshape/inpsector_plugin.gd").new()
	if plugin != null:
		add_inspector_plugin(plugin)
		
	pass


func _exit_tree():
	if (plugin != null):
		remove_inspector_plugin(plugin)
		
	gui_point_info_panel.visible = false
	gui_edge_info_panel.visible = false
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tb_hb_legacy_import)
	tb_hb.queue_free()
	tb_hb_legacy_import.queue_free()

func forward_canvas_gui_input(event):
	if not is_shape_valid(shape):
		return false

	var et = get_et()
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

	_gui_update_info_panels()
	return return_value


func _process(delta):
	if not Engine.editor_hint:
		return

	if not is_shape_valid(shape):
		gui_point_info_panel.visible = false
		gui_edge_info_panel.visible = false
		shape = null
		update_overlays()
		return
	# Force update if global transforma has been changed
	if cached_shape_global_transform != shape.get_global_transform():
		shape.set_as_dirty()
		cached_shape_global_transform = shape.get_global_transform()


func handles(object):
	tb_hb.hide()
	tb_hb_legacy_import.hide()
	update_overlays()
	gui_point_info_panel.visible = false
	gui_edge_info_panel.visible = false

	if object is Resource:
		return false

	var rslt: bool = object is SS2D_Shape_Base or object is RMSmartShape2D
	return rslt


func edit(object):
	on_edge = false
	deselect_verts()
	if is_shape_valid(shape):
		disconnect_shape(shape)
	if is_shape_valid(legacy_shape):
		disconnect_shape(legacy_shape)

	shape = null
	legacy_shape = null

	if object is RMSmartShape2D:
		tb_hb.hide()
		tb_hb_legacy_import.show()
		if object.closed_shape:
			tb_import.icon = ICON_IMPORT_CLOSED
		else:
			tb_import.icon = ICON_IMPORT_OPEN

		legacy_shape = object
		connect_shape(legacy_shape)
	else:
		tb_hb.show()
		tb_hb_legacy_import.hide()

		shape = object
		connect_shape(shape)

	update_overlays()


func make_visible(visible):
	pass


############
# SNAPPING #
############
func use_global_snap() -> bool:
	return ! tb_snap_popup.is_item_checked(1)


func use_snap() -> bool:
	return tb_snap_popup.is_item_checked(0)


func get_snap_offset() -> Vector2:
	return gui_snap_settings.get_snap_offset()


func get_snap_step() -> Vector2:
	return gui_snap_settings.get_snap_step()


func snap(v: Vector2, force: bool = false) -> Vector2:
	if not use_snap() and not force:
		return v
	var step = get_snap_step()
	var offset = get_snap_offset()
	var t = Transform2D.IDENTITY
	if use_global_snap():
		t = shape.get_global_transform()
	return snap_position(v, offset, step, t)


static func snap_position(
	pos_global: Vector2, snap_offset: Vector2, snap_step: Vector2, local_t: Transform2D
) -> Vector2:
	# Move global position to local position to snap in local space
	var pos_local = local_t * pos_global

	# Snap in local space
	var x = pos_local.x
	if snap_step.x != 0:
		var delta = fmod(pos_local.x, snap_step.x)
		# Round up
		if delta >= (snap_step.x / 2.0):
			x = pos_local.x + (snap_step.x - delta)
		# Round down
		else:
			x = pos_local.x - delta
	var y = pos_local.y
	if snap_step.y != 0:
		var delta = fmod(pos_local.y, snap_step.y)
		# Round up
		if delta >= (snap_step.y / 2.0):
			y = pos_local.y + (snap_step.y - delta)
		# Round down
		else:
			y = pos_local.y - delta

	# Transform local position to global position
	var pos_global_snapped = (local_t.affine_inverse() * Vector2(x, y)) + snap_offset
	#print ("%s | %s | %s | %s" % [pos_global, pos_local, Vector2(x,y), pos_global_snapped])
	return pos_global_snapped


##########
# PLUGIN #
##########
func _import_legacy():
	call_deferred("_import_legacy_impl")


func _import_legacy_impl():
	if legacy_shape == null:
		push_error("LEGACY SHAPE IS NULL")
		return
	if not legacy_shape is RMSmartShape2D:
		push_error("LEGACY SHAPE NOT VALID")
		return
	var par = legacy_shape.get_parent()
	if par == null:
		push_error("LEGACY SHAPE PARENT IS NULL")
		return

	# Make new shape and set values
	var new_shape = null
	if legacy_shape.closed_shape:
		new_shape = SS2D_Shape_Closed.new()
		new_shape.name = "SS2D_Shape_Closed"
	else:
		new_shape = SS2D_Shape_Open.new()
		new_shape.name = "SS2D_Shape_Open"
	new_shape.import_from_legacy(legacy_shape)
	new_shape.transform = legacy_shape.transform

	# Add new to scene tree
	par.add_child(new_shape)
	new_shape.owner = get_editor_interface().get_edited_scene_root()

	# Remove Legacy from scene tree
	disconnect_shape(legacy_shape)
	par.remove_child(legacy_shape)
	legacy_shape.queue_free()
	legacy_shape = null

	# Edit the new shape
	#edit(new_shape)


func _on_legacy_closed_changed():
	if is_shape_valid(legacy_shape):
		if legacy_shape is RMSmartShape2D:
			if legacy_shape.closed_shape:
				tb_import.icon = ICON_IMPORT_CLOSED
			else:
				tb_import.icon = ICON_IMPORT_OPEN


func disconnect_shape(s):
	if s.is_connected("points_modified", self, "_on_shape_point_modified"):
		s.disconnect("points_modified", self, "_on_shape_point_modified")
	# Legacy
	if s is RMSmartShape2D:
		if s.is_connected("on_closed_change", self, "_on_legacy_closed_changed"):
			s.disconnect("on_closed_change", self, "_on_legacy_closed_changed")


func connect_shape(s):
	if not s.is_connected("points_modified", self, "_on_shape_point_modified"):
		s.connect("points_modified", self, "_on_shape_point_modified")
	if s is RMSmartShape2D:
		if not s.is_connected("on_closed_change", self, "_on_legacy_closed_changed"):
			s.connect("on_closed_change", self, "_on_legacy_closed_changed")


static func get_material_override_from_indicies(shape: SS2D_Shape_Base, indicies: Array):
	var keys = []
	for i in indicies:
		keys.push_back(shape.get_point_key_at_index(i))
	if not shape.has_material_override(keys):
		return null
	return shape.get_material_override(keys)


func _on_set_edge_material_override_render(enabled: bool):
	var override = get_material_override_from_indicies(shape, gui_edge_info_panel.indicies)
	if override != null:
		override.render = enabled


func _on_set_edge_material_override_weld(enabled: bool):
	var override = get_material_override_from_indicies(shape, gui_edge_info_panel.indicies)
	if override != null:
		override.weld = enabled


func _on_set_edge_material_override_z_index(z: int):
	var override = get_material_override_from_indicies(shape, gui_edge_info_panel.indicies)
	if override != null:
		override.z_index = z


func _on_set_edge_material(m: SS2D_Material_Edge):
	var override = get_material_override_from_indicies(shape, gui_edge_info_panel.indicies)
	if override != null:
		override.edge_material = m


func _on_set_edge_material_override(enabled: bool):
	var indicies = gui_edge_info_panel.indicies
	if indicies.has(-1) or indicies.size() != 2:
		return
	var keys = []
	for i in indicies:
		keys.push_back(shape.get_point_key_at_index(i))

	# Get the relevant Override data if any exists
	var override = null
	if shape.has_material_override(keys):
		override = shape.get_material_override(keys)

	if enabled:
		if override == null:
			override = SS2D_Material_Edge_Metadata.new()
			override.edge_material = null
			shape.set_material_override(keys, override)

		# Load override data into the info panel
		gui_edge_info_panel.load_values_from_meta_material(override)
	else:
		if override != null:
			shape.remove_material_override(keys)


static func is_shape_valid(s) -> bool:
	if s == null:
		return false
	if not is_instance_valid(s):
		return false
	if not s.is_inside_tree():
		return false
	return true


func _on_shape_point_modified():
	FUNC.action_invert_orientation(self, "update_overlays", undo, shape)


func get_et() -> Transform2D:
	return get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform


static func is_key_valid(s: SS2D_Shape_Base, key: int) -> bool:
	if not is_shape_valid(s):
		return false
	return s.has_point(key)


func _enter_mode(mode: int):
	if current_mode == mode:
		return
	for tb in [tb_vert_edit, tb_edge_edit, tb_pivot, tb_vert_create]:
		tb.pressed = false

	previous_mode = current_mode
	current_mode = mode
	match mode:
		MODE.CREATE_VERT:
			tb_vert_create.pressed = true
		MODE.EDIT_VERT:
			tb_vert_edit.pressed = true
		MODE.EDIT_EDGE:
			tb_edge_edit.pressed = true
		MODE.SET_PIVOT:
			tb_pivot.pressed = true
		_:
			tb_vert_edit.pressed = true
	update_overlays()


func _set_pivot(point: Vector2):
	var et = get_et()

	var np: Vector2 = point
	var ct: Transform2D = shape.get_global_transform()
	ct.origin = np

	shape.disable_constraints()
	for i in shape.get_point_count():
		var key = shape.get_point_key_at_index(i)
		var pt = shape.get_global_transform().xform(shape.get_point_position(key))
		shape.set_point_position(key, ct.affine_inverse().xform(pt))
	shape.enable_constraints()

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


#############
# RENDERING #
#############
func forward_canvas_draw_over_viewport(overlay: Control):
	# Something might force a draw which we had no control over,
	# in this case do some updating to be sure
	if not is_shape_valid(shape) or not is_inside_tree():
		return

	if undo_version != undo.get_version():
		if (
			undo.get_current_action_name() == "Move CanvasItem"
			or undo.get_current_action_name() == "Rotate CanvasItem"
			or undo.get_current_action_name() == "Scale CanvasItem"
		):
			shape.set_as_dirty()
			undo_version = undo.get_version()

	match current_mode:
		MODE.CREATE_VERT:
			draw_mode_edit_vert(overlay)
			if Input.is_key_pressed(KEY_ALT) and Input.is_key_pressed(KEY_SHIFT):
				draw_new_shape_preview(overlay)
			elif Input.is_key_pressed(KEY_ALT):
				draw_new_point_close_preview(overlay)
			else:
				draw_new_point_preview(overlay)
		MODE.EDIT_VERT:
			draw_mode_edit_vert(overlay)
			if Input.is_key_pressed(KEY_ALT):
				if Input.is_key_pressed(KEY_SHIFT):
					draw_new_shape_preview(overlay)
				elif not on_edge:
					draw_new_point_close_preview(overlay)
		MODE.EDIT_EDGE:
			draw_mode_edit_edge(overlay)

	shape.update()


func draw_mode_edit_edge(overlay: Control):
	var t: Transform2D = get_et() * shape.get_global_transform()
	var verts = shape.get_vertices()
	var edges = shape.get_edges()

	var color_highlight = Color(1.0, 0.75, 0.75, 1.0)
	var color_normal = Color(1.0, 0.25, 0.25, 0.8)

	draw_shape_outline(overlay, t, verts, color_normal, 3.0)
	draw_vert_handles(overlay, t, verts, false)

	if current_action.type == ACTION_VERT.MOVE_VERT:
		var edge_point_keys = current_action.keys
		var p1 = shape.get_point_position(edge_point_keys[0])
		var p2 = shape.get_point_position(edge_point_keys[1])
		overlay.draw_line(t.xform(p1), t.xform(p2), color_highlight, 5.0)
	elif on_edge:
		var offset = shape.get_closest_offset_straight_edge(t.affine_inverse().xform(edge_point))
		var edge_point_keys = _get_edge_point_keys_from_offset(offset, true)
		var p1 = shape.get_point_position(edge_point_keys[0])
		var p2 = shape.get_point_position(edge_point_keys[1])
		overlay.draw_line(t.xform(p1), t.xform(p2), color_highlight, 5.0)


func draw_mode_edit_vert(overlay: Control):
	var t: Transform2D = get_et() * shape.get_global_transform()
	var verts = shape.get_vertices()
	var points = shape.get_tessellated_points()
	draw_shape_outline(overlay, t, points)
	draw_vert_handles(overlay, t, verts, true)
	if on_edge:
		overlay.draw_texture(ICON_ADD_HANDLE, edge_point - ICON_ADD_HANDLE.get_size() * 0.5)

	# Draw Highlighted Handle
	if current_action.is_single_vert_selected():
		var tex = ICON_HANDLE_SELECTED
		overlay.draw_texture(
			tex, t.xform(verts[current_action.current_point_index(shape)]) - tex.get_size() * 0.5
		)


func draw_shape_outline(overlay: Control, t: Transform2D, points, color = null, width = 2.0):
	# Draw Outline
	var prev_pt = null
	if color == null:
		color = shape.modulate
	for i in range(0, points.size(), 1):
		var pt = points[i]
		if prev_pt != null:
			overlay.draw_line(prev_pt, t.xform(pt), color, width, true)
		prev_pt = t.xform(pt)


func draw_vert_handles(overlay: Control, t: Transform2D, verts, control_points: bool):
	for i in range(0, verts.size(), 1):
		# Draw Vert handles
		var key: int = shape.get_point_key_at_index(i)
		var hp: Vector2 = t.xform(verts[i])
		var icon = ICON_HANDLE_BEZIER if Input.is_key_pressed(KEY_SHIFT) else ICON_HANDLE
		overlay.draw_texture(icon, hp - icon.get_size() * 0.5)

		# Draw Width handles
#		var normal = _get_vert_normal(t, verts, i)
#		var width_handle_icon = WIDTH_HANDLES[int((normal.angle() + PI / 8 + TAU) / PI * 4) % 4]
#		overlay.draw_texture(width_handle_icon, hp - width_handle_icon.get_size() * 0.5 + normal * WIDTH_HANDLE_OFFSET)

	# Draw Width handle
	var offset = WIDTH_HANDLE_OFFSET
	var width_handle_key = closest_key
	if (
		Input.is_mouse_button_pressed(BUTTON_LEFT)
		and current_action.type == ACTION_VERT.MOVE_WIDTH_HANDLE
	):
		offset *= width_scaling
		width_handle_key = current_action.keys[0]
	var width_handle_normal = _get_vert_normal(t, verts, shape.get_point_index(width_handle_key))
	var vertex_position: Vector2 = t.xform(shape.get_point_position(width_handle_key))
	var icon_position: Vector2 = vertex_position + width_handle_normal * offset
	var rect_size: Vector2 = Vector2.ONE * 10.0
	var width_handle_color = Color("f53351")
	overlay.draw_line(vertex_position, icon_position, width_handle_color, 1.0, true)
	overlay.draw_set_transform(icon_position, width_handle_normal.angle(), Vector2.ONE)
	overlay.draw_rect(Rect2(-rect_size / 2.0, rect_size), width_handle_color, true, 1.0)
	overlay.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# Draw Control point handles
	if control_points:
		for i in range(0, verts.size(), 1):
			var normal = _get_vert_normal(t, verts, i)
			var key = shape.get_point_key_at_index(i)
			var hp = t.xform(verts[i])

			# Drawing the point-out for the last point makes no sense, as there's no point ahead of it
			if i < verts.size() - 1:
				var pointout = t.xform(verts[i] + shape.get_point_out(key))
				if hp != pointout:
					_draw_control_point_line(overlay, hp, pointout, ICON_HANDLE_CONTROL)
			# Drawing the point-in for point 0 makes no sense, as there's no point behind it
			if i > 0:
				var pointin = t.xform(verts[i] + shape.get_point_in(key))
				if hp != pointin:
					_draw_control_point_line(overlay, hp, pointin, ICON_HANDLE_CONTROL)


func _draw_control_point_line(c: Control, vert: Vector2, cp: Vector2, tex: Texture):
	# Draw the line with a dark and light color to be visible on all backgrounds
	var color_dark = Color(0, 0, 0, 0.3)
	var color_light = Color(1, 1, 1, .5)
	var width = 2.0
	var normal = (cp - vert).normalized()
	c.draw_line(vert + normal * 4 + Vector2.DOWN, cp + Vector2.DOWN, color_dark, width, true)
	c.draw_line(vert + normal * 4, cp, color_light, width, true)
	c.draw_texture(tex, cp - tex.get_size() * 0.5)


func draw_new_point_preview(overlay: Control):
	# Draw lines to where a new point will be added
	var verts = shape.get_vertices()
	var t: Transform2D = get_et() * shape.get_global_transform()
	var color = Color(1, 1, 1, .5)
	var width = 2

	var a
	var mouse = overlay.get_local_mouse_position()
	if is_shape_closed(shape):
		a = t.xform(verts[verts.size() - 2])
		var b = t.xform(verts[0])
		overlay.draw_line(mouse, b, color, width * .5, true)
	else:
		a = t.xform(verts[verts.size() - 1])
	overlay.draw_line(mouse, a, color, width, true)
	overlay.draw_texture(ICON_ADD_HANDLE, mouse - ICON_ADD_HANDLE.get_size() * 0.5)


func draw_new_point_close_preview(overlay: Control):
	# Draw lines to where a new point will be added
	var verts = shape.get_vertices()
	var t: Transform2D = get_et() * shape.get_global_transform()
	var color = Color(1, 1, 1, .5)
	var width = 2

	var mouse = overlay.get_local_mouse_position()
	var a = t.xform(shape.get_point_position(closest_edge_keys[0]))
	var b = t.xform(shape.get_point_position(closest_edge_keys[1]))
#	var a = 
#	var b = t.xform()
	overlay.draw_line(mouse, b, color, width, true)
	overlay.draw_line(mouse, a, color, width, true)
	overlay.draw_texture(ICON_ADD_HANDLE, mouse - ICON_ADD_HANDLE.get_size() * 0.5)


func draw_new_shape_preview(overlay: Control):
	# Draw a plus where a new shape will be added
	var mouse = overlay.get_local_mouse_position()
	overlay.draw_texture(ICON_ADD_HANDLE, mouse - ICON_ADD_HANDLE.get_size() * 0.5)


##########
# PLUGIN #
##########
func deselect_verts():
	current_action = ActionDataVert.new([], [], [], [], [], ACTION_VERT.NONE)


func select_verticies(keys: Array, action: int) -> ActionDataVert:
	var from_positions = []
	var from_positions_c_in = []
	var from_positions_c_out = []
	var from_widths = []
	for key in keys:
		from_positions.push_back(shape.get_point_position(key))
		from_positions_c_in.push_back(shape.get_point_in(key))
		from_positions_c_out.push_back(shape.get_point_out(key))
		from_widths.push_back(shape.get_point_width(key))
	return ActionDataVert.new(
		keys, from_positions, from_positions_c_in, from_positions_c_out, from_widths, action
	)


func select_vertices_to_move(keys: Array, _mouse_starting_pos_viewport: Vector2):
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport
	current_action = select_verticies(keys, ACTION_VERT.MOVE_VERT)


func select_control_points_to_move(
	keys: Array, _mouse_starting_pos_viewport: Vector2, action = ACTION_VERT.MOVE_CONTROL
):
	current_action = select_verticies(keys, action)
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport


func select_width_handle_to_move(keys: Array, _mouse_starting_pos_viewport: Vector2):
	_mouse_motion_delta_starting_pos = _mouse_starting_pos_viewport
	current_action = select_verticies(keys, ACTION_VERT.MOVE_WIDTH_HANDLE)


#########
# INPUT #
#########
func _input_handle_right_click_press(mb_position: Vector2, grab_threshold: float) -> bool:
	if not shape.can_edit:
		return false
	if current_mode == MODE.EDIT_VERT or current_mode == MODE.CREATE_VERT:
		# Mouse over a single vertex?
		if current_action.is_single_vert_selected():
			FUNC.action_delete_point(self, "update_overlays", undo, shape, current_action.keys[0])
			undo_version = undo.get_version()
			deselect_verts()
			return true
		else:
			# Mouse over a control point?
			var et = get_et()
			var points_in = FUNC.get_intersecting_control_point_in(
				shape, et, mb_position, grab_threshold
			)
			var points_out = FUNC.get_intersecting_control_point_out(
				shape, et, mb_position, grab_threshold
			)
			if not points_in.empty():
				FUNC.action_delete_point_in(self, "update_overlays", undo, shape, points_in[0])
				undo_version = undo.get_version()
				return true
			elif not points_out.empty():
				FUNC.action_delete_point_out(self, "update_overlays", undo, shape, points_out[0])
				undo_version = undo.get_version()
				return true
	elif current_mode == MODE.EDIT_EDGE:
		if on_edge:
			gui_edge_info_panel.visible = not gui_edge_info_panel.visible
			gui_edge_info_panel.rect_position = mb_position + Vector2(256, -24)
	return false


func _input_handle_left_click(
	mb: InputEventMouseButton,
	vp_m_pos: Vector2,
	t: Transform2D,
	et: Transform2D,
	grab_threshold: float
) -> bool:
	# Set Pivot?
	if current_mode == MODE.SET_PIVOT:
		var local_position = et.affine_inverse().xform(mb.position)
		if use_snap():
			local_position = snap(local_position)
		FUNC.action_set_pivot(self, "_set_pivot", undo, shape, et, local_position)
		undo_version = undo.get_version()
		return true
	if current_mode == MODE.EDIT_VERT or current_mode == MODE.CREATE_VERT:
		gui_edge_info_panel.visible = false

		# Any nearby control points to move?
		if not Input.is_key_pressed(KEY_ALT):
			if _input_move_control_points(mb, vp_m_pos, grab_threshold):
				return true

			# Highlighting a vert to move or add control points to
			if current_action.is_single_vert_selected():
				if on_width_handle:
					select_width_handle_to_move([current_action.current_point_key()], vp_m_pos)
				elif Input.is_key_pressed(KEY_SHIFT):
					select_control_points_to_move([current_action.current_point_key()], vp_m_pos)
					return true
				else:
					select_vertices_to_move([current_action.current_point_key()], vp_m_pos)
					return true

		# Split the Edge?
		if _input_split_edge(mb, vp_m_pos, t):
			return true

		if not on_edge:
			# Create new point
			if Input.is_key_pressed(KEY_ALT) or current_mode == MODE.CREATE_VERT:
				var local_position = t.affine_inverse().xform(mb.position)
				if use_snap():
					local_position = snap(local_position)
				if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_ALT):
					# Copy shape with a new single point
					var copy = copy_shape(shape)

					copy.set_point_array(SS2D_Point_Array.new())
					copy.clear_all_material_overrides()
					var new_key = FUNC.action_add_point(
						self, "update_overlays", undo, copy, local_position
					)
					select_vertices_to_move([new_key], vp_m_pos)

					_enter_mode(MODE.CREATE_VERT)

					var selection := get_editor_interface().get_selection()
					selection.clear()
					selection.add_node(copy)
				elif Input.is_key_pressed(KEY_ALT):
					var new_key = FUNC.action_add_point(
						self,
						"update_overlays",
						undo,
						shape,
						local_position,
						shape.get_point_index(closest_edge_keys[1])
					)
				else:
					var new_key = FUNC.action_add_point(
						self, "update_overlays", undo, shape, local_position
					)
					select_vertices_to_move([new_key], vp_m_pos)
				undo_version = undo.get_version()
				return true
	elif current_mode == MODE.EDIT_EDGE:
		if gui_edge_info_panel.visible:
			gui_edge_info_panel.visible = false
			return true
		if on_edge:
			# Grab Edge (2 points)
			var offset = shape.get_closest_offset_straight_edge(
				t.affine_inverse().xform(edge_point)
			)
			var edge_point_keys = _get_edge_point_keys_from_offset(offset, true)
			select_vertices_to_move([edge_point_keys[0], edge_point_keys[1]], vp_m_pos)
		return true
	return false


func _input_handle_mouse_wheel(btn: int) -> bool:
	if not shape.can_edit:
		return false
	var key = current_action.current_point_key()
	if Input.is_key_pressed(KEY_SHIFT):
		var width = shape.get_point_width(key)
		var width_step = 0.1
		if btn == BUTTON_WHEEL_DOWN:
			width_step *= -1
		var new_width = width + width_step
		shape.set_point_width(key, new_width)

	else:
		var texture_idx_step = 1
		if btn == BUTTON_WHEEL_DOWN:
			texture_idx_step *= -1

		var tex_idx: int = shape.get_point_texture_index(key) + texture_idx_step
		shape.set_point_texture_index(key, tex_idx)

	shape.set_as_dirty()
	update_overlays()
	_gui_update_info_panels()

	return true


func _input_handle_keyboard_event(event: InputEventKey) -> bool:
	if not shape.can_edit:
		return false
	var kb: InputEventKey = event
	if _is_valid_keyboard_scancode(kb):
		if current_action.is_single_vert_selected():
			if kb.pressed and kb.scancode == KEY_SPACE:
				var key = current_action.current_point_key()
				shape.set_point_texture_flip(key, not shape.get_point_texture_flip(key))
				shape.set_as_dirty()
				shape.update()
				_gui_update_info_panels()

		if kb.pressed and kb.scancode == KEY_ESCAPE:
			# Hide edge_info_panel
			if gui_edge_info_panel.visible:
				gui_edge_info_panel.visible = false

			if current_mode == MODE.CREATE_VERT:
				_enter_mode(MODE.EDIT_VERT)

		if kb.scancode == KEY_CONTROL:
			if kb.pressed and not kb.echo:
				on_edge = false
				current_action = select_verticies([closest_key], ACTION_VERT.NONE)
			else:
				deselect_verts()
			update_overlays()

		if kb.scancode == KEY_ALT:
			update_overlays()

		return true
	return false


func _is_valid_keyboard_scancode(kb: InputEventKey) -> bool:
	match kb.scancode:
		KEY_ESCAPE:
			return true
		KEY_ENTER:
			return true
		KEY_SPACE:
			return true
		KEY_SHIFT:
			return true
		KEY_ALT:
			return true
		KEY_CONTROL:
			return true
	return false


func _input_handle_mouse_button_event(
	event: InputEventMouseButton, et: Transform2D, grab_threshold: float
) -> bool:
	if not shape.can_edit:
		return false
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
		var rslt: bool = false
		var type = current_action.type
		var _in = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_IN
		var _out = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_OUT
		if type == ACTION_VERT.MOVE_VERT:
			FUNC.action_move_verticies(self, "update_overlays", undo, shape, current_action)
			undo_version = undo.get_version()
			rslt = true
		elif _in or _out:
			FUNC.action_move_control_points(
				self, "update_overlays", undo, shape, current_action, _in, _out
			)
			undo_version = undo.get_version()
			rslt = true
		deselect_verts()
		return rslt

	#########################################
	# Mouse Wheel on valid point
	elif mouse_wheel_spun and current_action.is_single_vert_selected():
		return _input_handle_mouse_wheel(mb.button_index)

	#########################################
	# Mouse left click
	elif mb.pressed and mb.button_index == BUTTON_LEFT:
		return _input_handle_left_click(mb, viewport_mouse_position, t, et, grab_threshold)

	#########################################
	# Mouse right click
	elif mb.pressed and mb.button_index == BUTTON_RIGHT:
		return _input_handle_right_click_press(mb.position, grab_threshold)

	return false


func _input_split_edge(mb: InputEventMouseButton, vp_m_pos: Vector2, t: Transform2D) -> bool:
	if not on_edge:
		return false
	var gpoint: Vector2 = mb.position
	var insertion_point: int = -1
	var mb_offset = shape.get_closest_offset(t.affine_inverse().xform(gpoint))

	insertion_point = shape.get_point_index(_get_edge_point_keys_from_offset(mb_offset)[1])

	if insertion_point == -1:
		insertion_point = shape.get_point_count() - 1

	var key = FUNC.action_split_curve(
		self, "update_overlays", undo, shape, insertion_point, gpoint, t
	)
	undo_version = undo.get_version()
	select_vertices_to_move([key], vp_m_pos)
	on_edge = false

	return true


func _input_move_control_points(mb: InputEventMouseButton, vp_m_pos: Vector2, grab_threshold: float) -> bool:
	var points_in = FUNC.get_intersecting_control_point_in(
		shape, get_et(), mb.position, grab_threshold
	)
	var points_out = FUNC.get_intersecting_control_point_out(
		shape, get_et(), mb.position, grab_threshold
	)
	if not points_in.empty():
		select_control_points_to_move([points_in[0]], vp_m_pos, ACTION_VERT.MOVE_CONTROL_IN)
		return true
	elif not points_out.empty():
		select_control_points_to_move([points_out[0]], vp_m_pos, ACTION_VERT.MOVE_CONTROL_OUT)
		return true
	return false


func _get_edge_point_keys_from_offset(offset: float, straight: bool = false):
	for i in range(0, shape.get_point_count() - 1, 1):
		var key = shape.get_point_key_at_index(i)
		var key_next = shape.get_point_key_at_index(i + 1)
		var this_offset = 0
		var next_offset = 0
		if straight:
			this_offset = shape.get_closest_offset_straight_edge(shape.get_point_position(key))
			next_offset = shape.get_closest_offset_straight_edge(shape.get_point_position(key_next))
		else:
			this_offset = shape.get_closest_offset(shape.get_point_position(key))
			next_offset = shape.get_closest_offset(shape.get_point_position(key_next))
		if offset >= this_offset and offset <= next_offset:
			return [key, key_next]
		# for when the shape is closed and the final point has an offset of 0
		if next_offset == 0 and offset >= this_offset:
			return [key, key_next]
	return [-1, -1]


func _input_motion_is_on_edge(mm: InputEventMouseMotion, grab_threshold: float) -> bool:
	var xform: Transform2D = get_et() * shape.get_global_transform()
	if shape.get_point_count() < 2:
		return false

	# Find edge
	var closest_point = null
	if current_mode == MODE.EDIT_EDGE:
		closest_point = shape.get_closest_point_straight_edge(
			xform.affine_inverse().xform(mm.position)
		)
	else:
		closest_point = shape.get_closest_point(xform.affine_inverse().xform(mm.position))
	if closest_point != null:
		edge_point = xform.xform(closest_point)
		if edge_point.distance_to(mm.position) <= grab_threshold:
			return true
	return false


func _input_find_closest_edge_keys(mm: InputEventMouseMotion):
	var xform: Transform2D = get_et() * shape.get_global_transform()
	if shape.get_point_count() < 2:
		return false

	# Find edge
	var closest_point = null

	closest_point = shape.get_closest_point_straight_edge(xform.affine_inverse().xform(mm.position))
	var edge_point = xform.xform(closest_point)
	var offset = shape.get_closest_offset_straight_edge(xform.affine_inverse().xform(edge_point))
	closest_edge_keys = _get_edge_point_keys_from_offset(offset, true)


func get_mouse_over_vert_key(mm: InputEventMouseMotion, grab_threshold: float) -> int:
	var xform: Transform2D = get_et() * shape.get_global_transform()
	# However, if near a control point or one of its handles then we are not on the edge
	for k in shape.get_all_point_keys():
		var pp: Vector2 = shape.get_point_position(k)
		var p: Vector2 = xform.xform(pp)
		if p.distance_to(mm.position) <= grab_threshold:
			return k
	return -1


func get_mouse_over_width_handle(mm: InputEventMouseMotion, grab_threshold: float) -> int:
	var xform: Transform2D = get_et() * shape.get_global_transform()
	for k in shape.get_all_point_keys():
		var pp: Vector2 = shape.get_point_position(k)
		var normal: Vector2 = _get_vert_normal(
			xform, shape.get_vertices(), shape.get_point_index(k)
		)
		var p: Vector2 = xform.xform(pp) + normal * WIDTH_HANDLE_OFFSET
		if p.distance_to(mm.position) <= grab_threshold:
			return k
	return -1


func _input_motion_move_control_points(delta: Vector2, _in: bool, _out: bool) -> bool:
	var rslt = false
	for i in range(0, current_action.keys.size(), 1):
		var key = current_action.keys[i]
		var from = current_action.starting_positions[i]
		var out_multiplier = 1
		# Invert the delta for position_out if moving both at once
		if _out and _in:
			out_multiplier = -1
		var new_position_in = delta + current_action.starting_positions_control_in[i]
		var new_position_out = (
			(delta * out_multiplier)
			+ current_action.starting_positions_control_out[i]
		)
		if use_snap():
			new_position_in = snap(new_position_in)
			new_position_out = snap(new_position_out)
		if _in:
			shape.set_point_in(key, new_position_in)
			rslt = true
		if _out:
			shape.set_point_out(key, new_position_out)
			rslt = true
		shape.set_as_dirty()
		update_overlays()
	return false


func _input_motion_move_verts(delta: Vector2) -> bool:
	for i in range(0, current_action.keys.size(), 1):
		var key = current_action.keys[i]
		var from = current_action.starting_positions[i]
		var new_position = from + delta
		if use_snap():
			new_position = snap(new_position)
		shape.set_point_position(key, new_position)
		update_overlays()
	return true


func _input_motion_move_width_handle(mouse_position: Vector2, scale: Vector2) -> bool:
	for i in range(0, current_action.keys.size(), 1):
		var key = current_action.keys[i]
		var from_width = current_action.starting_width[i]
		var from_position = current_action.starting_positions[i]
		width_scaling = from_position.distance_to(mouse_position) / WIDTH_HANDLE_OFFSET * scale.x
		shape.set_point_width(key, round(from_width * width_scaling * 10) / 10)
		update_overlays()
	return true


func get_closest_vert_to_point(s: SS2D_Shape_Base, p: Vector2) -> int:
	"""
	Will Return index of closest vert to point
	"""
	var gt = shape.get_global_transform()
	var verts = s.get_vertices()
	var transformed_point = gt.affine_inverse() * p
	var idx = -1
	var closest_distance = -1
	for i in verts.size():
		var distance = verts[i].distance_to(transformed_point)
		if distance < closest_distance or closest_distance == -1:
			idx = s.get_point_key_at_index(i)
			closest_distance = distance
	return idx


func _input_handle_mouse_motion_event(
	event: InputEventMouseMotion, et: Transform2D, grab_threshold: float
) -> bool:
	var t: Transform2D = et * shape.get_global_transform()
	var mm: InputEventMouseMotion = event
	var delta_current_pos = et.affine_inverse().xform(mm.position)
	gui_point_info_panel.rect_position = mm.position + Vector2(256, -24)
	var delta = delta_current_pos - _mouse_motion_delta_starting_pos

	closest_key = get_closest_vert_to_point(shape, delta_current_pos)

	if current_mode == MODE.EDIT_VERT or current_mode == MODE.CREATE_VERT:
		var type = current_action.type
		var _in = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_IN
		var _out = type == ACTION_VERT.MOVE_CONTROL or type == ACTION_VERT.MOVE_CONTROL_OUT

		if type == ACTION_VERT.MOVE_VERT:
			return _input_motion_move_verts(delta)
		elif _in or _out:
			return _input_motion_move_control_points(delta, _in, _out)
		elif type == ACTION_VERT.MOVE_WIDTH_HANDLE:
			return _input_motion_move_width_handle(
				et.affine_inverse().xform(mm.position), et.get_scale()
			)
		var mouse_over_key = get_mouse_over_vert_key(event, grab_threshold)
		var mouse_over_width_handle = get_mouse_over_width_handle(event, grab_threshold)

		# Make the closest key grabable while holding down Control
		if (
			Input.is_key_pressed(KEY_CONTROL)
			and not Input.is_key_pressed(KEY_ALT)
			and mouse_over_width_handle == -1
			and mouse_over_key == -1
		):
			mouse_over_key = closest_key

		on_width_handle = false
		if mouse_over_key != -1:
			on_edge = false
			current_action = select_verticies([mouse_over_key], ACTION_VERT.NONE)
		elif mouse_over_width_handle != -1:
			on_edge = false
			on_width_handle = true
			current_action = select_verticies([mouse_over_width_handle], ACTION_VERT.NONE)
		elif Input.is_key_pressed(KEY_ALT):
			_input_find_closest_edge_keys(mm)
		else:
			deselect_verts()
			on_edge = _input_motion_is_on_edge(mm, grab_threshold)

	elif current_mode == MODE.EDIT_EDGE:
		# Don't update if edge panel is visible
		if gui_edge_info_panel.visible:
			return false
		var type = current_action.type
		if type == ACTION_VERT.MOVE_VERT:
			return _input_motion_move_verts(delta)
		else:
			deselect_verts()
		on_edge = _input_motion_is_on_edge(mm, grab_threshold)

	update_overlays()
	return false


func _get_vert_normal(t: Transform2D, verts, i: int):
	var point: Vector2 = t.xform(verts[i])
	var prev_point: Vector2 = t.xform(verts[(i - 1) % verts.size()])
	var next_point: Vector2 = t.xform(verts[(i + 1) % verts.size()])
	return ((prev_point - point).normalized().rotated(PI / 2) + (point - next_point).normalized().rotated(PI / 2)).normalized()


func copy_shape(shape):
	var copy: SS2D_Shape_Base
	if shape is SS2D_Shape_Closed:
		copy = SS2D_Shape_Closed.new()
	if shape is SS2D_Shape_Open:
		copy = SS2D_Shape_Open.new()
	if shape is SS2D_Shape_Meta:
		copy = SS2D_Shape_Meta.new()
	copy.position = shape.position
	copy.scale = shape.scale
	copy.modulate = shape.modulate
	copy.shape_material = shape.shape_material
	copy.editor_debug = shape.editor_debug
	copy.flip_edges = shape.flip_edges
	copy.editor_debug = shape.editor_debug
	copy.collision_size = shape.collision_size
	copy.collision_offset = shape.collision_offset
	copy.tessellation_stages = shape.tessellation_stages
	copy.tessellation_tolerence = shape.tessellation_tolerence
	copy.curve_bake_interval = shape.curve_bake_interval
	copy.material_overrides = shape.material_overrides

	shape.get_parent().add_child(copy)
	copy.set_owner(get_tree().get_edited_scene_root())

	if (
		shape.collision_polygon_node_path != ""
		and shape.has_node(shape.collision_polygon_node_path)
	):
		var collision_polygon_original = shape.get_node(shape.collision_polygon_node_path)
		var collision_polygon_new = CollisionPolygon2D.new()
		collision_polygon_new.visible = collision_polygon_original.visible

		collision_polygon_original.get_parent().add_child(collision_polygon_new)
		collision_polygon_new.set_owner(get_tree().get_edited_scene_root())

		copy.collision_polygon_node_path = copy.get_path_to(collision_polygon_new)

	return copy


func is_shape_closed(shape):
	if shape is SS2D_Shape_Open:
		return false
	if shape is SS2D_Shape_Meta:
		return shape.treat_as_closed()
	return true


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
