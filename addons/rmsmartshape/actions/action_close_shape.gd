extends SS2D_Action

## ActionCloseShape

const ActionInvertOrientation := preload("res://addons/rmsmartshape/actions/action_invert_orientation.gd")
var _invert_orientation: ActionInvertOrientation

var _shape: SS2D_Shape
var _key: int
var _performed: bool


func _init(shape: SS2D_Shape) -> void:
	_shape = shape
	_invert_orientation = ActionInvertOrientation.new(shape)


func get_name() -> String:
	return "Close Shape"


func do() -> void:
	var pa := _shape.get_point_array()
	_performed = pa.can_close()
	if _performed:
		pa.begin_update()
		_key = pa.close_shape(_key)
		_invert_orientation.do()
		pa.end_update()


func undo() -> void:
	if _performed:
		var pa := _shape.get_point_array()
		pa.begin_update()
		_invert_orientation.undo()
		pa.remove_point(_key)
		pa.end_update()


func get_key() -> int:
	return _key
