extends "res://addons/gut/test.gd"

func test_equality() -> void:
	var t1 := Vector2i(5, 3)
	var t2 := Vector2i(5, 3)
	var t3 := Vector2i(3, 5)
	var t4 := Vector2i(3, 7)
	var t5 := Vector2i(0, 5)
	assert_true(SS2D_IndexTuple.are_equal(t1, t2))
	assert_true(SS2D_IndexTuple.are_equal(t1, t3))
	assert_true(SS2D_IndexTuple.are_equal(t2, t3))
	assert_false(SS2D_IndexTuple.are_equal(t3, t4))
	assert_false(SS2D_IndexTuple.are_equal(t2, t5))


func test_get_other_value() -> void:
	var t1 := Vector2i(3, 5)
	var t2 := Vector2i(1, 0)
	assert_eq(5, SS2D_IndexTuple.get_other_value(t1, 3))
	assert_eq(3, SS2D_IndexTuple.get_other_value(t1, 5))
	assert_eq(1, SS2D_IndexTuple.get_other_value(t2, 0))
	assert_eq(0, SS2D_IndexTuple.get_other_value(t2, 1))
	assert_eq(-1, SS2D_IndexTuple.get_other_value(t1, 9))
	assert_eq(-1, SS2D_IndexTuple.get_other_value(t2, 9))


func test_dict() -> void:
	var d := {}
	var t1 := Vector2i(1, 2)
	var flipped := SS2D_IndexTuple.flip_elements(t1)

	assert_eq(SS2D_IndexTuple.dict_get(d, t1), null)
	assert_false(SS2D_IndexTuple.dict_has(d, t1))

	SS2D_IndexTuple.dict_set(d, t1, true)

	assert_eq(d.size(), 1)
	assert_eq(SS2D_IndexTuple.dict_get(d, t1), true)
	assert_true(SS2D_IndexTuple.dict_has(d, t1))

	assert_eq(SS2D_IndexTuple.dict_get(d, flipped), true)
	assert_true(SS2D_IndexTuple.dict_has(d, flipped))

	assert_eq(SS2D_IndexTuple.dict_get_key(d, t1), t1)
	assert_eq(SS2D_IndexTuple.dict_get_key(d, flipped), t1)

	SS2D_IndexTuple.dict_erase(d, t1)
	assert_eq(d.size(), 0)

	SS2D_IndexTuple.dict_set(d, t1, true)
	assert_eq(d.size(), 1)
	SS2D_IndexTuple.dict_erase(d, flipped)
	assert_eq(d.size(), 0)


func test_flip() -> void:
	var t := Vector2i(1, 2)
	assert_eq(SS2D_IndexTuple.flip_elements(t), Vector2i(2, 1))


func test_dict_validate() -> void:
	var d := {}
	var t := Vector2i(1, 1)

	d[t] = true
	d[[4, 5]] = true

	SS2D_IndexTuple.dict_validate(d, TYPE_BOOL)

	assert_eq(d.size(), 2)
	assert_true(d.has(t))
	assert_true(d.has(Vector2i(4, 5)))


func test_array() -> void:
	var t1 := Vector2i(5, 3)
	var t2 := Vector2i(3, 7)
	var arr: Array[Vector2i] = [ t1, t2 ]

	assert_true(SS2D_IndexTuple.array_has(arr, t1))
	assert_true(SS2D_IndexTuple.array_has(arr, SS2D_IndexTuple.flip_elements(t1)))
	assert_true(SS2D_IndexTuple.array_has(arr, Vector2(3, 7)))
	assert_true(SS2D_IndexTuple.array_has(arr, SS2D_IndexTuple.flip_elements(t2)))

	assert_eq(SS2D_IndexTuple.array_find(arr, t1), 0)
	assert_eq(SS2D_IndexTuple.array_find(arr, SS2D_IndexTuple.flip_elements(t1)), 0)
	assert_eq(SS2D_IndexTuple.array_find(arr, Vector2(3, 7)), 1)
	assert_eq(SS2D_IndexTuple.array_find(arr, SS2D_IndexTuple.flip_elements(t2)), 1)
