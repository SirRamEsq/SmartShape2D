@tool
extends Resource
class_name SS2D_Point_Array

enum CONSTRAINT { NONE = 0, AXIS_X = 1, AXIS_Y = 2, CONTROL_POINTS = 4, PROPERTIES = 8, ALL = 15 }

# Maps a key to each point: Dict[int, SS2D_Point]
@export var _points: Dictionary = {} : set = _set_points
# Contains all keys; the order of the keys determines the order of the points
@export var _point_order := PackedInt32Array() : set = set_point_order

## Dict[Vector2i, CONSTRAINT]
## Key is tuple of point_keys; Value is the CONSTRAINT enum.
@export var _constraints: Dictionary = {} : set = _set_constraints
# Next key value to generate
@export var _next_key: int = 0 : set = set_next_key

## Dict[Vector2i, SS2D_Material_Edge_Metadata]
## Dictionary of specific materials to use for specific tuples of points.
## Key is tuple of two point keys, value is material.
@export var _material_overrides: Dictionary = {} : set = set_material_overrides

## Controls how many subdivisions a curve segment may face before it is considered
## approximate enough.
@export_range(0, 8, 1)
var tessellation_stages: int = 3 : set = set_tessellation_stages

## Controls how many degrees the midpoint of a segment may deviate from the real
## curve, before the segment has to be subdivided.
@export_range(0.1, 16.0, 0.1, "or_greater", "or_lesser")
var tessellation_tolerance: float = 6.0 : set = set_tessellation_tolerance

@export_range(1, 512) var curve_bake_interval: float = 20.0 : set = set_curve_bake_interval

var _constraints_enabled: bool = true
var _updating_constraints := false
var _keys_to_update_constraints := PackedInt32Array()

var _changed_during_update := false
var _updating := false

# Point caches
var _point_cache_dirty := true
var _vertex_cache := PackedVector2Array()
var _curve := Curve2D.new()
var _curve_no_control_points := Curve2D.new()
var _tesselation_cache := PackedVector2Array()
var _tess_vertex_mapping := SS2D_TesselationVertexMapping.new()

## Gets called when points were modified.
## In comparison to the "changed" signal, "update_finished" will only be called once after
## begin/end_update() blocks, while "changed" will be called for every singular change.
## Hence, this signal is usually better suited to react to point updates.
signal update_finished()

signal constraint_removed(key1: int, key2: int)
signal material_override_changed(tuple: Vector2i)

###################
# HANDLING POINTS #
###################


func _init() -> void:
	# Required by Godot to correctly make unique instances of this resource
	_points = {}
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
	copy.tessellation_stages = tessellation_stages
	copy.tessellation_tolerance = tessellation_tolerance
	copy.curve_bake_interval = curve_bake_interval

	if deep:
		var new_point_dict := {}
		for k: int in _points:
			new_point_dict[k] = get_point(k).duplicate(true)
		copy._points = new_point_dict
		copy._point_order = _point_order.duplicate()
		copy._constraints = _constraints.duplicate()
		copy._material_overrides = _material_overrides.duplicate()
	else:
		copy._points = _points
		copy._point_order = _point_order
		copy._constraints = _constraints
		copy._material_overrides = _material_overrides

	return copy


## Called by Godot when loading from a saved scene
func _set_points(ps: Dictionary) -> void:
	_points = ps
	for k: int in _points:
		_hook_point(k)
	_changed()


func set_point_order(po: PackedInt32Array) -> void:
	_point_order = po
	_changed()


func _set_constraints(cs: Dictionary) -> void:
	_constraints = cs

	# For backwards compatibility (Array to Vector2i transition)
	# FIXME: Maybe remove during the next breaking release
	SS2D_IndexTuple.dict_validate(_constraints, TYPE_INT)


func set_next_key(i: int) -> void:
	_next_key = i


func __generate_key(next: int) -> int:
	if not is_key_valid(next):
		return __generate_key(maxi(next + 1, 0))
	return next


## Reserve a key. It will not be generated again.
func reserve_key() -> int:
	var next: int = __generate_key(_next_key)
	_next_key = next + 1
	return next


## Returns next key that would be generated when adding a new point, e.g. when [method add_point] is called.
func get_next_key() -> int:
	return __generate_key(_next_key)


func is_key_valid(k: int) -> bool:
	return k >= 0 and not _points.has(k)


## Add a point and insert it at the given index or at the end by default.
## Returns the key of the added point.
func add_point(point: Vector2, idx: int = -1, use_key: int = -1) -> int:
#	print("Add Point  ::  ", point, " | idx: ", idx, " | key: ", use_key, " |")
	if use_key == -1 or not is_key_valid(use_key):
		use_key = reserve_key()
	if use_key == _next_key:
		_next_key += 1
	_points[use_key] = SS2D_Point.new(point)
	_hook_point(use_key)
	_point_order.push_back(use_key)
	if idx != -1:
		set_point_index(use_key, idx)
	_changed()
	return use_key


## Deprecated. There is no reason to use this function, points can be modified directly.
## @deprecated
func set_point(key: int, value: SS2D_Point) -> void:
	if has_point(key):
		# FIXME: Should there be a call to remove_constraints() like in remove_point()? Because
		# we're technically deleting a point and replacing it with another.
		_unhook_point(get_point(key))
		_points[key] = value
		_hook_point(key)
		_changed()


## Connects the changed signal of the given point. Requires that the point exists in _points.
func _hook_point(key: int) -> void:
	var p := get_point(key)
	if not p.changed.is_connected(_on_point_changed):
		p.changed.connect(_on_point_changed.bind(key))


## Disconnects the changed signal of the given point. See also _hook_point().
func _unhook_point(p: SS2D_Point) -> void:
	if not p.changed.is_connected(_on_point_changed):
		p.changed.disconnect(_on_point_changed)


func is_index_in_range(idx: int) -> bool:
	return idx >= 0 and idx < _point_order.size()


func get_point_key_at_index(idx: int) -> int:
	return _point_order[idx]


func get_edge_keys_for_indices(indices: Vector2i) -> Vector2i:
	return Vector2i(
		get_point_key_at_index(indices.x),
		get_point_key_at_index(indices.y)
	)


func get_point_at_index(idx: int) -> SS2D_Point:
	return _points[_point_order[idx]]


## Returns the point with the given key as reference or null if it does not exist.
func get_point(key: int) -> SS2D_Point:
	return _points.get(key)


func get_point_count() -> int:
	return _point_order.size()


func get_point_index(key: int) -> int:
	if has_point(key):
		var idx := 0
		for k in _point_order:
			if key == k:
				return idx
			idx += 1
	return -1


## Reverse order of points in point array.[br]
## I.e. [1, 2, 3, 4] will become [4, 3, 2, 1].[br]
func invert_point_order() -> void:
	# Postpone `changed` and disable constraints.
	var was_updating: bool = _updating
	_updating = true
	disable_constraints()

	_point_order.reverse()
	# Swap Bezier points.
	for p: SS2D_Point in _points.values():
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


func get_all_point_keys() -> PackedInt32Array:
	# _point_order should contain every single point ONLY ONCE
	return _point_order


func remove_point(key: int) -> bool:
	if has_point(key):
#		print("Remove Point  ::  ", get_point_position(key), " | idx: ", get_point_index(key), " | key: ", key, " |")
		remove_constraints(key)
		_unhook_point(get_point(key))
		_point_order.remove_at(get_point_index(key))
		_points.erase(key)
		_changed()
		return true
	return false


func remove_point_at_index(idx: int) -> void:
	remove_point(get_point_key_at_index(idx))


## Remove all points from point array.
func clear() -> void:
	_points.clear()
	_point_order.clear()
	_constraints.clear()
	_next_key = 0
	_changed()


## point_in controls the edge leading from the previous vertex to this one
func set_point_in(key: int, value: Vector2) -> void:
	if has_point(key):
		_points[key].point_in = value
		_changed()


func get_point_in(key: int) -> Vector2:
	if has_point(key):
		return _points[key].point_in
	return Vector2(0, 0)


## point_out controls the edge leading from this vertex to the next
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
	var p := get_point(key)
	return p.properties if p else null


## Returns the corresponding key for a given point or -1 if it does not exist.
func get_key_from_point(p: SS2D_Point) -> int:
	for k: int in _points:
		if p == _points[k]:
			return k
	return -1


func _on_point_changed(key: int) -> void:
	if _updating_constraints:
		_keys_to_update_constraints.push_back(key)
	else:
		update_constraints(key)


## Begin updating the shape.[br]
## Shape mesh and curve will only be updated after [method end_update] is called.
func begin_update() -> void:
	_updating = true


## End updating the shape.[br]
## Mesh and curve will be updated, if changes were made to points array after
## [method begin_update] was called.
func end_update() -> bool:
	var was_dirty := _changed_during_update
	_updating = false
	_changed_during_update = false
	if was_dirty:
		update_finished.emit()
	return was_dirty


## Is shape in the middle of being updated.
## Returns [code]true[/code] after [method begin_update] and before [method end_update].
func is_updating() -> bool:
	return _updating


func _changed() -> void:
	_point_cache_dirty = true

	emit_changed()

	if _updating:
		_changed_during_update = true
	else:
		update_finished.emit()

###############
# CONSTRAINTS #
###############


func disable_constraints() -> void:
	_constraints_enabled = false


func enable_constraints() -> void:
	_constraints_enabled = true


func _update_constraints(src: int) -> void:
	if not _constraints_enabled:
		return

	var constraints := get_point_constraints_tuples(src)

	for tuple in constraints:
		var constraint: CONSTRAINT = SS2D_IndexTuple.dict_get(_constraints, tuple)

		if constraint == CONSTRAINT.NONE:
			continue

		var dst: int = SS2D_IndexTuple.get_other_value(tuple, src)

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
		var key_set := _keys_to_update_constraints
		_keys_to_update_constraints = PackedInt32Array()
		for k in key_set:
			_update_constraints(k)

	_updating_constraints = false
	_changed()


## Returns all point constraint that include the given point key.
## Returns a Dictionary[Vector2i, CONSTRAINT].
func get_point_constraints(key1: int) -> Dictionary:
	var constraints := {}
	var tuples := get_point_constraints_tuples(key1)

	for t in tuples:
		constraints[t] = get_point_constraint(t.x, t.y)

	return constraints


## Returns all point constraint tuples that include the given point key.
func get_point_constraints_tuples(key1: int) -> Array[Vector2i]:
	return SS2D_IndexTuple.dict_find_partial(_constraints, key1)


## Returns the constraint for a pair of keys or CONSTRAINT.NONE if no constraint exists.
func get_point_constraint(key1: int, key2: int) -> CONSTRAINT:
	return SS2D_IndexTuple.dict_get(_constraints, Vector2i(key1, key2), CONSTRAINT.NONE)


## Set a constraint between two points. If the constraint is NONE, remove_constraint() is called instead.
func set_constraint(key1: int, key2: int, constraint: CONSTRAINT) -> void:
	var t := Vector2i(key1, key2)

	if constraint == CONSTRAINT.NONE:
		remove_constraint(t)
		return

	SS2D_IndexTuple.dict_set(_constraints, t, constraint)
	update_constraints(key1)
	_changed()


## Remove all constraints involving the given point key.
func remove_constraints(key1: int) -> void:
	for tuple in get_point_constraints_tuples(key1):
		remove_constraint(tuple)


## Remove the constraint between the two point indices of the given tuple.
func remove_constraint(point_index_tuple: Vector2i) -> void:
	if SS2D_IndexTuple.dict_erase(_constraints, point_index_tuple):
		emit_signal("constraint_removed", point_index_tuple.x, point_index_tuple.y)


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
## dict: Dict[Vector2i, SS2D_Material_Edge_Metadata]
func set_material_overrides(dict: Dictionary) -> void:
	# For backwards compatibility (Array to Vector2i transition)
	# FIXME: Maybe remove during the next breaking release
	SS2D_IndexTuple.dict_validate(dict, SS2D_Material_Edge_Metadata)

	if _material_overrides != null:
		for old: SS2D_Material_Edge_Metadata in _material_overrides.values():
			_unhook_mat(old)

	_material_overrides = dict

	for tuple: Vector2i in _material_overrides:
		_hook_mat(tuple, _material_overrides[tuple])


func has_material_override(tuple: Vector2i) -> bool:
	return SS2D_IndexTuple.dict_has(_material_overrides, tuple)


func remove_material_override(tuple: Vector2i) -> void:
	var old := get_material_override(tuple)

	if old != null:
		_unhook_mat(old)
		SS2D_IndexTuple.dict_erase(_material_overrides, tuple)
		_on_material_override_changed(tuple)


func set_material_override(tuple: Vector2i, mat: SS2D_Material_Edge_Metadata) -> void:
	var old := get_material_override(tuple)

	if old != null:
		if old == mat:
			return
		else:
			_unhook_mat(old)

	_hook_mat(tuple, mat)
	SS2D_IndexTuple.dict_set(_material_overrides, tuple, mat)
	_on_material_override_changed(tuple)


## Returns the material override for the edge defined by the given point index tuple, or null if
## there is no override.
func get_material_override(tuple: Vector2i) -> SS2D_Material_Edge_Metadata:
	return SS2D_IndexTuple.dict_get(_material_overrides, tuple)


func _hook_mat(tuple: Vector2i, mat: SS2D_Material_Edge_Metadata) -> void:
	if not mat.changed.is_connected(_on_material_override_changed):
		mat.changed.connect(_on_material_override_changed.bind(tuple))


func _unhook_mat(mat: SS2D_Material_Edge_Metadata) -> void:
	if mat.changed.is_connected(_on_material_override_changed):
		mat.changed.disconnect(_on_material_override_changed)


## Returns a list of index tuples for wich material overrides exist.
func get_material_overrides() -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	keys.assign(_material_overrides.keys())
	return keys


func clear_all_material_overrides() -> void:
	_material_overrides = {}



## Returns a PackedVector2Array with all points of the shape.
func get_vertices() -> PackedVector2Array:
	_update_cache()
	return _vertex_cache


## Returns a Curve2D representing the shape including bezier handles.
func get_curve() -> Curve2D:
	_update_cache()
	return _curve


## Returns a Curve2D representing the shape, disregarding bezier handles.
func get_curve_no_control_points() -> Curve2D:
	_update_cache()
	return _curve_no_control_points


## Returns a PackedVector2Array with all points
func get_tessellated_points() -> PackedVector2Array:
	_update_cache()
	return _tesselation_cache


func set_tessellation_stages(value: int) -> void:
	tessellation_stages = value
	_changed()


func set_tessellation_tolerance(value: float) -> void:
	tessellation_tolerance = value
	_changed()


func set_curve_bake_interval(f: float) -> void:
	curve_bake_interval = f
	_curve.bake_interval = f
	_changed()


func get_tesselation_vertex_mapping() -> SS2D_TesselationVertexMapping:
	_update_cache()
	return _tess_vertex_mapping


func _update_cache() -> void:
	# NOTE: Theoretically one could differentiate between vertex list dirty, curve dirty and
	# tesselation dirty to never waste any computation time.
	# However, 99% of the time, the cache will be dirty due to vertex updates, so we don't bother.

	if not _point_cache_dirty:
		return

	var keys := get_all_point_keys()

	_vertex_cache.resize(keys.size())
	_curve.clear_points()
	_curve_no_control_points.clear_points()

	for i in keys.size():
		var key := keys[i]
		var pos := get_point_position(keys[i])

		# Vertex cache
		_vertex_cache[i] = pos

		# Curves
		_curve.add_point(pos, get_point_in(key), get_point_out(key))
		_curve_no_control_points.add_point(pos)

	# Tesselation
	# Point 0 will be the same on both the curve points and the vertices
	# Point size - 1 will be the same on both the curve points and the vertices
	_tesselation_cache = _curve.tessellate(tessellation_stages, tessellation_tolerance)

	if _tesselation_cache.size() >= 2:
		_tesselation_cache[0] = _curve.get_point_position(0)
		_tesselation_cache[-1] = _curve.get_point_position(_curve.get_point_count() - 1)

	_tess_vertex_mapping.build(_tesselation_cache, _vertex_cache)

	_point_cache_dirty = false


func _to_string() -> String:
	return "<SS2D_Point_Array points: %s order: %s>" % [_points.keys(), _point_order]


func _on_material_override_changed(tuple: Vector2i) -> void:
	material_override_changed.emit(tuple)
