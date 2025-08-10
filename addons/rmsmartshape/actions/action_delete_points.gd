extends SS2D_Action
class_name SS2D_ActionDeletePoints

var _invert_orientation: SS2D_ActionInvertOrientation
var _close_shape: SS2D_ActionCloseShape

var _shape: SS2D_Shape
var _keys: PackedInt32Array
var _indicies: PackedInt32Array
var _points: Array[SS2D_Point] = []
var _constraints: Array[Dictionary]
var _was_closed: bool
var _commit_update: bool


func _init(shape: SS2D_Shape, keys: PackedInt32Array, commit_update: bool = true) -> void:
	_shape = shape
	_invert_orientation = SS2D_ActionInvertOrientation.new(shape)
	_close_shape = SS2D_ActionCloseShape.new(shape)
	_commit_update = commit_update

	# FIXME?: Why save constraints here but points in do()?
	for k in keys:
		add_point_to_delete(k)


func get_name() -> String:
	return "Delete Points %s" % [_keys]


func do() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	_was_closed = pa.is_shape_closed()
	var first_run := _points.size() == 0
	for k in _keys:
		if first_run:
			_indicies.append(pa.get_point_index(k))
			_points.append(pa.get_point(k))
		pa.remove_point(k)
	if _was_closed:
		_close_shape.do()
	_invert_orientation.do()
	if _commit_update:
		pa.end_update()


func undo() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	_invert_orientation.undo()
	if _was_closed:
		_close_shape.undo()
	for i in range(_keys.size()-1, -1, -1):
		pa.add_point_object(_points[i], _indicies[i], _keys[i])
	# Restore point constraints.
	for i in range(_keys.size()-1, -1, -1):
		for tuple: Vector2i in _constraints[i]:
			pa.set_constraint(tuple[0], tuple[1], _constraints[i][tuple])
	pa.end_update()


func add_point_to_delete(key: int) -> void:
	_keys.push_back(key)
	var constraints := _shape.get_point_array().get_point_constraints(key)
	# Save point constraints.
	_constraints.append(constraints)

	for tuple: Vector2i in constraints:
		var constraint: SS2D_Point_Array.CONSTRAINT = constraints[tuple]
		if constraint == SS2D_Point_Array.CONSTRAINT.NONE:
			continue
		var key_other := SS2D_IndexTuple.get_other_value(tuple, key)
		if constraint & SS2D_Point_Array.CONSTRAINT.ALL:
			if not _keys.has(key_other):
				add_point_to_delete(key_other)
