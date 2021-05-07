tool
extends Reference
class_name SS2D_Meta_Mat_2_Idxs

"""
Maps a set of indicies to a meta_material
"""

var meta_material: SS2D_Material_Edge_Metadata
var indicies: Array = [] setget set_indicies


# Workaround (class cannot reference itself)
func __new(i:Array, m: SS2D_Material_Edge_Metadata) -> SS2D_Meta_Mat_2_Idxs:
	return get_script().new(i, m)

# Sub resource has no effect, no sub resources to duplicate
func duplicate(sub_resource: bool = false):
	var _new = __new(indicies, meta_material)
	return _new


func _init(i: Array, m: SS2D_Material_Edge_Metadata):
	meta_material = m
	set_indicies(i)


# Sort indicies in ascending order
func set_indicies(a: Array):
	indicies = a.duplicate()


func _to_string() -> String:
	return "[M_2_IDX] (%s) | %s" % [str(meta_material), indicies]


func is_valid() -> bool:
	return indicies.size() >= 2

# Break the indicies into contiguous segments
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

# Will wrap around 2 segments that contain 0 and the highest_idx
# Used for closed_shape functionality
# Most likely takes input from the get_contiguous_segments function
func wrap_around_contiguous_segments(segments:Array, highest_idx:int) -> Array:
	var new_segments = segments.duplicate()
	var zero_at_first_idx = null
	var high_at_last_idx = null
	for segment in new_segments:
		if segment[0] == 0:
			zero_at_first_idx = segment
		if segment.back() == highest_idx:
			high_at_last_idx = segment
	if zero_at_first_idx != null and high_at_last_idx != null:
		high_at_last_idx.append_array(zero_at_first_idx)
		new_segments.erase(zero_at_first_idx)
	return new_segments




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
	# If the distance between 2 idxes is greater than 1
	if abs((a[i] + 1) - (a[i + 1])):
		return true
	return false


func has_index(idx: int) -> bool:
	return indicies.has(idx)


func lowest_index() -> int:
	return indicies.min()


func highest_index() -> int:
	return indicies.max()

