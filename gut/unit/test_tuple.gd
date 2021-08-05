extends "res://addons/gut/test.gd"

const TUP = preload("res://addons/rmsmartshape/lib/tuple.gd")


func test_equality():
	var t1 = TUP.create_tuple(5, 3)
	var t2 = TUP.create_tuple(5, 3)
	var t3 = TUP.create_tuple(3, 5)
	var t4 = TUP.create_tuple(3, 7)
	var t5 = TUP.create_tuple(0, 5)
	assert_true(TUP.tuples_are_equal(t1, t2))
	assert_true(TUP.tuples_are_equal(t1, t3))
	assert_true(TUP.tuples_are_equal(t2, t3))
	assert_false(TUP.tuples_are_equal(t3, t4))
	assert_false(TUP.tuples_are_equal(t2, t5))


func test_find():
	var t1 = TUP.create_tuple(5, 3)
	var t2 = TUP.create_tuple(5, 3)
	var t3 = TUP.create_tuple(3, 5)
	var t4 = TUP.create_tuple(1, 0)
	var ta = [t1, t2, t3, t4]
	assert_eq(0, TUP.find_tuple_in_array_of_tuples(ta, t1))
	assert_eq(0, TUP.find_tuple_in_array_of_tuples(ta, t2))
	assert_eq(0, TUP.find_tuple_in_array_of_tuples(ta, t3))
	assert_eq(3, TUP.find_tuple_in_array_of_tuples(ta, t4))
	assert_eq(-1, TUP.find_tuple_in_array_of_tuples(ta, [7, 8]))


func test_get_other_value():
	var t1 = TUP.create_tuple(3, 5)
	var t2 = TUP.create_tuple(1, 0)
	assert_eq(5, TUP.get_other_value_from_tuple(t1, 3))
	assert_eq(3, TUP.get_other_value_from_tuple(t1, 5))
	assert_eq(1, TUP.get_other_value_from_tuple(t2, 0))
	assert_eq(0, TUP.get_other_value_from_tuple(t2, 1))
	assert_eq(-1, TUP.get_other_value_from_tuple(t1, 9))
	assert_eq(-1, TUP.get_other_value_from_tuple(t2, 9))


func test_is_tuple():
	assert_true(TUP.is_tuple([0, 2]))
	assert_true(TUP.is_tuple([1, 0]))
	assert_true(TUP.is_tuple([-1000, 1000]))
	assert_false(TUP.is_tuple([2, 0, 1]))
	assert_false(TUP.is_tuple([1]))
	assert_false(TUP.is_tuple("herpderp"))
	assert_false(TUP.is_tuple(31337))
