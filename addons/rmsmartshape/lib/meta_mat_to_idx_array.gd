tool
extends Reference

"""
Everything in this script should be static
This script contains code that may referenced in multiple locations in the plugin

This is a simple script to work with arrays of SS2D_IndexMap
Some notes:
"""

# Will merge two arrays of MetaMatToIdxs; a overriting on top of b; returning a new array of MetaMatToIDxs
static func overwrite_array_a_into_array_b(a: Array, b: Array) -> Array:
	var ret = []
	# Make equal to b; b serves as the baseline
	for bm in b:
		ret.push_back(bm.duplicate())

	# Merge a on top of b
	var to_remove = []
	var to_add = []
	for am in a:
		var m = am.duplicate()
		# Check to see if any of the a indicies exist in the mm array already
		for mm in ret:
			# Find all overlapping points
			var overlapping_points = []
			for idx in am.indicies:
				var pos = mm.indicies.find(idx)
				if pos == -1:
					continue
				overlapping_points.append(idx)

			if overlapping_points.empty():
				continue

			# Remove all overlapping points
			for pos in overlapping_points:
				mm.indicies.erase(pos)

			# Remove Mapping entirely if no longer valid
			if not mm.is_valid():
				to_remove.push_back(mm)

		to_add.push_back(m)
		for remove in to_remove:
			ret.erase(remove)
		for add in to_add:
			ret.push_back(add)
		to_add = []
		to_remove = []
	return ret
