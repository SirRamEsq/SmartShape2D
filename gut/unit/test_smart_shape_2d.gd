extends "res://addons/gut/test.gd"


class z_sort:
	var z_index: int = 0

	func _init(z: int):
		z_index = z


func test_z_sort():
	var a = [z_sort.new(3), z_sort.new(5), z_sort.new(0), z_sort.new(-12)]
	a = SmartShape2D.sort_by_z(a)
	assert_eq(a[0].z_index, -12)
	assert_eq(a[1].z_index, 0)
	assert_eq(a[2].z_index, 3)
	assert_eq(a[3].z_index, 5)


func test_are_points_clockwise():
	var shape = SmartShape2D.new()
	add_child_autofree(shape)
	var points_clockwise = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	var points_c_clockwise = points_clockwise.duplicate()
	points_c_clockwise.invert()

	shape.add_points_to_curve(points_clockwise)
	assert_true(shape.are_points_clockwise())

	shape.clear_points()
	shape.add_points_to_curve(points_c_clockwise)
	assert_false(shape.are_points_clockwise())


func test_curve_duplicate():
	var shape = SmartShape2D.new()
	add_child_autofree(shape)
	shape.add_point_to_curve(Vector2(-10, -20))
	var points = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	shape.collision_bake_interval = 35.0
	var curve = shape.get_curve()

	assert_eq(shape.get_point_count(), curve.get_point_count())
	assert_eq(shape.collision_bake_interval, curve.bake_interval)
	shape.collision_bake_interval = 25.0
	assert_ne(shape.collision_bake_interval, curve.bake_interval)

	curve.add_point(points[0])
	assert_ne(shape.get_point_count(), curve.get_point_count())
	shape.set_curve(curve)
	assert_eq(shape.get_point_count(), curve.get_point_count())
