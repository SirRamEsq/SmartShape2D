extends "res://addons/rmsmartshape/actions/action_delete_points.gd"

## ActionDeletePoint


func _init(shape: SS2D_Shape, key: int, commit_update: bool = true) -> void:
	var keys: PackedInt32Array = [key]
	super(shape, keys, commit_update)


func get_name() -> String:
	var pos := _shape.get_point_position(_keys[0])
	return "Delete Point at (%d, %d)" % [pos.x, pos.y]
