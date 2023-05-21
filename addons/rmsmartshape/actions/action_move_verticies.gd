extends SS2D_Action

## ActionMoveVerticies

const ActionInvertOrientation := preload("res://addons/rmsmartshape/actions/action_invert_orientation.gd")
var _invert_orientation: ActionInvertOrientation

var _shape: SS2D_Shape
var _keys: PackedInt64Array
var _old_positions: PackedVector2Array
var _new_positions: PackedVector2Array


func _init(s: SS2D_Shape, keys: PackedInt64Array, old_positions: PackedVector2Array) -> void:
	_shape = s
	_keys = keys.duplicate()
	_old_positions = old_positions.duplicate()
	_new_positions = PackedVector2Array()
	for k in _keys:
		_new_positions.append(_shape.get_point_position(k))
	_invert_orientation = ActionInvertOrientation.new(_shape)


func get_name() -> String:
	if _keys.size() == 1:
		return "Move Vertex to (%d, %d)" % [_new_positions[0].x, _new_positions[0].y]
	else:
		return "Move Verticies"


func do() -> void:
	_shape.begin_update()
	for i in _keys.size():
		_shape.set_point_position(_keys[i], _new_positions[i])
	_invert_orientation.do()
	_shape.end_update()


func undo() -> void:
	_shape.begin_update()
	_invert_orientation.undo()
	for i in range(_keys.size() - 1, -1, -1):
		_shape.set_point_position(_keys[i], _old_positions[i])
	_shape.end_update()
