@tool
extends Resource
class_name SS2D_Point_Array

const TUP = preload("../lib/tuple.gd")

enum CONSTRAINT { NONE = 0, AXIS_X = 1, AXIS_Y = 2, CONTROL_POINTS = 4, PROPERTIES = 8, ALL = 15 }

# Maps a key to each point: Dict[int, SS2D_Point]
@export var _points: Dictionary = {} : set = set_points
# Contains all keys; the order of the keys determines the order of the points
@export var _point_order: Array[int] = [] : set = set_point_order
# Key is tuple of point_keys; Value is the CONSTRAINT enum
@export var _constraints: Dictionary = {} : set = _set_constraints
# Next key value to generate
@export var _next_key: int = 0 : set = set_next_key
# Dictionary of specific materials to use for specific tuples of points
# Key is tuple of two point keys
# Value is material
@export var _material_overrides: Dictionary = {} : set = set_material_overrides

var _constraints_enabled: bool = true
var _dirty := false
var _updating := false

signal constraint_removed(key1, key2)
signal material_override_changed(tuple)

###################
# HANDLING POINTS #
###################


func _init() -> void:
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


func clone(deep: bool = false) -> SS2D_Point_Array:
	var copy := SS2D_Point_Array.new()
	copy._next_key = _next_key
	if deep:
		var new_point_dict := {}
		for k in _points:
			new_point_dict[k] = _points[k].duplicate(true)
		copy._points = new_point_dict
		copy._point_order = _point_order.duplicate(true)

		copy._constraints = {}
		for tuple in _constraints:
			copy._constraints[tuple] = _constraints[tuple]

		copy._material_overrides = {}
		for tuple in _material_overrides:
			copy._material_overrides[tuple] = _material_overrides[tuple]
	else:
		copy._points = _points
		copy._point_order = _point_order
		copy._constraints = _constraints
		copy._material_overrides = _material_overrides
	return copy


func set_points(ps: Dictionary) -> void:
	# Called by Godot when loading from a saved scene
	for k in ps:
		var p: SS2D_Point = ps[k]
		p.connect("changed", self._on_point_changed.bind(p))
	_points = ps
	notify_property_list_changed()


func set_point_order(po: Array[int]) -> void:
	_point_order = po
	notify_property_list_changed()


func _set_constraints(cs: Dictionary) -> void:
	_constraints = cs

	# Fix for Backwards Compatibility with Godot 3.x
	if Engine.is_editor_hint():
		for tuple in _constraints:
			if not tuple is Array:
				push_error("Constraints Dictionary should have the following structure: key is a tuple of point_keys and value is the CONSTRAINT enum")
			elif tuple.get_typed_builtin() != TYPE_INT:
				# Try to convert
				var new_tuple: Array[int] = []
				new_tuple.assign(tuple)
				var constraint: CONSTRAINT = _constraints[tuple]
				_constraints.erase(tuple)
				_constraints[new_tuple] = constraint

	notify_property_list_changed()


func set_next_key(i: int) -> void:
	_next_key = i
	notify_property_list_changed()


func __generate_key(next: int) -> int:
	if not is_key_valid(next):
		return __generate_key(maxi(next + 1, 0))
	return next


func reserve_key() -> int:
	var next: int = __generate_key(_next_key)
	_next_key = next + 1
	return next


## Will return the next key that will be used when adding a point.
func get_next_key() -> int:
	return __generate_key(_next_key)


func is_key_valid(k: int) -> bool:
	if k < 0:
		return false
	if _points.has(k):
		return false
	return true


func add_point(point: Vector2, idx: int = -1, use_key: int = -1) -> int:
#	print("Add Point  ::  ", point, " | idx: ", idx, " | key: ", use_key, " |")
	if use_key == -1 or not is_key_valid(use_key):
		use_key = reserve_key()
	if use_key == _next_key:
		_next_key += 1
	var new_point := SS2D_Point.new(point)
	new_point.connect(&"changed", self._on_point_changed.bind(new_point))
	_points[use_key] = new_point
	_point_order.push_back(use_key)
	if idx != -1:
		set_point_index(use_key, idx)
	_changed()
	return use_key


func is_index_in_range(idx: int) -> bool:
	return idx > 0 and idx < _point_order.size()


func get_point_key_at_index(idx: int) -> int:
	return _point_order[idx]


func get_point_at_index(idx: int) -> SS2D_Point:
	return _points[_point_order[idx]].duplicate(true)


func get_point(key: int) -> SS2D_Point:
	return _points[key].duplicate(true)


func set_point(key: int, value: SS2D_Point) -> void:
	if has_point(key):
		_points[key] = value.duplicate(true)
		_changed()


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


func invert_point_order() -> void:
	# Postpone `changed` and disable constraints.
	var was_updating: bool = _updating
	_updating = true
	disable_constraints()

	_point_order.reverse()
	# Swap Bezier points.
	for p in _points.values():
		if p.point_out != p.point_in:
			var tmp: Vector2 = p.point_out
			p.point_out = p.point_in
			p.point_in = tmp

	# Re-enable contraits and emit `changed`.
	enable_constraints()
	_updating = was_updating
	_changed()


func set_point_index(key: int, idx: int) -> void:
	if not has_point(key):
		return
	var old_idx: int = get_point_index(key)
	if idx < 0 or idx >= _points.size():
		idx = _points.size() - 1
	if idx == old_idx:
		return
	_point_order.remove_at(old_idx)
	_point_order.insert(idx, key)
	_changed()


func has_point(key: int) -> bool:
	return _points.has(key)


func get_all_point_keys() -> Array[int]:
	# _point_order should contain every single point ONLY ONCE
	return _point_order.duplicate(true)


func remove_point(key: int) -> bool:
	if has_point(key):
#		print("Remove Point  ::  ", get_point_position(key), " | idx: ", get_point_index(key), " | key: ", key, " |")
		remove_constraints(key)
		var p: SS2D_Point = _points[key]
		if p.is_connected("changed", self._on_point_changed):
			p.disconnect("changed", self._on_point_changed)
		_point_order.remove_at(get_point_index(key))
		_points.erase(key)
		_changed()
		return true
	return false


func clear() -> void:
	_points.clear()
	_point_order.clear()
	_constraints.clear()
	_next_key = 0
	_changed()


func set_point_in(key: int, value: Vector2) -> void:
	if has_point(key):
		_points[key].point_in = value
		_changed()


func get_point_in(key: int) -> Vector2:
	if has_point(key):
		return _points[key].point_in
	return Vector2(0, 0)


func set_point_out(key: int, value: Vector2) -> void:
	if has_point(key):
		_points[key].point_out = value
		_changed()


func get_point_out(key: int) -> Vector2:
	if has_point(key):
		return _points[key].point_out
	return Vector2(0, 0)


func set_point_position(key: int, value: Vector2) -> void:
	if has_point(key):
		_points[key].position = value
		_changed()


func get_point_position(key: int) -> Vector2:
	if has_point(key):
		return _points[key].position
	return Vector2(0, 0)


func set_point_properties(key: int, value: SS2D_VertexProperties) -> void:
	if has_point(key):
		_points[key].properties = value
		_changed()


func get_point_properties(key: int) -> SS2D_VertexProperties:
	if has_point(key):
		return _points[key].properties.duplicate(true)
	var new_props := SS2D_VertexProperties.new()
	return new_props


func get_key_from_point(p: SS2D_Point) -> int:
	for k in _points:
		if p == _points[k]:
			return k
	return -1


func _on_point_changed(p: SS2D_Point) -> void:
	var key: int = get_key_from_point(p)
	if _updating_constraints:
		_keys_to_update_constraints.push_back(key)
	else:
		update_constraints(key)


func begin_update() -> void:
	_updating = true


func end_update() -> bool:
	var was_dirty := _dirty
	_updating = false
	_dirty = false
	if was_dirty:
		emit_changed()
	return was_dirty


func is_updating() -> bool:
	return _updating


func _changed() -> void:
	if _updating:
		_dirty = true
	else:
		emit_changed()

###############
# CONSTRAINTS #
###############

var _updating_constraints := false
var _keys_to_update_constraints: Array[int] = []


func disable_constraints() -> void:
	_constraints_enabled = false


func enable_constraints() -> void:
	_constraints_enabled = true


func _update_constraints(src: int) -> void:
	if not _constraints_enabled:
		return
	var constraints: Dictionary = get_point_constraints(src)
	for tuple in constraints:
		var constraint: CONSTRAINT = constraints[tuple]
		if constraint == CONSTRAINT.NONE:
			continue
		var dst: int = TUP.get_other_value_from_tuple(tuple, src)
		if constraint & CONSTRAINT.AXIS_X:
			set_point_position(dst, Vector2(get_point_position(src).x, get_point_position(dst).y))
		if constraint & CONSTRAINT.AXIS_Y:
			set_point_position(dst, Vector2(get_point_position(dst).x, get_point_position(src).y))
		if constraint & CONSTRAINT.CONTROL_POINTS:
			set_point_in(dst, get_point_in(src))
			set_point_out(dst, get_point_out(src))
		if constraint & CONSTRAINT.PROPERTIES:
			set_point_properties(dst, get_point_properties(src))


## Will mutate points based on constraints.[br]
## Values from Passed key will be used to update constrained points.[br]
func update_constraints(src: int) -> void:
	if not has_point(src) or _updating_constraints:
		return
	_updating_constraints = true
	# Initial pass of updating constraints
	_update_constraints(src)

	# Subsequent required passes of updating constraints
	while not _keys_to_update_constraints.is_empty():
		var key_set = _keys_to_update_constraints.duplicate(true)
		_keys_to_update_constraints.clear()
		for k in key_set:
			_update_constraints(k)

	_updating_constraints = false
	_changed()


## Will Return all constraints for a given key.
func get_point_constraints(key1: int) -> Dictionary:
	var constraints := {}
	for tuple in _constraints:
		if tuple.has(key1):
			constraints[tuple] = _constraints[tuple]
	return constraints


## Will Return the constraint for a pair of keys.
func get_point_constraint(key1: int, key2: int) -> CONSTRAINT:
	var t := TUP.create_tuple(key1, key2)
	var keys: Array = _constraints.keys()
	var t_index: int = TUP.find_tuple_in_array_of_tuples(keys, t)
	if t_index == -1:
		return CONSTRAINT.NONE
	var t_key = keys[t_index]
	return _constraints[t_key]


func set_constraint(key1: int, key2: int, constraint: CONSTRAINT) -> void:
	var t := TUP.create_tuple(key1, key2)
	var existing_tuples: Array = _constraints.keys()
	var existing_t_index: int = TUP.find_tuple_in_array_of_tuples(existing_tuples, t)
	if existing_t_index != -1:
		t = existing_tuples[existing_t_index]
	_constraints[t] = constraint
	if _constraints[t] == CONSTRAINT.NONE:
		_constraints.erase(t)
		emit_signal("constraint_removed", key1, key2)
	else:
		update_constraints(key1)
	_changed()


func remove_constraints(key1: int) -> void:
	var constraints: Dictionary = get_point_constraints(key1)
	for tuple in constraints:
		var key2: int = TUP.get_other_value_from_tuple(tuple, key1)
		set_constraint(key1, key2, CONSTRAINT.NONE)


func remove_constraint(key1: int, key2: int) -> void:
	set_constraint(key1, key2, CONSTRAINT.NONE)


func get_all_constraints_of_type(type: CONSTRAINT) -> Array[TUP]:
	var constraints: Array[TUP] = []
	for t in _constraints:
		var c: CONSTRAINT = _constraints[t]
		if c == type:
			constraints.push_back(t)
	return constraints


########
# MISC #
########
func debug_print() -> void:
	for k in get_all_point_keys():
		var pos: Vector2 = get_point_position(k)
		var _in: Vector2 = get_point_in(k)
		var out: Vector2 = get_point_out(k)
		print("%s = P:%s | I:%s | O:%s" % [k, pos, _in, out])


######################
# MATERIAL OVERRIDES #
######################
func set_material_overrides(dict: Dictionary) -> void:
	for k in dict:
		if not TUP.is_tuple(k):
			push_error("Material Override Dictionary KEY is not an Array with 2 points!")
		var v = dict[k]
		if not v is SS2D_Material_Edge_Metadata:
			push_error("Material Override Dictionary VALUE is not SS2D_Material_Edge_Metadata!")

	if _material_overrides != null:
		for old in _material_overrides.values():
			if old.is_connected("changed", self._on_material_override_changed):
				old.disconnect("changed", self._on_material_override_changed)

	_material_overrides = dict
	for tuple in _material_overrides:
		var m = _material_overrides[tuple]
		m.connect("changed", self._on_material_override_changed.bind(tuple))


func get_material_override_tuple(tuple: Array[int]) -> Array[int]:
	var keys: Array = _material_overrides.keys()
	var idx: int = TUP.find_tuple_in_array_of_tuples(keys, tuple)
	if idx != -1:
		tuple = keys[idx]
	return tuple


func has_material_override(tuple: Array[int]) -> bool:
	tuple = get_material_override_tuple(tuple)
	return _material_overrides.has(tuple)


func remove_material_override(tuple: Array[int]) -> void:
	if not has_material_override(tuple):
		return
	var old := get_material_override(tuple)
	if old.is_connected("changed", self._on_material_override_changed):
		old.disconnect("changed", self._on_material_override_changed)
	_material_overrides.erase(get_material_override_tuple(tuple))
	_on_material_override_changed(tuple)


func set_material_override(tuple: Array[int], mat: SS2D_Material_Edge_Metadata) -> void:
	if has_material_override(tuple):
		var old := get_material_override(tuple)
		if old == mat:
			return
		else:
			if old.is_connected("changed", self._on_material_override_changed):
				old.disconnect("changed", self._on_material_override_changed)
	if not mat.is_connected("changed", self._on_material_override_changed):
		mat.connect("changed", self._on_material_override_changed.bind(tuple))
	_material_overrides[get_material_override_tuple(tuple)] = mat
	_on_material_override_changed(tuple)


func get_material_override(tuple: Array[int]) -> SS2D_Material_Edge_Metadata:
	if not has_material_override(tuple):
		return null
	return _material_overrides[get_material_override_tuple(tuple)]


func get_material_overrides() -> Dictionary:
	return _material_overrides


func clear_all_material_overrides() -> void:
	_material_overrides = {}


func _to_string() -> String:
	return "<SS2D_Point_Array points: %s order: %s>" % [_points.keys(), _point_order]


func _on_material_override_changed(tuple) -> void:
	emit_signal("material_override_changed", tuple)
