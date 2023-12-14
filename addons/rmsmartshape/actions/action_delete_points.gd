extends SS2D_Action

## ActionDeletePoints

const TUP := preload("res://addons/rmsmartshape/lib/tuple.gd")

const ActionInvertOrientation := preload("res://addons/rmsmartshape/actions/action_invert_orientation.gd")
var _invert_orientation: ActionInvertOrientation

const ActionCloseShape := preload("res://addons/rmsmartshape/actions/action_close_shape.gd")
var _close_shape: ActionCloseShape

var _shape: SS2D_Shape
var _keys: PackedInt64Array
var _indicies: PackedInt64Array
var _positions: PackedVector2Array
var _points_in: PackedVector2Array
var _points_out: PackedVector2Array
var _properties: Array[SS2D_VertexProperties]
var _constraints: Array[Dictionary]
var _was_closed: bool
var _commit_update: bool


func _init(shape: SS2D_Shape, keys: PackedInt64Array, commit_update: bool = true) -> void:
	_shape = shape
	_invert_orientation = ActionInvertOrientation.new(shape)
	_close_shape = ActionCloseShape.new(shape)
	_commit_update = commit_update

	for k in keys:
		add_point_to_delete(k)


func get_name() -> String:
	var pos := _shape.get_point_position(_keys[0])
	return "Delete Points %s" % [_keys]


func do() -> void:
	_shape.begin_update()
	_was_closed = _shape.is_shape_closed()
	var first_run := _positions.size() == 0
	for k in _keys:
		if first_run:
			_indicies.append(_shape.get_point_index(k))
			_positions.append(_shape.get_point_position(k))
			_points_in.append(_shape.get_point_in(k))
			_points_out.append(_shape.get_point_out(k))
			_properties.append(_shape.get_point_properties(k))
		_shape.remove_point(k)
	if _was_closed:
		_close_shape.do()
	_invert_orientation.do()
	if _commit_update:
		_shape.end_update()


func undo() -> void:
	_shape.begin_update()
	_invert_orientation.undo()
	if _was_closed:
		_close_shape.undo()
	for i in range(_keys.size()-1, -1, -1):
		_shape.add_point(_positions[i], _indicies[i], _keys[i])
		_shape.set_point_in(_keys[i], _points_in[i])
		_shape.set_point_out(_keys[i], _points_out[i])
		_shape.set_point_properties(_keys[i], _properties[i])
	# Restore point constraints.
	for i in range(_keys.size()-1, -1, -1):
		for tuple in _constraints[i]:
			_shape.set_constraint(tuple[0], tuple[1], _constraints[i][tuple])
	_shape.end_update()


func add_point_to_delete(key: int) -> void:
	_keys.push_back(key)
	var constraints: Dictionary = _shape.get_point_constraints(key)
	# Save point constraints.
	_constraints.append(_shape.get_point_constraints(key))
	for tuple in constraints:
		var constraint: SS2D_Point_Array.CONSTRAINT = constraints[tuple]
		if constraint == SS2D_Point_Array.CONSTRAINT.NONE:
			continue
		var key_other: int = TUP.get_other_value_from_tuple(tuple, key)
		if constraint & SS2D_Point_Array.CONSTRAINT.ALL:
			if not _keys.has(key_other):
				add_point_to_delete(key_other)