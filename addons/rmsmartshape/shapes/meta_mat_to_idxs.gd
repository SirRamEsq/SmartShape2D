tool
extends Reference
class_name SS2D_IndexMap

const TUP = preload("res://addons/rmsmartshape/lib/tuple.gd")

"""
Maps a set of indicies to an object
"""

var object = null
var indicies: Array = [] setget set_indicies


# Workaround (class cannot reference itself)
func __new(i:Array, o) -> SS2D_IndexMap:
	return get_script().new(i, o)

# Sub resource has no effect, no sub resources to duplicate
func duplicate(sub_resource: bool = false):
	var _new = __new(indicies, object)
	return _new


func _init(i: Array, o):
	object = o
	set_indicies(i)


# Sort indicies in ascending order
func set_indicies(a: Array):
	indicies = a.duplicate()


func _to_string() -> String:
	return "[M_2_IDX] (%s) | %s" % [str(object), indicies]


func is_valid() -> bool:
	return indicies.size() >= 2

func get_contiguous_segments() -> Array:
	if is_contiguous():
		return [indicies.duplicate()]
	var segments = []
	var break_idx = find_break()
	var remainder = indicies.duplicate()
	while break_idx != -1:
		var new_slice = []
		for i in range(0, break_idx):
			new_slice.push_back(remainder[i])
		segments.push_back(new_slice)
		remainder = remainder.slice(break_idx, remainder.size() - 1)
		break_idx = _find_break(remainder)
	if not remainder.empty():
		segments.push_back(remainder)
	return segments

# Will join together segments that share the same idx
# ex. [1,2], [4,5], and [2,3,4] become [1,2,3,4,5]
# Most likely will take input from the get_contiguous_segments function
func join_segments(segments:Array) -> Array:
	var final_segments = segments.duplicate()
	var to_join_tuple = []
	while to_join_tuple != null:
		to_join_tuple = null
		for i in range(0, final_segments.size()):
			if to_join_tuple != null:
				break
			for ii in range(i+1, final_segments.size()):
				var a = final_segments[i]
				var b = final_segments[ii]
				var ab = [a.back(),b[0]]
				var ba = [b.back(),a[0]]
				if a.back() == b[0]:
					to_join_tuple = TUP.create_tuple(i,ii)
				if b.back() == a[0]:
					to_join_tuple = TUP.create_tuple(ii,i)
				if to_join_tuple != null:
					break
		if to_join_tuple != null:
			var idx_lowest = to_join_tuple[0]
			var idx_highest = to_join_tuple[1]
			var lowest = final_segments[idx_lowest]
			var highest = final_segments[idx_highest]
			final_segments.erase(lowest)
			final_segments.erase(highest)
			# pop the shared idx from lowest
			lowest.pop_back()
			var new_segment = []
			new_segment.append_array(lowest)
			new_segment.append_array(highest)
			final_segments.push_back(new_segment)

	return final_segments



# Does each index increment by 1 without any breaks
func is_contiguous() -> bool:
	return _is_contiguous(indicies)

func _is_contiguous(a:Array) -> bool:
	return _find_break(a) == -1


# Find a break in the indexes where they aren't contiguous
# Will return -1 if there's no break
func find_break() -> int:
	return _find_break(indicies)
func _find_break(a:Array) -> int:
	for i in range(0, a.size() - 1, 1):
		if _is_break_at_index(a, i):
			return i+1
	return -1

# Whether there is a break at the given index
# Will return -1 if there's no break
func is_break_at_index(i:int) -> bool:
	return _is_break_at_index(indicies,i)
func _is_break_at_index(a:Array, i:int) -> bool:
	var difference = abs((a[i]) - (a[i + 1]))
	if difference != 1:
		return true
	return false


func has_index(idx: int) -> bool:
	return indicies.has(idx)


func lowest_index() -> int:
	return indicies.min()


func highest_index() -> int:
	return indicies.max()

