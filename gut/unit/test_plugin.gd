extends "res://addons/gut/test.gd"

var FUNC = load("res://addons/rmsmartshape/plugin-functionality.gd")


func test_intersect_control_point():
	var shape = RMSS2D_Shape_Closed.new()
	add_child_autofree(shape)
	var vert_p = Vector2(100, 100)
	var key = shape.add_point(vert_p)
	shape.set_point_in(key, Vector2(-32, 0))
	shape.set_point_out(key, Vector2(32, 0))
	var et = Transform2D()
	var grab = 16.0
	var f1 = funcref(FUNC, "get_intersecting_control_point_out")
	var f2 = funcref(FUNC, "get_intersecting_control_point_in")
	var functions = [f1, f2]
	var f_name = ["out", "in"]
	var f_offset = [Vector2(32, 0), Vector2(-32, 0)]
	var intersect = []
	for i in range(0, functions.size(), 1):
		var f = functions[i]
		var s = f_name[i]
		var o = f_offset[i]
		shape.position = Vector2(0, 0)
		intersect = f.call_func(shape, et, Vector2(0, 0), grab)
		assert_eq(intersect.size(), 0, s)
		intersect = f.call_func(shape, et, vert_p, grab)
		assert_eq(intersect.size(), 0, s)
		intersect = f.call_func(shape, et, vert_p + o - Vector2(grab, 0), grab)
		assert_eq(intersect.size(), 1, s)
		intersect = f.call_func(shape, et, vert_p + o - Vector2(grab + 1, 0), grab)
		assert_eq(intersect.size(), 0, s)
		intersect = f.call_func(shape, et, vert_p + o + Vector2(grab, 0), grab)
		assert_eq(intersect.size(), 1, s)
		intersect = f.call_func(shape, et, vert_p + o + Vector2(grab + 1, 0), grab)
		assert_eq(intersect.size(), 0, s)

		shape.position.x = 1
		intersect = f.call_func(shape, et, vert_p + o + Vector2(grab + 1, 0), grab)
		assert_eq(intersect.size(), 1, s)
