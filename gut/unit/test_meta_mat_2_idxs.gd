extends "res://addons/gut/test.gd"

const MM2I = preload("res://addons/rmsmartshape/lib/meta_mat_to_idx_array.gd")


func test_contiguous_segments():
	var mm2i = new_index_map([1, 2, 3, 4, 5])
	var segments = mm2i.get_contiguous_segments()
	assert_eq(segments.size(), 1)
	assert_eq(segments[0], [1,2,3,4,5])

	mm2i = new_index_map([0, 1, 2,   4, 5,   7, 8,   10])
	segments = mm2i.get_contiguous_segments()
	assert_eq(segments.size(), 4)
	assert_eq(segments[0], [0, 1, 2])
	assert_eq(segments[1], [4,5])
	assert_eq(segments[2], [7,8])
	assert_eq(segments[3], [10])

func test_join_segments():
	var mm2i = new_index_map([])

	# Test contains some points, but not all
	var segments = [[0, 1, 2,3],  [4, 5],   [7, 8],   [5, 6, 7],   [8, 9, 10],   [10, 11]]
	segments = mm2i.join_segments(segments)
	gut.p(segments)
	assert_eq(segments.size(), 2)
	assert_eq(segments[0], [0,1,2,3])
	assert_eq(segments[1], [4,5,6,7,8,9,10,11])

	segments = [[0, 1], [1,2], [2,3], [4, 5],   [7, 8],   [5, 6, 7],   [8, 9, 10],   [10, 11]]
	segments = mm2i.join_segments(segments)
	gut.p(segments)
	assert_eq(segments.size(), 2)
	assert_eq(segments[0], [0,1,2,3])
	assert_eq(segments[1], [4,5,6,7,8,9,10,11])

	# Test wrap around
	segments = [[0, 1, 2,3],  [4, 5],   [7, 8],   [5, 6, 7],   [8, 9, 10],   [10, 11, 0]]
	segments = mm2i.join_segments(segments)
	gut.p(segments)
	assert_eq(segments.size(), 1)
	assert_eq(segments[0], [4,5,6,7,8,9,10,11,0,1,2,3])

	# Test contains all point pairs
	segments = [[0, 1, 2,3,4],  [4, 5],   [7, 8],   [5, 6, 7],   [8, 9, 10],   [10, 11, 0]]
	segments = mm2i.join_segments(segments)
	gut.p(segments)
	assert_eq(segments.size(), 1)
	assert_eq(segments[0], [0,1,2,3,4,5,6,7,8,9,10,11,0])

func test_index_order():
	var indicies = [5, 4, 2, 3, 1]
	var mm2i = new_index_map(indicies)
	assert_eq(mm2i.highest_index(), 5)
	assert_eq(mm2i.lowest_index(), 1)
	assert_false(mm2i.is_contiguous())
	assert_true(mm2i.is_valid())


func test_contiguous():
	var mm2i = new_index_map()

	mm2i.indicies = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	assert_true(mm2i.is_contiguous())
	mm2i.indicies = [1, 2, 3, 4, 6, 7, 8, 9]
	assert_false(mm2i.is_contiguous())
	mm2i.indicies = [4, 5, 9]
	assert_false(mm2i.is_contiguous())
	mm2i.indicies = [4, 8, 9]
	assert_false(mm2i.is_contiguous())


func test_duplicate():
	var a = new_index_map()
	var b = a.duplicate()
	assert_eq(a.object, b.object)
	assert_eq(a.indicies, b.indicies)
	# Modfiy original; ensure copied indicies array was not modified
	a.indicies.push_back(6)
	assert_ne(a.indicies, b.indicies)


func test_merge_arrays():
	# Define baseline
	var mb1 = new_index_map([0, 1, 2, 3])
	var mb2 = new_index_map([4, 5, 6, 7, 8, 9, 10])
	var mb3 = new_index_map([11, 12, 0])
	var mbFull1 = new_index_map([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0])
	var mbFull2 = new_index_map([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0])

	# Define What is to be merged on top
	var ma1 = new_index_map([3, 4])
	var ma2 = new_index_map([7, 8, 9])

	# Arrays for merging
	var a = [ma1, ma2]
	var b = [mb1, mb2, mb3, mbFull1, mbFull2]

	var c = MM2I.overwrite_array_a_into_array_b(a, b)
	for cm in c:
		gut.p("%s" % cm)
	var expected_values = [
		[0, 1, 2],  #mb1
		[3, 4],  #ma1
		[5, 6, 10],  #mb2
		[7, 8, 9],  #ma2
		[11, 12, 0],  #mb3
		[0, 1, 2, 5, 6, 10, 11, 12, 0],  #mFull1
		[0, 1, 2, 5, 6, 10, 11, 12, 0]  #mFull2
	]
	assert_eq(c.size(), expected_values.size())
	var already_found = []
	for e in expected_values:
		var exists = false
		for cm in c:
			if already_found.has(cm):
				continue
			if cm.indicies == e:
				already_found.push_back(cm)
				exists = true
				break
		assert_true(exists, "Expected %s" % [e])


func new_index_map(indicies: Array = [1, 2, 3, 4, 5]) -> SS2D_IndexMap:
	var meta_mat = SS2D_Material_Edge_Metadata.new()
	var mm2i = SS2D_IndexMap.new(indicies, meta_mat)
	return mm2i
