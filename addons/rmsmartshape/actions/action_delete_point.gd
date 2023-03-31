extends SS2D_Action

## ActionDeletePoint

const TUP := preload("res://addons/rmsmartshape/lib/tuple.gd")

const ActionInvertOrientation := preload("res://addons/rmsmartshape/actions/action_invert_orientation.gd")
var _invert_orientation: ActionInvertOrientation

const ActionCloseShape := preload("res://addons/rmsmartshape/actions/action_close_shape.gd")
var _close_shape: ActionCloseShape

var _shape: SS2D_Shape_Base
var _keys: PackedInt64Array
var _indicies: PackedInt64Array
var _positions: PackedVector2Array
var _points_in: PackedVector2Array
var _points_out: PackedVector2Array
var _properties: Array[SS2D_VertexProperties]
var _constraints: Dictionary


func _init(shape: SS2D_Shape_Base, key: int) -> void:
	_shape = shape
	_invert_orientation = ActionInvertOrientation.new(shape)
	_close_shape = ActionCloseShape.new(shape)

	get_constrained_points_to_delete(shape, key, _keys)
	# Save point constraints.
	_constraints = _shape.get_point_constraints(key)


func get_name() -> String:
	var pos := _shape.get_point_position(_keys[0])
	return "Delete Point at (%d, %d)" % [pos.x, pos.y]


func do() -> void:
	_shape.begin_update()
	var first_run := _positions.size() == 0
	for k in _keys:
		if first_run:
			_indicies.append(_shape.get_point_index(k))
			_positions.append(_shape.get_point_position(k))
			_points_in.append(_shape.get_point_in(k))
			_points_out.append(_shape.get_point_out(k))
			_properties.append(_shape.get_point_properties(k))
		_shape.remove_point(k)
	_close_shape.do()
	_invert_orientation.do()
	_shape.end_update()


func undo() -> void:
	_shape.begin_update()
	_invert_orientation.undo()
	_close_shape.undo()
	for i in range(_keys.size()-1, -1, -1):
		_shape.add_point(_positions[i], _indicies[i], _keys[i])
		_shape.set_point_in(_keys[i], _points_in[i])
		_shape.set_point_out(_keys[i], _points_out[i])
		_shape.set_point_properties(_keys[i], _properties[i])
	# Restore point constraints.
	for tuple in _constraints:
		_shape.set_constraint(tuple[0], tuple[1], _constraints[tuple])
	_shape.end_update()


func get_constrained_points_to_delete(s: SS2D_Shape_Base, k: int, keys: PackedInt64Array = []) -> PackedInt64Array:
	keys.push_back(k)
	var constraints: Dictionary = s.get_point_constraints(k)
	for tuple in constraints:
		var constraint: SS2D_Point_Array.CONSTRAINT = constraints[tuple]
		if constraint == SS2D_Point_Array.CONSTRAINT.NONE:
			continue
		var k2: int = TUP.get_other_value_from_tuple(tuple, k)
		if constraint & SS2D_Point_Array.CONSTRAINT.ALL:
			if not keys.has(k2):
				get_constrained_points_to_delete(s, k2, keys)
	return keys
