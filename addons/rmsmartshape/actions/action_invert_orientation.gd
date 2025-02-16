extends SS2D_Action
class_name SS2D_ActionInvertOrientation

var _shape: SS2D_Shape
var _performed: bool


func _init(shape: SS2D_Shape) -> void:
	_shape = shape


func get_name() -> String:
	return "Invert Orientation"


func do() -> void:
	_performed = should_invert_orientation(_shape)
	if _performed:
		_shape.get_point_array().invert_point_order()


func undo() -> void:
	if _performed:
		_shape.get_point_array().invert_point_order()


func should_invert_orientation(s: SS2D_Shape) -> bool:
	if s == null:
		return false

	var pa := s.get_point_array()
	if not pa.is_shape_closed():
		return false
	return not pa.are_points_clockwise() and pa.get_point_count() >= 3
