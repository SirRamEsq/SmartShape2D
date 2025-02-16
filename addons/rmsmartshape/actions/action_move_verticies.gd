extends SS2D_Action
class_name SS2D_ActionMoveVerticies

var _invert_orientation: SS2D_ActionInvertOrientation
var _shape: SS2D_Shape
var _keys: PackedInt32Array
var _old_positions: PackedVector2Array
var _new_positions: PackedVector2Array


func _init(s: SS2D_Shape, keys: PackedInt32Array, old_positions: PackedVector2Array) -> void:
	_shape = s
	_keys = keys.duplicate()
	_old_positions = old_positions.duplicate()
	_new_positions = PackedVector2Array()
	for k in _keys:
		_new_positions.append(_shape.get_point_array().get_point_position(k))
	_invert_orientation = SS2D_ActionInvertOrientation.new(_shape)


func get_name() -> String:
	if _keys.size() == 1:
		return "Move Vertex to (%d, %d)" % [_new_positions[0].x, _new_positions[0].y]
	else:
		return "Move Verticies"


func do() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	for i in _keys.size():
		pa.set_point_position(_keys[i], _new_positions[i])
	_invert_orientation.do()
	pa.end_update()


func undo() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	_invert_orientation.undo()
	for i in range(_keys.size() - 1, -1, -1):
		pa.set_point_position(_keys[i], _old_positions[i])
	pa.end_update()
