extends "res://addons/gut/test.gd"


func test_import_open():
	var legacy = generate_legacy_shape(false)
	var new_shape = SS2D_Shape_Open.new()
	add_child_autofree(new_shape)
	new_shape.editor_debug = false

	# This should fail, as the shape is closed
	#legacy.closed_shape = true
	#new_shape.import_from_legacy(legacy)
	#assert_ne(legacy.editor_debug, new_shape.editor_debug)

	# This should succeed, as the shape is NOT closed
	#legacy.closed_shape = false
	new_shape.import_from_legacy(legacy)

	# Test property Equality
	assert_eq(legacy.editor_debug, new_shape.editor_debug, "Editor Debug")
	assert_eq(legacy.flip_edges, new_shape.flip_edges, "Flip Edges")
	assert_eq(legacy.draw_edges, new_shape.render_edges, "Render Edges")
	assert_eq(legacy.tessellation_stages, new_shape.tessellation_stages, "Tess Stages")
	assert_eq(legacy.tessellation_tolerence, new_shape.tessellation_tolerence, "Tess Tolerence")
	assert_eq(legacy.collision_bake_interval, new_shape.curve_bake_interval, "Bake Int")
	assert_eq(legacy.collision_polygon_node, new_shape.collision_polygon_node_path, "Col Node Path")

	# Point Test
	assert_eq(legacy.get_point_count(), new_shape.get_point_count(), "Point Count")
	for i in range(0, legacy.get_point_count(), 1):
		var p1 = legacy.get_point_position(i)
		var key = new_shape.get_point_key_at_index(i)
		var p2 = new_shape.get_point_position(key)
		assert_eq(p1, p2)
		assert_eq(legacy.get_point_in(i), new_shape.get_point_in(key))
		assert_eq(legacy.get_point_out(i), new_shape.get_point_out(key))
		assert_eq(legacy.get_point_texture_index(i), new_shape.get_point_texture_index(key))
		assert_eq(legacy.get_point_texture_flip(i), new_shape.get_point_texture_flip(key))
		assert_eq(legacy.get_point_width(i), new_shape.get_point_width(key))


func test_import_closed():
	var legacy = generate_legacy_shape(true)
	var new_shape = SS2D_Shape_Closed.new()
	add_child_autofree(new_shape)
	new_shape.editor_debug = false

	# This should fail, as the shape is NOT closed
	#legacy.closed_shape = false
	#new_shape.import_from_legacy(legacy)
	#assert_ne(legacy.editor_debug, new_shape.editor_debug)

	# This should succeed, as the shape is closed
	#legacy.closed_shape = true
	new_shape.import_from_legacy(legacy)

	# Test property Equality
	assert_eq(legacy.editor_debug, new_shape.editor_debug, "Editor Debug")
	assert_eq(legacy.flip_edges, new_shape.flip_edges, "Flip Edges")
	assert_eq(legacy.draw_edges, new_shape.render_edges, "Render Edges")
	assert_eq(legacy.tessellation_stages, new_shape.tessellation_stages, "Tess Stages")
	assert_eq(legacy.tessellation_tolerence, new_shape.tessellation_tolerence, "Tess Tolerence")
	assert_eq(legacy.collision_bake_interval, new_shape.curve_bake_interval, "Bake Int")
	assert_eq(legacy.collision_polygon_node, new_shape.collision_polygon_node_path, "Col Node Path")

	# Point Test
	assert_eq(legacy.get_point_count(), new_shape.get_point_count(), "Point Count")
	var point_count = legacy.get_point_count()
	for i in range(0, point_count, 1):
		var p1 = legacy.get_point_position(i)
		var key = new_shape.get_point_key_at_index(i)
		var p2 = new_shape.get_point_position(key)
		var s = "IDX:%s/%s" % [i, point_count - 1]
		assert_eq(p1, p2, s)
		# Ignore first point for now
		if i != 0:
			assert_eq(legacy.get_point_in(i), new_shape.get_point_in(key), s)
			assert_eq(legacy.get_point_out(i), new_shape.get_point_out(key), s)
			assert_eq(legacy.get_point_texture_index(i), new_shape.get_point_texture_index(key), s)
			assert_eq(legacy.get_point_texture_flip(i), new_shape.get_point_texture_flip(key), s)
			assert_eq(legacy.get_point_width(i), new_shape.get_point_width(key), s)

	# First point values of new shape will be same as the final point values of legacy
	var i = point_count - 1
	var key = new_shape.get_point_key_at_index(0)
	var s = "IDX:0"
	assert_eq(legacy.get_point_in(i), new_shape.get_point_in(key), s)
	assert_eq(legacy.get_point_out(i), new_shape.get_point_out(key), s)
	assert_eq(legacy.get_point_texture_index(i), new_shape.get_point_texture_index(key), s)
	assert_eq(legacy.get_point_texture_flip(i), new_shape.get_point_texture_flip(key), s)
	assert_eq(legacy.get_point_width(i), new_shape.get_point_width(key), s)


func generate_legacy_shape(closed: bool) -> RMSmartShape2D:
	var legacy = RMSmartShape2D.new()
	add_child_autofree(legacy)
	var points = generate_points()
	legacy.add_points_to_curve(points)
	assert_eq(legacy.get_point_count(), points.size())

	legacy.editor_debug = true
	legacy.flip_edges = true
	legacy.draw_edges = false
	legacy.tessellation_stages = 3
	legacy.tessellation_tolerence = 8
	legacy.collision_bake_interval = 6
	legacy.collision_polygon_node = NodePath("./derp")

	legacy.set_point_in(2, Vector2(10, 10))
	legacy.set_point_out(2, Vector2(-10, -10))

	legacy.set_point_in(4, Vector2(20, 20))
	legacy.set_point_out(4, Vector2(-10, 15))

	legacy.set_point_in(points.size() - 1, Vector2(30, 30))
	legacy.set_point_out(points.size() - 1, Vector2(15, -5))

	legacy.set_point_in(0, Vector2(12, -15))
	legacy.set_point_out(0, Vector2(-13, 5))

	legacy.set_point_width(1, 5.3)
	legacy.set_point_texture_flip(2, false)
	legacy.set_point_texture_flip(3, true)
	legacy.set_point_texture_index(4, 2)
	legacy.set_point_texture_index(1, -2)

	legacy.closed_shape = closed

	return legacy


func generate_points() -> Array:
	return [
		Vector2(0, 0),
		Vector2(10, 10),
		Vector2(20, 20),
		Vector2(30, 30),
		Vector2(40, 40),
		Vector2(50, 50),
		Vector2(60, 60),
		Vector2(70, 70)
	]
