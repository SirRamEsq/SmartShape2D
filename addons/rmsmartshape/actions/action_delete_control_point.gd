extends SS2D_Action

## ActionDeleteControlPoint

enum PointType {POINT_IN, POINT_OUT}

const ActionInvertOrientation := preload("res://addons/rmsmartshape/actions/action_invert_orientation.gd")
var _invert_orientation: ActionInvertOrientation

var _shape: SS2D_Shape
var _key: int
var _point_type: PointType
var _old_value: Vector2


func _init(shape: SS2D_Shape, key: int, point_type: PointType) -> void:
	_shape = shape
	_key = key
	_point_type = point_type
	_old_value = shape.get_point_in(key) if _point_type == PointType.POINT_IN else shape.get_point_out(key)
	_invert_orientation = ActionInvertOrientation.new(shape)


func get_name() -> String:
	return "Delete Control Point " + ("In" if _point_type == PointType.POINT_IN else "Out")


func do() -> void:
	_shape.begin_update()
	if _point_type == PointType.POINT_IN:
		_shape.set_point_in(_key, Vector2.ZERO)
	else:
		_shape.set_point_out(_key, Vector2.ZERO)
	_invert_orientation.do()
	_shape.end_update()


func undo() -> void:
	_shape.begin_update()
	_invert_orientation.undo()
	if _point_type == PointType.POINT_IN:
		_shape.set_point_in(_key, _old_value)
	else:
		_shape.set_point_out(_key, _old_value)
	_shape.end_update()
