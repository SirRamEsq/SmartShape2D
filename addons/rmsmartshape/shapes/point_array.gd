tool
extends Resource
class_name SS2D_Point_Array

const TUP = preload("../lib/tuple.gd")

enum CONSTRAINT { NONE = 0, AXIS_X = 1, AXIS_Y = 2, CONTROL_POINTS = 4, PROPERTIES = 8, ALL = 15 }

# Maps a key to each point
export var _points: Dictionary = {} setget set_points
# Contains all keys; the order of the keys determines the order of the points
export var _point_order: Array = [] setget set_point_order
# Key is tuple of point_keys; Value is the CONSTRAINT enum
export var _constraints = {} setget set_constraints
# Next key value to generate
export var _next_key = 0 setget set_next_key
# Dictionary of specific materials to use for specific tuples of points
# Key is tuple of two point keys
# Value is material
export (Dictionary) var _material_overrides = null setget set_material_overrides

var _constraints_enabled: bool = true

signal constraint_removed(key1, key2)
signal material_override_changed(tuple)

###################
# HANDLING POINTS #
###################


func _init():
	# Required by Godot to correctly make unique instances of this resource
	_points = {}
	_point_order = []
	_constraints = {}
	_next_key = 0
	# Assigning an empty dict to _material_overrides this way
	# instead of assigning in the declaration appears to bypass
	# a weird Godot bug where _material_overrides of one shape
	# interfere with another
	if _material_overrides == null:
		_material_overrides = {}

func _ready():
	for tuple in _material_overrides:
		var mat = _material_overrides[tuple]
		if not mat.is_connected("changed", self, "_on_material_override_changed"):
			mat.connect("changed", self, "_on_material_override_changed", [tuple])


func set_points(ps: Dictionary):
	# Called by Godot when loading from a saved scene
	for k in ps:
		var p = ps[k]
		p.connect("changed", self, "_on_point_changed", [p])
	_points = ps
	property_list_changed_notify()


func set_point_order(po: Array):
	_point_order = po
	property_list_changed_notify()


func set_constraints(cs: Dictionary):
	_constraints = cs
	property_list_changed_notify()


func set_next_key(i: int):
	_next_key = i
	property_list_changed_notify()


func __generate_key(next: int) -> int:
	if not is_key_valid(next):
		return __generate_key(max(next + 1, 0))
	return next


func _generate_key() -> int:
	var next = __generate_key(_next_key)
	_next_key = next + 1
	return next


func get_next_key() -> int:
	"""
	Will return the next key that will be used when adding a point
	"""
	return __generate_key(_next_key)


func is_key_valid(k: int) -> bool:
	if k < 0:
		return false
	if _points.has(k):
		return false
	return true


func add_point(point: Vector2, idx: int = -1, use_key: int = -1) -> int:
	var next_key = use_key
	if next_key == -1 or not is_key_valid(next_key):
		next_key = _generate_key()
	var new_point = SS2D_Point.new(point)
	new_point.connect("changed", self, "_on_point_changed", [new_point])
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
	return _points[_point_order[idx]].duplicate(true)


func get_point(key: int) -> int:
	return _points[key].duplicate(true)


func set_point(key: int, value: SS2D_Point):
	if has_point(key):
		_points[key] = value.duplicate(true)


func get_point_count() -> int:
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
	return _point_order.duplicate(true)


func remove_point(key: int) -> bool:
	if has_point(key):
		remove_constraints(key)
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


func set_point_properties(key: int, value: SS2D_VertexProperties):
	if has_point(key):
		_points[key].properties = value


func get_point_properties(key: int) -> SS2D_VertexProperties:
	if has_point(key):
		return _points[key].properties.duplicate(true)
	var new_props = SS2D_VertexProperties.new()
	return new_props


func get_key_from_point(p: SS2D_Point) -> int:
	for k in _points:
		if p == _points[k]:
			return k
	return -1


func _on_point_changed(p: SS2D_Point):
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


func disable_constraints():
	_constraints_enabled = false


func enable_constraints():
	_constraints_enabled = true


func _update_constraints(src: int):
	if not _constraints_enabled:
		return
	var constraints = get_point_constraints(src)
	for tuple in constraints:
		var constraint = constraints[tuple]
		if constraint == CONSTRAINT.NONE:
			continue
		var dst = TUP.get_other_value_from_tuple(tuple, src)
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
		var key_set = _keys_to_update_constraints.duplicate(true)
		_keys_to_update_constraints.clear()
		for k in key_set:
			_update_constraints(k)

	_updating_constraints = false
	emit_signal("changed")


func get_point_constraints(key1: int) -> Dictionary:
	"""
	Will Return all constraints for a given key
	"""
	var constraints = {}
	for tuple in _constraints:
		if tuple.has(key1):
			constraints[tuple] = _constraints[tuple]
	return constraints


func get_point_constraint(key1: int, key2: int) -> int:
	"""
	Will Return the constraint for a pair of keys
	"""
	var t = TUP.create_tuple(key1, key2)
	var keys = _constraints.keys()
	var t_index = TUP.find_tuple_in_array_of_tuples(keys, t)
	if t_index == -1:
		return CONSTRAINT.NONE
	var t_key = keys[t_index]
	return _constraints[t_key]


func set_constraint(key1: int, key2: int, constraint: int):
	var t = TUP.create_tuple(key1, key2)
	var existing_tuples = _constraints.keys()
	var existing_t_index = TUP.find_tuple_in_array_of_tuples(existing_tuples, t)
	if existing_t_index != -1:
		t = existing_tuples[existing_t_index]
	_constraints[t] = constraint
	if _constraints[t] == CONSTRAINT.NONE:
		_constraints.erase(t)
		emit_signal("constraint_removed", key1, key2)
	else:
		update_constraints(key1)


func remove_constraints(key1: int):
	var constraints = get_point_constraints(key1)
	for tuple in constraints:
		var constraint = constraints[tuple]
		var key2 = TUP.get_other_value_from_tuple(tuple, key1)
		set_constraint(key1, key2, CONSTRAINT.NONE)


func remove_constraint(key1: int, key2: int):
	set_constraint(key1, key2, CONSTRAINT.NONE)


func get_all_constraints_of_type(type: int) -> int:
	var constraints = []
	for t in _constraints:
		var c = _constraints[t]
		if c == type:
			constraints.push_back(t)
	return constraints


########
# MISC #
########
func debug_print():
	for k in get_all_point_keys():
		var pos = get_point_position(k)
		var _in = get_point_in(k)
		var out = get_point_out(k)
		print("%s = P:%s | I:%s | O:%s" % [k, pos, _in, out])


func duplicate(sub_resource: bool = false):
	var _new = __new()
	_new._next_key = _next_key
	if sub_resource:
		var new_point_dict = {}
		for k in _points:
			new_point_dict[k] = _points[k].duplicate(true)
		_new._points = new_point_dict
		_new._point_order = _point_order.duplicate(true)

		_new._constraints = {}
		for tuple in _constraints:
			_new._constraints[tuple] = _constraints[tuple]

		_new._material_overrides = {}
		for tuple in _material_overrides:
			_new._material_overrides[tuple] = _material_overrides[tuple]
	else:
		_new._points = _points
		_new._point_order = _point_order
		_new._constraints = _constraints
		_new._material_overrides = _material_overrides
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()


######################
# MATERIAL OVERRIDES #
######################
func set_material_overrides(dict:Dictionary):
	for k in dict:
		if not TUP.is_tuple(k):
			push_error("Material Override Dictionary KEY is not an Array with 2 points!")
		var v = dict[k]
		if not v is SS2D_Material_Edge_Metadata:
			push_error("Material Override Dictionary VALUE is not SS2D_Material_Edge_Metadata!")

	if _material_overrides != null:
		for old in _material_overrides.values():
			if old.is_connected("changed", self, "_on_material_override_changed"):
				old.disconnect("changed", self, "_on_material_override_changed")

	_material_overrides = dict
	for tuple in _material_overrides:
		var m = _material_overrides[tuple]
		m.connect("changed", self, "_on_material_override_changed", [tuple])

func get_material_override_tuple(tuple: Array) -> Array:
	var keys = _material_overrides.keys()
	var idx = TUP.find_tuple_in_array_of_tuples(keys, tuple)
	if idx != -1:
		tuple = keys[idx]
	return tuple


func has_material_override(tuple: Array) -> bool:
	tuple = get_material_override_tuple(tuple)
	return _material_overrides.has(tuple)


func remove_material_override(tuple: Array):
	if not has_material_override(tuple):
		return
	var old = get_material_override(tuple)
	if old.is_connected("changed", self, "_on_material_override_changed"):
		old.disconnect("changed", self, "_on_material_override_changed")
	_material_overrides.erase(get_material_override_tuple(tuple))
	_on_material_override_changed(tuple)


func set_material_override(tuple: Array, mat: SS2D_Material_Edge_Metadata):
	if has_material_override(tuple):
		var old = get_material_override(tuple)
		if old == mat:
			return
		else:
			if old.is_connected("changed", self, "_on_material_override_changed"):
				old.disconnect("changed", self, "_on_material_override_changed")
	if not mat.is_connected("changed", self, "_on_material_override_changed"):
		mat.connect("changed", self, "_on_material_override_changed", [tuple])
	_material_overrides[get_material_override_tuple(tuple)] = mat
	_on_material_override_changed(tuple)


func get_material_override(tuple: Array) -> SS2D_Material_Edge_Metadata:
	if not has_material_override(tuple):
		return null
	return _material_overrides[get_material_override_tuple(tuple)]

func get_material_overrides():
	return _material_overrides


func clear_all_material_overrides():
	_material_overrides = {}

func _on_material_override_changed(tuple):
	emit_signal("material_override_changed", tuple)
