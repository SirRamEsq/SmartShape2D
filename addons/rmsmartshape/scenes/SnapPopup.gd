@tool
extends Popup
class_name SS2D_SnapPopup

@onready var snap_offset_x: SpinBox = %SnapOffsetX
@onready var snap_offset_y: SpinBox = %SnapOffsetY
@onready var snap_step_x: SpinBox = %SnapStepX
@onready var snap_step_y: SpinBox = %SnapStepY


func get_snap_offset() -> Vector2:
	return Vector2(snap_offset_x.value, snap_offset_y.value)


func get_snap_step() -> Vector2:
	return Vector2(snap_step_x.value, snap_step_y.value)
