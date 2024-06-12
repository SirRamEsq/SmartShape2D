@tool
extends RefCounted
class_name SS2D_IndexTuple

## Provides utility functions for handling and storing indices of two related points using Vector2i.
##
## Index tuples are considered equal if their elements are equal, regardless of their order:
## T(X, Y) <=> T(Y, X).
##
## For effectively working with containers, helper functions for arrays and dictionaries are
## provided that implement the above behavior.

## Returns the second tuple element that does not equal the given value.
## Returns -1 if neither element matches.
static func get_other_value(t: Vector2i, value: int) -> int:
	if t.x == value:
		return t.y
	elif t.y == value:
		return t.x
	return -1


## Returns whether two tuples are equal. Two tuples are considered equal when both contain the same values regardless of order.
static func are_equal(t1: Vector2i, t2: Vector2i) -> bool:
	return t1 == t2 or t1 == flip_elements(t2)


## Returns true when the tuple contains the given value.
static func has(t: Vector2i, value: int) -> bool:
	return t.x == value or t.y == value


## Searches for an equal tuple in the given array and returns the index or -1 if not found.
## Incorporates the equality behavior.
static func array_find(tuple_array: Array[Vector2i], t: Vector2i) -> int:
	for i in tuple_array.size():
		if are_equal(tuple_array[i], t):
			return i
	return -1


## Returns whether the given tuple exists in the given array.
## Incorporates the equality behavior.
static func array_has(tuple_array: Array[Vector2i], t: Vector2i) -> bool:
	return array_find(tuple_array, t) != -1


## Returns a list indices to tuples that contain the given value.
static func array_find_partial(tuple_array: Array[Vector2i], value: int) -> PackedInt32Array:
	var out := PackedInt32Array()

	for i in tuple_array.size():
		if tuple_array[i].x == value or tuple_array[i].y == value:
			out.push_back(i)

	return out


## Transform the tuple into a normalized representation (elements in ascending order).
## Same as sort_ascending() at the moment.
## Useful in more optimized use-cases where certain assumptions can be made if all tuples share a
## normalized representation.
static func normalize_tuple(tuple: Vector2i) -> Vector2i:
	return sort_ascending(tuple)


## Returns a tuple with elements in ascending order.
static func sort_ascending(tuple: Vector2i) -> Vector2i:
	if tuple.x <= tuple.y:
		return tuple
	return flip_elements(tuple)



## Returns a tuple with x and y components switched.
static func flip_elements(tuple: Vector2i) -> Vector2i:
	return Vector2i(tuple.y, tuple.x)


## Validates the keys of a dictionary to be correct tuple values and converts all Arrays to
## corresponding Vector2i values.
## Optionally also validates that values are of the given type.
## Exists mostly for backwards compatibility to allow a seamless transition from Array to Vector2i tuples.
static func dict_validate(dict: Dictionary, value_type: Variant = null) -> void:
	# TODO: Maybe don't use asserts but push_warning and return true if successful
	for key: Variant in dict.keys():
		var value: Variant = dict[key]

		if value_type != null:
			assert(is_instance_of(value, value_type), "Incorrect value type in dictionary: " + var_to_str(value))

		if key is Array or key is PackedInt32Array or key is PackedInt64Array:
			var converted := Vector2i(int(key[0]), int(key[1]))
			dict.erase(key)
			dict[converted] = value
		else:
			assert(key is Vector2i, "Invalid tuple representation: %s. Should be Vector2i." % var_to_str(key))


## Get the value in a dictionary with the given tuple as key or a default value if it does not exist.
## Incorporates the equality behavior.
static func dict_get(dict: Dictionary, tuple: Vector2i, default: Variant = null) -> Variant:
	if dict.has(tuple):
		return dict[tuple]
	return dict.get(flip_elements(tuple), default)


static func dict_has(dict: Dictionary, tuple: Vector2i) -> bool:
	return dict.has(tuple) or dict.has(flip_elements(tuple))


static func dict_set(dict: Dictionary, tuple: Vector2i, value: Variant) -> void:
	dict[dict_get_key(dict, tuple)] = value


## Removes the given entry from the dictionary. Returns true if a corresponding key existed, otherwise false.
static func dict_erase(dict: Dictionary, tuple: Vector2i) -> bool:
	return dict.erase(dict_get_key(dict, tuple))


## Checks if there is an existing key for the given tuple or its flipped variant and returns it.
## If a key does not exist, returns the tuple as it is.
## Usually this function does not need to be invoked manually, as helpers for dictionary and array access exist.
static func dict_get_key(dict: Dictionary, tuple: Vector2i) -> Vector2i:
	if not dict.has(tuple):
		var flipped := flip_elements(tuple)

		if dict.has(flipped):
			return flipped

	return tuple


## Returns a list of all dictionary keys (tuples) that contain the given value.
static func dict_find_partial(dict: Dictionary, value: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []

	for t: Vector2i in dict.keys():
		if t.x == value or t.y == value:
			out.push_back(t)

	return out
