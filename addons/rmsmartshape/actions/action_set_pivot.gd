extends SS2D_Action

## ActionSetPivot

var _shape: SS2D_Shape
var _parent_body: PhysicsBody2D

var _old_shape_pos: Vector2
var _old_body_pos: Vector2

var _new_pos: Vector2


func _init(s: SS2D_Shape, pos: Vector2) -> void:
	_shape = s
	_new_pos = pos
	_old_shape_pos = _shape.global_position
	var parent = _shape.get_parent()
	if parent is PhysicsBody2D:
		_parent_body = parent
		_old_body_pos = parent.global_position


func get_name() -> String:
	return "Set Pivot"


func do() -> void:
	_set_pivot(_new_pos, _new_pos)


func undo() -> void:
	_set_pivot(_old_shape_pos, _old_body_pos)


func _set_pivot(shape_position: Vector2, parent_body_position: Vector2) -> void:
	var xform: Transform2D = _shape.get_global_transform()
	
	if _shape.get_parent() == _parent_body:
		_parent_body.global_position = parent_body_position
	_shape.global_position = shape_position

	_shape.begin_update()
	_shape.disable_constraints()

	for i in _shape.get_point_count():
		var key: int = _shape.get_point_key_at_index(i)
		var point: Vector2 = _shape.get_point_position(key)
		_shape.set_point_position(key, _shape.to_local(xform * point))
		
	_shape.enable_constraints()
	_shape.end_update()

