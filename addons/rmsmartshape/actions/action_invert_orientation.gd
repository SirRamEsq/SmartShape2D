extends SS2D_Action

## ActionInvertOrientation

var _shape: SS2D_Shape
var _performed: bool


func _init(shape: SS2D_Shape) -> void:
	_shape = shape


func get_name() -> String:
	return "Invert Orientation"


func do() -> void:
	_performed = should_invert_orientation(_shape)
	if _performed:
		_shape.invert_point_order()


func undo() -> void:
	if _performed:
		_shape.invert_point_order()


func should_invert_orientation(s: SS2D_Shape) -> bool:
	if s == null:
		return false
	if not s.is_shape_closed():
		return false
	return not s.are_points_clockwise() and s.get_point_count() >= 3
