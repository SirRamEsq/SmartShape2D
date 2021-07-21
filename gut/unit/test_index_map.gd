extends "res://addons/gut/test.gd"

###################
# REMOVE INDICIES #
###################
func test_remove_indicies_basic():
	var object = "OBJECT"
	var indicies  = [0,1,2,3,4,5,6,7,8]
	var to_remove = [2,3,4,5]
	var expected  = [[0,1],[6,7,8]]
	var imap = SS2D_IndexMap.new(indicies, object)
	var new_maps = imap.remove_indicies(to_remove)
	assert_eq(new_maps.size(), expected.size())
	if new_maps.size() == expected.size():
		assert_eq(new_maps[0].object, object)
		assert_eq(new_maps[1].object, object)
		assert_eq(new_maps[0].indicies, expected[0])
		assert_eq(new_maps[1].indicies, expected[1])
	else:
		gut.p(new_maps)

func test_remove_indicies_basic_2():
	var object = "OBJECT"
	var indicies  = [1,2,3,4,5,6,7,8]
	var to_remove = [2,3,4,5]
	var expected  = [[6,7,8]]
	var imap = SS2D_IndexMap.new(indicies, object)
	var new_maps = imap.remove_indicies(to_remove)
	assert_eq(new_maps.size(), expected.size())
	if new_maps.size() == expected.size():
		assert_eq(new_maps[0].object, object)
		assert_eq(new_maps[0].indicies, expected[0])
	else:
		gut.p(new_maps)

func test_remove_indicies_none_remaining():
	var object = "OBJECT"
	var indicies  = [1,2,3,4,5,6]
	var to_remove = [2,3,4,5]
	var expected  = []
	var imap = SS2D_IndexMap.new(indicies, object)
	var new_maps = imap.remove_indicies(to_remove)
	assert_eq(new_maps.size(), expected.size())
	if not(new_maps.size() == expected.size()):
		gut.p(new_maps)

func test_remove_indicies_unaffected():
	var object = "OBJECT"
	var indicies  = [1,2,3,4,5,6]
	var to_remove = [8,9,10]
	var expected  = [[1,2,3,4,5,6]]
	var imap = SS2D_IndexMap.new(indicies, object)
	var new_maps = imap.remove_indicies(to_remove)
	assert_eq(new_maps.size(), expected.size())
	if new_maps.size() == expected.size():
		assert_eq(new_maps[0].object, object)
		assert_eq(new_maps[0].indicies, expected[0])
	else:
		gut.p(new_maps)


################
# REMOVE EDGES #
################
func test_remove_edges_basic():
	var object = "OBJECT"
	var indicies  = [0,1,2,3,4,5,6,7,8]
	var to_remove = [2,3,4,5]
	var expected  = [[0,1,2],[5,6,7,8]]
	var imap = SS2D_IndexMap.new(indicies, object)
	var new_maps = imap.remove_edges(to_remove)
	assert_eq(new_maps.size(), expected.size())
	if new_maps.size() == expected.size():
		assert_eq(new_maps[0].object, object)
		assert_eq(new_maps[1].object, object)
		assert_eq(new_maps[0].indicies, expected[0])
		assert_eq(new_maps[1].indicies, expected[1])
	else:
		gut.p(new_maps)

func test_remove_edges_basic_2():
	var object = "OBJECT"
	var indicies  = [0,1,2,3,4,5,6,7,8]
	var to_remove = [3,4]
	var expected  = [[0,1,2,3],[4,5,6,7,8]]
	var imap = SS2D_IndexMap.new(indicies, object)
	var new_maps = imap.remove_edges(to_remove)
	assert_eq(new_maps.size(), expected.size())
	if new_maps.size() == expected.size():
		assert_eq(new_maps[0].object, object)
		assert_eq(new_maps[1].object, object)
		assert_eq(new_maps[0].indicies, expected[0])
		assert_eq(new_maps[1].indicies, expected[1])
	else:
		gut.p(new_maps)


func test_remove_edges_basic_3():
	var object = "OBJECT"
	var indicies  = [2,3,4,5,6,7,8]
	var to_remove = [2,3]
	var expected  = [[3,4,5,6,7,8]]
	var imap = SS2D_IndexMap.new(indicies, object)
	var new_maps = imap.remove_edges(to_remove)
	assert_eq(new_maps.size(), expected.size())
	if new_maps.size() == expected.size():
		assert_eq(new_maps[0].object, object)
		assert_eq(new_maps[0].indicies, expected[0])
	else:
		gut.p(new_maps)

#########
# OTHER #
#########

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


func new_index_map(indicies: Array = [1, 2, 3, 4, 5]) -> SS2D_IndexMap:
	var meta_mat = SS2D_Material_Edge_Metadata.new()
	var mm2i = SS2D_IndexMap.new(indicies, meta_mat)
	return mm2i
