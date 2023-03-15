@tool
extends RefCounted
class_name SS2D_IndexMap

## Maps a set of indicies to an object.

const TUP = preload("res://addons/rmsmartshape/lib/tuple.gd")

var object: Variant = null
var indicies: Array[int] = [] : set = set_indicies


## Parameter [param subresources] has no effect, no subresources to duplicate.
func duplicate(_subresources: bool = false) -> SS2D_IndexMap:
	return SS2D_IndexMap.new(indicies, object)


func _init(i: Array[int], o: Variant) -> void:
	object = o
	set_indicies(i)


func set_indicies(a: Array[int]) -> void:
	indicies = a.duplicate()


func _to_string() -> String:
	return "[M_2_IDX] (%s) | %s" % [str(object), indicies]


static func is_index_array_valid(idx_array: Array[int]) -> bool:
	return idx_array.size() >= 2


func is_valid() -> bool:
	return SS2D_IndexMap.is_index_array_valid(indicies)


func get_contiguous_segments() -> Array:
	if is_contiguous():
		return [indicies.duplicate()]
	var segments: Array = []
	var break_idx: int = find_break()
	var remainder: Array[int] = indicies.duplicate()
	while break_idx != -1:
		var new_slice: Array[int] = []
		for i in range(0, break_idx):
			new_slice.push_back(remainder[i])
		segments.push_back(new_slice)
		remainder = remainder.slice(break_idx, remainder.size())
		break_idx = SS2D_IndexMap.find_break_in_array(remainder)
	if not remainder.is_empty():
		segments.push_back(remainder)
	return segments


## Will join together segments that share the same idx,
## ex. [1,2], [4,5], and [2,3,4] become [1,2,3,4,5]
static func join_segments(segments: Array) -> Array:
	var final_segments := segments.duplicate()
	var to_join_tuple: Array[int]
	var join_performed := true
	while join_performed:
		join_performed = false
		for i in range(0, final_segments.size()):
			if join_performed:
				break
			for ii in range(i + 1, final_segments.size()):
				var a: Array[int] = final_segments[i]
				var b: Array[int] = final_segments[ii]
				if a.back() == b[0]:
					to_join_tuple = TUP.create_tuple(i, ii)
					join_performed = true
				if b.back() == a[0]:
					to_join_tuple = TUP.create_tuple(ii, i)
					join_performed = true
				if join_performed:
					break
		if join_performed:
			var idx_lowest: int = to_join_tuple[0]
			var idx_highest: int = to_join_tuple[1]
			var lowest: Array[int] = final_segments[idx_lowest]
			var highest: Array[int] = final_segments[idx_highest]
			final_segments.erase(lowest)
			final_segments.erase(highest)
			# pop the shared idx from lowest
			lowest.pop_back()
			var new_segment: Array[int] = []
			new_segment.append_array(lowest)
			new_segment.append_array(highest)
			final_segments.push_back(new_segment)

	return final_segments


## Does each index increment by 1 without any breaks.
func is_contiguous() -> bool:
	return SS2D_IndexMap.is_array_contiguous(indicies)


static func is_array_contiguous(a: Array[int]) -> bool:
	return find_break_in_array(a) == -1


## Find a break in the indexes where they aren't contiguous.[br]
## Will return -1 if there's no break.[br]
func find_break() -> int:
	return SS2D_IndexMap.find_break_in_array(indicies)


static func find_break_in_array(a: Array[int]) -> int:
	for i in range(0, a.size() - 1, 1):
		if is_break_at_index_in_array(a, i):
			return i + 1
	return -1


## Whether there is a break at the given index.[br]
## Will return -1 if there's no break.[br]
func is_break_at_index(i: int) -> bool:
	return SS2D_IndexMap.is_break_at_index_in_array(indicies, i)


static func is_break_at_index_in_array(a: Array[int], i: int) -> bool:
	var difference: int = absi((a[i]) - (a[i + 1]))
	return difference != 1


func has_index(idx: int) -> bool:
	return indicies.has(idx)


func lowest_index() -> int:
	return indicies.min()


func highest_index() -> int:
	return indicies.max()


func _split_indicies_into_multiple_mappings(new_indicies: Array[int]) -> Array[SS2D_IndexMap]:
	var maps: Array[SS2D_IndexMap] = []
	var break_idx: int = SS2D_IndexMap.find_break_in_array(new_indicies)
	while break_idx != -1:
		var sub_indicies: Array[int] = []
		for i in range(0, break_idx, 1):
			sub_indicies.push_back(new_indicies[i])
		if SS2D_IndexMap.is_index_array_valid(sub_indicies):
			maps.push_back(SS2D_IndexMap.new(sub_indicies, object))
		for i in sub_indicies:
			new_indicies.erase(i)
		break_idx = SS2D_IndexMap.find_break_in_array(new_indicies)

	if SS2D_IndexMap.is_index_array_valid(new_indicies):
		maps.push_back(SS2D_IndexMap.new(new_indicies, object))
	return maps


## Will create a new set of SS2D_IndexMaps. [br][br]
##
## The new set will contain all of the indicies of the current set,
## minus the ones specified in the indicies parameter. [br][br]
##
## Example:								[br]
## indicies = [0,1,2,3,4,5,6]			[br]
## to_remove = [3,4]					[br]
## new_sets = [0,1,2] [5,6]				[br][br]
##
## This may split the IndexMap or make it invalid entirely.
## As a result, the returned array could have 0 or several IndexMaps.
func remove_indicies(to_remove: Array[int]) -> Array[SS2D_IndexMap]:
	var new_indicies: Array[int] = indicies.duplicate()
	for r in to_remove:
		new_indicies.erase(r)
	if not SS2D_IndexMap.is_index_array_valid(new_indicies):
		return []
	if SS2D_IndexMap.is_array_contiguous(new_indicies):
		return [SS2D_IndexMap.new(new_indicies, object)]

	return _split_indicies_into_multiple_mappings(new_indicies)


## Will create a new set of SS2D_IndexMaps. [br][br]
##
## The new set will contain all of the edges of the current set,
## minus the ones specified in the indicies parameter. [br][br]
##
## Example:								[br]
## indicies = [0,1,2,3,4,5,6]			[br]
## to_remove = [4,5]					[br]
## new_sets = [0,1,2,3,4] [4,5,6]		[br][br]
##
## This may split the IndexMap or make it invalid entirely.
## As a result, the returned array could have 0 or several IndexMaps.
func remove_edges(to_remove: Array[int]) -> Array[SS2D_IndexMap]:
	# Corner case
	if to_remove.size() == 2:
		var idx: int = indicies.find(to_remove[0])
		if idx != indicies.size()-1:
			if indicies[idx+1] == to_remove[1]:
				# Need one split
				var set_1 := indicies.slice(0, idx+1)
				var set_2 := indicies.slice(idx+1, indicies.size())
				var new_maps: Array[SS2D_IndexMap] = []
				if SS2D_IndexMap.is_index_array_valid(set_1):
					new_maps.push_back(SS2D_IndexMap.new(set_1, object))
				if SS2D_IndexMap.is_index_array_valid(set_2):
					new_maps.push_back(SS2D_IndexMap.new(set_2, object))
				return new_maps
		return [SS2D_IndexMap.new(indicies, object)]

	# General case
	var new_edges: Array = SS2D_IndexMap.indicies_to_edges(indicies.duplicate())
	for i in range(0, to_remove.size() - 1, 1):
		var idx1: int = to_remove[i]
		var idx2: int = to_remove[i + 1]
		var edges_to_remove: Array[int] = []
		for ii in range(0, new_edges.size(), 1):
			var edge: Array[int] = new_edges[ii]
			if (edge[0] == idx1 or edge[0] == idx2) and (edge[1] == idx1 or edge[1] == idx2):
				edges_to_remove.push_back(ii)
		# Reverse iterate
		for ii in range(edges_to_remove.size()-1, -1, -1):
			new_edges.remove_at(edges_to_remove[ii])

	new_edges = SS2D_IndexMap.join_segments(new_edges)
	var new_index_mappings: Array[SS2D_IndexMap] = []
	for e in new_edges:
		new_index_mappings.push_back(SS2D_IndexMap.new(e, object))
	return new_index_mappings


static func indicies_to_edges(p_indicies: Array[int]) -> Array:
	var edges: Array = []
	for i in range(0, p_indicies.size()-1, 1):
		var edge: Array[int] = [i, i+1]
		if is_array_contiguous(edge):
			edges.push_back(edge)
	return edges


static func index_map_array_sort_by_object(imaps: Array) -> Dictionary:
	var dict := {}
	for imap in imaps:
		if not dict.has(imap.object):
			var arr: Array[SS2D_IndexMap] = []
			dict[imap.object] = arr
		dict[imap.object].push_back(imap)
	return dict
