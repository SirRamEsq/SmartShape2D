extends SS2D_Action
class_name SS2D_ActionMoveControlPoints

var _shape: SS2D_Shape
var _keys: PackedInt32Array
var _old_points_in: PackedVector2Array
var _old_points_out: PackedVector2Array
var _new_points_in: PackedVector2Array
var _new_points_out: PackedVector2Array


func _init(s: SS2D_Shape, keys: PackedInt32Array,
		old_points_in: PackedVector2Array, old_points_out: PackedVector2Array) -> void:
	_shape = s
	_keys = keys
	_old_points_in = old_points_in
	_old_points_out = old_points_out
	var pa := _shape.get_point_array()
	for key in _keys:
		_new_points_in.append(pa.get_point_in(key))
		_new_points_out.append(pa.get_point_out(key))


func get_name() -> String:
	return "Move Control Point"


func do() -> void:
	_assign_points_in_out(_keys, _new_points_in, _new_points_out)


func undo() -> void:
	_assign_points_in_out(_keys, _old_points_in, _old_points_out)


func _assign_points_in_out(keys: PackedInt32Array, in_positions: PackedVector2Array, out_positions: PackedVector2Array) -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	for i in keys.size():
		if pa.get_point_in(keys[i]) != in_positions[i]:
			pa.set_point_in(keys[i], in_positions[i])
		if pa.get_point_out(keys[i]) != out_positions[i]:
			pa.set_point_out(keys[i], out_positions[i])
	pa.end_update()
