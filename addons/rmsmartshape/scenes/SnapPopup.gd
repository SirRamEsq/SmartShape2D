@tool
extends PopupPanel

# export (NodePath) var p_snap_offset_x
@export var p_snap_offset_x : NodePath

# export (NodePath) var p_snap_offset_y
@export var p_snap_offset_y : NodePath

# export (NodePath) var p_snap_step_x
@export var p_snap_step_x : NodePath

# export (NodePath) var p_snap_step_y
@export var p_snap_step_y : NodePath


func get_snap_offset() -> Vector2:
	return Vector2(get_node(p_snap_offset_x).value, get_node(p_snap_offset_y).value)


func get_snap_step() -> Vector2:
	return Vector2(get_node(p_snap_step_x).value, get_node(p_snap_step_y).value)
