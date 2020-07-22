tool
extends Reference
class_name RMSS2D_Point_Array


class Tuple:
	extends Reference
	var a = null
	var b = null

	func _init(_a, _b):
		a = _a
		b = _b

	func has(value) -> bool:
		return a == value or b == value

	func get_other_value(value):
		if a == value:
			return b
		elif b == value:
			return a
		return null

	func equals(t: Tuple) -> bool:
		return (a == t.a and b == t.b) or (b == t.a and a == t.b)


enum CONSTRAINT { NONE = 0, AXIS_X = 1, AXIS_Y = 2, CONTROL_POINTS = 4, PROPERTIES = 8, ALL = 15 }

# Maps a key to each point
var _points: Dictionary = {}
# Contains all keys; the order of the keys determines the order of the points
var _point_order: Array = []
# Key is tuple of point_keys; Value is the CONSTRAINT enum
var _constraints = {}
# Next key value to generate
var _next_key = 0

signal changed

###################
# HANDLING POINTS #
###################


func __generate_key(next: int) -> int:
	if _points.has(next):
		return __generate_key(next + 1)
	return next


func _generate_key() -> int:
	var next = __generate_key(_next_key)
	_next_key = next + 1
	return next


func add_point(point: Vector2, idx: int = -1) -> int:
	var next_key = _generate_key()
	var new_point = RMSS2D_Point.new(point)
	new_point.connect("changed", self, "_on_point_changed")
	_points[next_key] = new_point
	_point_order.push_back(next_key)
	if idx != -1:
		set_point_index(next_key, idx)
	return next_key


func is_index_in_range(idx: int) -> bool:
	return idx > 0 and idx < _point_order.size()


func get_point_key_at_index(idx: int) -> int:
	return _point_order[idx]

func get_point_at_index(idx: int) -> int:
	return _points[_point_order[idx]].duplicate()

func get_point(key: int) -> int:
	return _points[key].duplicate()

func get_point_count()->int:
	return _point_order.size()


func get_point_index(key: int) -> int:
	if has_point(key):
		var idx = 0
		for k in _point_order:
			if key == k:
				break
			idx += 1
		return idx
	return -1

func invert_point_order():
	_point_order.invert()

func set_point_index(key: int, idx: int):
	if not has_point(key):
		return
	var old_idx = get_point_index(key)
	if idx < 0 or idx >= _points.size():
		idx = _points.size() - 1
	if idx == old_idx:
		return
	_point_order.remove(old_idx)
	_point_order.insert(idx, key)


func has_point(key: int) -> bool:
	return _points.has(key)


func get_all_point_keys() -> Array:
	"""
	_point_order should contain every single point ONLY ONCE
	"""
	return _point_order.duplicate()


func remove_point(key: int) -> bool:
	if has_point(key):
		var p = _points[key]
		if p.is_connected("changed", self, "_on_point_changed"):
			p.disconnect("changed", self, "_on_point_changed")
		_point_order.remove(get_point_index(key))
		_points.erase(key)
		return true
	return false


func clear():
	_points.clear()
	_point_order.clear()
	_constraints.clear()
	_next_key = 0
	emit_signal("changed")


func set_point_in(key: int, value: Vector2):
	if has_point(key):
		_points[key].point_in = value


func get_point_in(key: int) -> Vector2:
	if has_point(key):
		return _points[key].point_in
	return Vector2(0, 0)


func set_point_out(key: int, value: Vector2):
	if has_point(key):
		_points[key].point_out = value


func get_point_out(key: int) -> Vector2:
	if has_point(key):
		return _points[key].point_out
	return Vector2(0, 0)


func set_point_position(key: int, value: Vector2):
	if has_point(key):
		_points[key].position = value


func get_point_position(key: int) -> Vector2:
	if has_point(key):
		return _points[key].position
	return Vector2(0, 0)


func set_point_properties(key: int, value: RMS2D_VertexProperties):
	if has_point(key):
		_points[key].properties = value


func get_point_properties(key: int) -> RMS2D_VertexProperties:
	if has_point(key):
		return _points[key].properties.duplicate()
	return RMS2D_VertexProperties.new()


func get_key_from_point(p: RMSS2D_Point) -> int:
	for k in _points:
		if p == _points[k]:
			return k
	return -1


func _on_point_changed(p: RMSS2D_Point):
	var key = get_key_from_point(p)
	if _updating_constraints:
		_keys_to_update_constraints.push_back(key)
	else:
		update_constraints(key)


###############
# CONSTRAINTS #
###############

var _updating_constraints = false
var _keys_to_update_constraints = []


func _update_constraints(src: int):
	var constraints = get_constraints(src)
	for tuple in constraints:
		var constraint = constraints[tuple]
		if constraint == CONSTRAINT.NONE:
			continue
		var dst = tuple.get_other_value(src)
		if constraint & CONSTRAINT.AXIS_X:
			set_point_position(dst, Vector2(get_point_position(src).x, get_point_position(dst).y))
		if constraint & CONSTRAINT.AXIS_Y:
			set_point_position(dst, Vector2(get_point_position(dst).x, get_point_position(src).y))
		if constraint & CONSTRAINT.CONTROL_POINTS:
			set_point_in(dst, get_point_in(src))
			set_point_out(dst, get_point_out(src))
		if constraint & CONSTRAINT.PROPERTIES:
			set_point_properties(dst, get_point_properties(src))


func update_constraints(src: int):
	"""
	Will mutate points based on constraints
	values from Passed key will be used to update constrained points
	"""
	if not has_point(src) or _updating_constraints:
		return
	_updating_constraints = true
	# Initial pass of updating constraints
	_update_constraints(src)

	# Subsequent required passes of updating constraints
	while not _keys_to_update_constraints.empty():
		var key_set = _keys_to_update_constraints.duplicate()
		_keys_to_update_constraints.clear()
		for k in key_set:
			_update_constraints(k)

	_updating_constraints = false
	emit_signal("changed")


func get_constraints(key1: int) -> Dictionary:
	"""
	Will Return all constraints for a given key
	"""
	var constraints = {}
	for tuple in _constraints:
		if tuple.has(key1):
			constraints[tuple] = _constraints[tuple]
	return constraints


func get_constraint(key1: int, key2: int) -> int:
	"""
	Will Return the constraint for a pair of keys
	"""
	var t = Tuple.new(key1, key2)
	var t_index = _find_tuple_in_array(_constraints.keys(), t)
	if t_index == -1:
		return CONSTRAINT.NONE
	return _constraints[t_index]


func set_constraint(key1: int, key2: int, constraint: int):
	var t = Tuple.new(key1, key2)
	var existing_tuples = _constraints.keys()
	var existing_t_index = _find_tuple_in_array(existing_tuples, t)
	if existing_t_index != -1:
		t = existing_tuples[existing_t_index]
	_constraints[t] = constraint
	if _constraints[t] == CONSTRAINT.NONE:
		_constraints.erase(t)
	else:
		update_constraints(key1)


########
# MISC #
########
func _find_tuple_in_array(a: Array, t: Tuple) -> int:
	for i in range(a.size()):
		var e = a[i]
		if e.equals(t):
			return i
	return -1

func debug_print():
	for k in get_all_point_keys():
		var pos = get_point_position(k)
		var _in = get_point_in(k)
		var out = get_point_out(k)
		print("%s = P:%s | I:%s | O:%s" % [k, pos, _in, out])
