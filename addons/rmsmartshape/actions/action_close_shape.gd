extends SS2D_Action

## ActionCloseShape

var _shape: SS2D_Shape_Base
var _key: int
var _performed: bool


func _init(shape: SS2D_Shape_Base) -> void:
	_shape = shape


func get_name() -> String:
	return "Close Shape"


func do() -> void:
	_performed = _shape.can_close()
	if _performed:
		_key = _shape.close_shape(_key)


func undo() -> void:
	if _performed:
		_shape.remove_point(_key)

