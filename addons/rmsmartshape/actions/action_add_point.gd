extends SS2D_Action
class_name SS2D_ActionAddPoint

var _invert_orientation: SS2D_ActionInvertOrientation

var _commit_update: bool
var _shape: SS2D_Shape
var _key: int
var _position: Vector2
var _idx: int


func _init(shape: SS2D_Shape, position: Vector2, idx: int = -1, commit_update: bool = true) -> void:
	_shape = shape
	_position = position
	_commit_update = commit_update
	_idx = idx
	_key = _shape.get_point_array().reserve_key()
	_invert_orientation = SS2D_ActionInvertOrientation.new(shape)


func get_name() -> String:
	return "Add Point at (%d, %d)" % [_position.x, _position.y]


func do() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	_key = pa.add_point(_position, _idx, _key)
	_invert_orientation.do()
	if _commit_update:
		pa.end_update()


func undo() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	_invert_orientation.undo()
	pa.remove_point(_key)
	pa.end_update()


func get_key() -> int:
	return _key
