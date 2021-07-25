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
func __new(i: Array, o) -> SS2D_IndexMap:
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


static func is_index_array_valid(idx_array: Array) -> bool:
	return idx_array.size() >= 2


func is_valid() -> bool:
	return is_index_array_valid(indicies)


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
		break_idx = find_break_in_array(remainder)
	if not remainder.empty():
		segments.push_back(remainder)
	return segments

# Will join together segments that share the same idx
# ex. [1,2], [4,5], and [2,3,4] become [1,2,3,4,5]
static func join_segments(segments: Array) -> Array:
	var final_segments = segments.duplicate()
	var to_join_tuple = []
	while to_join_tuple != null:
		to_join_tuple = null
		for i in range(0, final_segments.size()):
			if to_join_tuple != null:
				break
			for ii in range(i + 1, final_segments.size()):
				var a = final_segments[i]
				var b = final_segments[ii]
				var ab = [a.back(), b[0]]
				var ba = [b.back(), a[0]]
				if a.back() == b[0]:
					to_join_tuple = TUP.create_tuple(i, ii)
				if b.back() == a[0]:
					to_join_tuple = TUP.create_tuple(ii, i)
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
	return is_array_contiguous(indicies)


static func is_array_contiguous(a: Array) -> bool:
	return find_break_in_array(a) == -1


# Find a break in the indexes where they aren't contiguous
# Will return -1 if there's no break
func find_break() -> int:
	return find_break_in_array(indicies)


static func find_break_in_array(a: Array) -> int:
	for i in range(0, a.size() - 1, 1):
		if is_break_at_index_in_array(a, i):
			return i + 1
	return -1


# Whether there is a break at the given index
# Will return -1 if there's no break
func is_break_at_index(i: int) -> bool:
	return is_break_at_index_in_array(indicies, i)


static func is_break_at_index_in_array(a: Array, i: int) -> bool:
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


func _split_indicies_into_multiple_mappings(new_indicies: Array) -> Array:
	var maps = []
	var break_idx = find_break_in_array(new_indicies)
	while break_idx != -1:
		var sub_indicies = []
		for i in range(0, break_idx, 1):
			sub_indicies.push_back(new_indicies[i])
		if is_index_array_valid(sub_indicies):
			maps.push_back(__new(sub_indicies, object))
		for i in sub_indicies:
			new_indicies.erase(i)
		break_idx = find_break_in_array(new_indicies)

	if is_index_array_valid(new_indicies):
		maps.push_back(__new(new_indicies, object))
	return maps

"""
Will create a new set of SS2D_IndexMaps
The new set will contain all of the indicies of the current set,
minus the ones specified in the indicies parameter
ie.
indicies = [0,1,2,3,4,5,6]
to_remove = [3,4]
new_sets = [0,1,2] [5,6]


This may split the IndexMap or make it invalid entirely
As a result, the returned array could have 0 or several IndexMaps
"""


func remove_indicies(to_remove: Array) -> Array:
	var new_indicies = indicies.duplicate()
	for r in to_remove:
		new_indicies.erase(r)
	if not is_index_array_valid(new_indicies):
		return []
	if is_array_contiguous(new_indicies):
		return [__new(new_indicies, object)]

	return _split_indicies_into_multiple_mappings(new_indicies)


"""
Will create a new set of SS2D_IndexMaps
The new set will contain all of the edges of the current set,
minus the ones specified in the indicies parameter
ie.
indicies = [0,1,2,3,4,5,6]
to_remove = [4,5]
new_sets = [0,1,2,3,4] [4,5,6]


This may split the IndexMap or make it invalid entirely
As a result, the returned array could have 0 or several IndexMaps
"""


func remove_edges(to_remove: Array) -> Array:
	# Corner case
	if to_remove.size() == 2:
		var idx = indicies.find(to_remove[0])
		if idx != indicies.size()-1:
			if indicies[idx+1] == to_remove[1]:
				# Need one split
				var set_1 = indicies.slice(0, idx)
				var set_2 = indicies.slice(idx+1, indicies.size()-1)
				var new_maps = []
				if is_index_array_valid(set_1):
					new_maps.push_back(__new(set_1, object))
				if is_index_array_valid(set_2):
					new_maps.push_back(__new(set_2, object))
				return new_maps
		return [__new(indicies, object)]


	# General case
	var new_edges = indicies_to_edges(indicies.duplicate())
	for i in range(0, to_remove.size() - 1, 1):
		var idx1 = to_remove[i]
		var idx2 = to_remove[i + 1]
		var edges_to_remove = []
		for ii in range(0, new_edges.size(), 1):
			var edge = new_edges[ii]
			if (edge[0] == idx1 or edge[0] == idx2) and (edge[1] == idx1 or edge[1] == idx2):
				edges_to_remove.push_back(ii)
		# Reverse iterate
		for ii in range(edges_to_remove.size()-1, -1, -1):
			new_edges.remove(edges_to_remove[ii])

	new_edges = join_segments(new_edges)
	var new_index_mappings = []
	for e in new_edges:
		new_index_mappings.push_back(__new(e, object))
	return new_index_mappings

static func indicies_to_edges(indicies:Array)->Array:
	var edges = []
	for i in range(0, indicies.size()-1, 1):
		var edge = [i,i+1]
		if is_array_contiguous(edge):
			edges.push_back(edge)
	return edges

static func index_map_array_sort_by_object(imaps:Array)->Dictionary:
	var dict = {}
	for imap in imaps:
		if not dict.has(imap.object):
			dict[imap.object] = []
		dict[imap.object].push_back(imap)
	return dict
