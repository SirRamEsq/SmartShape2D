extends "res://addons/rmsmartshape/actions/action_add_point.gd"

## ActionSplitCurve

func _init(shape: SS2D_Shape_Base, idx: int, gpoint: Vector2, xform: Transform2D) -> void:
	super._init(shape, xform.affine_inverse() * gpoint, idx)


func get_name() -> String:
	return "Split Curve at (%d, %d)" % [_position.x, _position.y]
