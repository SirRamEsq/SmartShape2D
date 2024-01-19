extends SS2D_Action

## ActionSetPivot

var _shape: SS2D_Shape

var _new_pos: Vector2
var _old_pos: Vector2


func _init(s: SS2D_Shape, pos: Vector2) -> void:
	_shape = s
	_new_pos = pos
	_old_pos = _shape.global_position


func get_name() -> String:
	return "Set Pivot"


func do() -> void:
	_set_pivot(_new_pos)


func undo() -> void:
	_set_pivot(_old_pos)


func _set_pivot(shape_position: Vector2) -> void:
	var shape_gt: Transform2D = _shape.get_global_transform()

	_shape.global_position = shape_position

	_shape.begin_update()
	_shape.disable_constraints()

	for i in _shape.get_point_count():
		var key: int = _shape.get_point_key_at_index(i)
		var point: Vector2 = _shape.get_point_position(key)
		_shape.set_point_position(key, _shape.to_local(shape_gt * point))

	_shape.enable_constraints()
	_shape.end_update()

