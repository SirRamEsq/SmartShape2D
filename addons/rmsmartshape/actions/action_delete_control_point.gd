extends SS2D_Action
class_name SS2D_ActionDeleteControlPoint

enum PointType {POINT_IN, POINT_OUT}

var _invert_orientation: SS2D_ActionInvertOrientation

var _shape: SS2D_Shape
var _key: int
var _point_type: PointType
var _old_value: Vector2


func _init(shape: SS2D_Shape, key: int, point_type: PointType) -> void:
	_shape = shape
	_key = key
	_point_type = point_type
	var pa := _shape.get_point_array()
	_old_value = pa.get_point_in(key) if _point_type == PointType.POINT_IN else pa.get_point_out(key)
	_invert_orientation = SS2D_ActionInvertOrientation.new(shape)


func get_name() -> String:
	return "Delete Control Point " + ("In" if _point_type == PointType.POINT_IN else "Out")


func do() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	if _point_type == PointType.POINT_IN:
		pa.set_point_in(_key, Vector2.ZERO)
	else:
		pa.set_point_out(_key, Vector2.ZERO)
	_invert_orientation.do()
	pa.end_update()


func undo() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	_invert_orientation.undo()
	if _point_type == PointType.POINT_IN:
		pa.set_point_in(_key, _old_value)
	else:
		pa.set_point_out(_key, _old_value)
	pa.end_update()
