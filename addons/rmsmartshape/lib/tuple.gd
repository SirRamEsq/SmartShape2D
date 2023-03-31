@tool
extends RefCounted

## Everything in this script should be static.
##
## This script contains code that may referenced in multiple locations in the plugin.
##
## This is a simple script for a *very* simple tuple class
## Some notes:
## - "tuples" are just an array with two elements
## - Only integer Tuples are fully supported
## - Tuple(X,Y) is equal to Tuple(Y,X)


static func create_tuple(a: int, b: int) -> Array[int]:
	return [a, b]


static func get_other_value_from_tuple(t: Array[int], value: int) -> int:
	if t[0] == value:
		return t[1]
	elif t[1] == value:
		return t[0]
	return -1


static func tuples_are_equal(t1: Array[int], t2: Array[int]) -> bool:
	return (t1[0] == t2[0] and t1[1] == t2[1]) or (t1[0] == t2[1] and t1[1] == t2[0])


static func find_tuple_in_array_of_tuples(tuple_array: Array, t: Array[int]) -> int:
	for i in range(tuple_array.size()):
		var other: Array[int]
		other.assign(tuple_array[i])
		if tuples_are_equal(t, other):
			return i
	return -1


static func is_tuple_in_array_of_tuples(tuple_array: Array, t: Array[int]) -> bool:
	return find_tuple_in_array_of_tuples(tuple_array, t) != -1


static func is_tuple(thing) -> bool:
	if thing is Array:
		if thing.size() == 2:
			return true
	return false
