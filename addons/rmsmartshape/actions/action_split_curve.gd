extends SS2D_ActionAddPoint
class_name SS2D_ActionSplitCurve

func _init(shape: SS2D_Shape, idx: int, gpoint: Vector2, xform: Transform2D, commit_update: bool = true) -> void:
	super._init(shape, xform.affine_inverse() * gpoint, idx, commit_update)


func get_name() -> String:
	return "Split Curve at (%d, %d)" % [_position.x, _position.y]
