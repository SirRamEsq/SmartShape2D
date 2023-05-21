extends SS2D_Action

## ActionMakeShapeUnique

var _shape: SS2D_Shape
var _old_array: SS2D_Point_Array
var _new_array: SS2D_Point_Array


func _init(shape: SS2D_Shape) -> void:
	_shape = shape
	_old_array = shape.get_point_array()
	_new_array = _shape.get_point_array().clone(true)


func get_name() -> String:
	return "Make Shape Unique"


func do() -> void:
	_shape.set_point_array(_new_array)


func undo() -> void:
	_shape.set_point_array(_old_array)

