extends GutTest

# This unit test is semi-useful.
# It is there and can ensure that collisions won't break, however the tests are difficult to
# understand reproduce since there is non-trivial math and thus ugly numbers involved.
# These numbers were generated and printed from the collisions.tscn example and should cover all
# edge-cases, i.e. normal corners and sharp corners, both inside and outside.
# To make it a little more understandable, the polygon points were snapped to a 10x10 grid and
# translated to (0, 0).

const TEST_POLYGON_CLOSED: PackedVector2Array = [
	Vector2(0.0, 0.0),
	Vector2(-50.0, -30.0),
	Vector2(30.0, -80.0),
	Vector2(-50.0, -130.0),
	Vector2(50.0, -130.0),
	Vector2(160.0, -80.0),
	Vector2(50.0, -30.0),
	Vector2(0.0, 0.0)
]

const TEST_POLYGON_OPEN: PackedVector2Array = [
	Vector2(0.0, 0.0),
	Vector2(-50.0, 30.0),
	Vector2(-100.0, 0.0),
	Vector2(-20.0, -50.0),
	Vector2(-100.0, -100.0),
	Vector2(0.0, -100.0),
	Vector2(110.0, -50.0),
	Vector2(40.0, -10.0)
]


# collisions.tscn - "closed_default"
func test_generate_filled() -> void:
	# Unchanged
	assert_points_equal(setup_gen(0, 100).generate_filled(TEST_POLYGON_CLOSED), TEST_POLYGON_CLOSED)  # collision_size should be ignored here
	# Inflate
	assert_points_equal(setup_gen(20, 10).generate_filled(TEST_POLYGON_CLOSED), [
		Vector2(180.0, -92.87827),
		Vector2(180.0, -67.12173),
		Vector2(59.31312, -12.26407),
		Vector2(0.0, 23.32381),
		Vector2(-88.29287, -29.65191),
		Vector2(-7.735939, -80.0),
		Vector2(-73.37961, -121.0273),
		Vector2(-65.07034, -150.0),
		Vector2(54.33218, -150.0)
	])

	# Deflate
	assert_points_equal(setup_gen(-20, 10).generate_filled(TEST_POLYGON_CLOSED), [
		Vector2(45.66781, -110.0),
		Vector2(111.6678, -80.00002),
		Vector2(40.6869, -47.73595),
		Vector2(0.0, -23.32382),
		Vector2(-11.70713, -30.34809),
		Vector2(67.73592, -80.0),
		Vector2(19.73593, -110.0)
	])


# collisions.tscn - "open_default"
func test_generate_open() -> void:
	# Unchanged
	assert_points_equal(setup_gen(0, 0).generate_open(TEST_POLYGON_OPEN), TEST_POLYGON_OPEN)
	# Inflate
	assert_points_equal(setup_gen(20, 10).generate_open(TEST_POLYGON_OPEN), [
		Vector2(129.4129, -63.14512),
		Vector2(130.5443, -38.70459),
		Vector2(49.92278, 7.364868),
		Vector2(44.96138, -1.317574),
		Vector2(120.2721, -44.35232),
		Vector2(119.7065, -56.57257),
		Vector2(2.1661, -110.0),
		Vector2(-107.5352, -110.0),
		Vector2(-111.6898, -95.51366),
		Vector2(-38.86796, -50.0),
		Vector2(-119.1464, 0.174042),
		Vector2(-50.0, 41.66191),
		Vector2(5.144958, 8.574944),
		Vector2(10.28992, 17.14986),
		Vector2(-50.0, 53.32381),
		Vector2(-138.2929, 0.348091),
		Vector2(-57.73592, -50.00001),
		Vector2(-123.3796, -91.0273),
		Vector2(-115.0704, -120.0),
		Vector2(4.332191, -120.0)])

	# Deflate
	assert_points_equal(setup_gen(-10, 10).generate_open(TEST_POLYGON_OPEN), [
		Vector2(81.95457, -51.76333),
		Vector2(82.23744, -45.6532),
		Vector2(35.03862, -18.68243),
		Vector2(30.07722, -27.36487),
		Vector2(66.13515, -47.96941),
		Vector2(-4.332176, -80.0),
		Vector2(-30.26408, -80.0),
		Vector2(17.73592, -50.0),
		Vector2(-61.70715, -0.348099),
		Vector2(-50.00001, 6.676193),
		Vector2(-10.28992, -17.14986),
		Vector2(-5.144958, -8.574944),
		Vector2(-50.0, 18.33809),
		Vector2(-80.85357, -0.174049),
		Vector2(-1.132042, -50.0),
		Vector2(-53.54295, -82.75681),
		Vector2(-51.46564, -89.99999),
		Vector2(-2.166092, -90.0)
	])


# collisions.tscn - "closed_hollow"
func test_generate_hollow() -> void:
	# Inflate
	assert_points_equal(setup_gen(20, 10).generate_hollow(TEST_POLYGON_CLOSED), [
		Vector2(55.41523, -155.0),
		Vector2(-68.83793, -155.0),
		Vector2(-79.22451, -118.7841),
		Vector2(-17.16991, -80.00002),
		Vector2(-97.86608, -29.56489),
		Vector2(0.0, 29.15475),
		Vector2(61.64136, -7.83007),
		Vector2(185.0, -63.90217),
		Vector2(185.0, -96.09783),
		Vector2(55.41523, -155.0),
		Vector2(53.24914, -145.0),
		Vector2(175.0, -89.6587),
		Vector2(175.0, -70.3413),
		Vector2(56.9848, -16.69804),
		Vector2(0.0, 17.49286),
		Vector2(-78.71965, -29.73893),
		Vector2(1.698059, -80.00002),
		Vector2(-67.5347, -123.2705),
		Vector2(-61.30276, -145.0),
		Vector2(53.24914, -145.0)
	])

	# Deflate
	assert_points_equal(setup_gen(-20, 10).generate_hollow(TEST_POLYGON_CLOSED), [
		Vector2(2.301941, -115.0),
		Vector2(58.30194, -80.0),
		Vector2(-21.28036, -30.26107),
		Vector2(0.0, -17.49286),
		Vector2(43.01517, -43.30196),
		Vector2(123.7509, -80.00002),
		Vector2(46.75086, -115.0),
		Vector2(2.301941, -115.0),
		Vector2(37.16991, -105.0),
		Vector2(44.58478, -105.0),
		Vector2(99.58476, -80.00002),
		Vector2(38.35862, -52.16993),
		Vector2(0.0, -29.15476),
		Vector2(-2.13393, -30.43511),
		Vector2(77.16991, -80.0),
		Vector2(37.16991, -105.0)])



func test_simple_offset_open_polygon_miter() -> void:
	# Unchanged
	assert_eq(SS2D_CollisionGen.simple_offset_open_polygon_miter(TEST_POLYGON_OPEN, 0).size(), 0)
	# Inflate
	assert_points_equal(SS2D_CollisionGen.simple_offset_open_polygon_miter(TEST_POLYGON_OPEN, 20), [
		Vector2(10.28992, 17.14986),
		Vector2(-50.0, 53.32381),
		Vector2(-138.2929, 0.348091),
		Vector2(-57.73592, -50.0),
		Vector2(-123.3796, -91.02731),
		Vector2(-115.0703, -120.0),
		Vector2(4.332184, -120.0),
		Vector2(129.4129, -63.14513),
		Vector2(130.5443, -38.70458),
		Vector2(49.92278, 7.364861)
	])

	# Deflate
	assert_points_equal(SS2D_CollisionGen.simple_offset_open_polygon_miter(TEST_POLYGON_OPEN, -10), [
		Vector2(-5.144958, -8.574928),
		Vector2(-50.0, 18.3381),
		Vector2(-80.85356, -0.174042),
		Vector2(-1.132034, -50.0),
		Vector2(-65.13203, -89.99999),
		Vector2(-2.166092, -90.0),
		Vector2(88.06758, -48.9847),
		Vector2(35.0386, -18.68243)
	])


func test_insufficient_points() -> void:
	var points0 := PackedVector2Array()
	var points1 := PackedVector2Array([Vector2(0, 0)])
	var points2 := PackedVector2Array([Vector2(0, 0), Vector2(1, 1)])
	var gen := setup_gen(100, 100)

	for i: PackedVector2Array in [ points0, points1, points2 ]:
		assert_eq(gen.generate_hollow(i).size(), 0)
		assert_eq(gen.generate_filled(i).size(), 0)

	assert_eq(gen.generate_open(points0).size(), 0)
	assert_eq(gen.generate_open(points1).size(), 0)
	assert_eq(SS2D_CollisionGen.simple_offset_open_polygon_miter(points0, 100).size(), 0)
	assert_eq(SS2D_CollisionGen.simple_offset_open_polygon_miter(points1, 100).size(), 0)


static func setup_gen(offset: float, size: float) -> SS2D_CollisionGen:
	var gen := SS2D_CollisionGen.new()
	gen.collision_offset = offset
	gen.collision_size = size
	return gen


func assert_points_equal(points: PackedVector2Array, expected: PackedVector2Array) -> void:
	assert_eq(points.size(),  expected.size())

	points = reorder_points(points, expected[0])

	for i in mini(points.size(), expected.size()):
		assert_true(points[i].is_equal_approx(expected[i]), "Point mismatch at index %d: %s != %s" % [i, points[i], expected[i]])


## Geometry2D.offset_polygon/polyline() may reorder points so re-reorder them to a known start point.
func reorder_points(points: PackedVector2Array, known_start_point: Vector2) -> PackedVector2Array:
	for i in points.size():
		if points[i].is_equal_approx(known_start_point):
			if i == 0:
				return points

			# reorder points so that the known start point is at the beginning
			var reordered := points.slice(i)
			reordered.append_array(points.slice(0, i))
			return reordered

	fail_test("Known point not found")
	return points
