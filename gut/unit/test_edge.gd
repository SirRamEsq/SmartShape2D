extends "res://addons/gut/test.gd"


func test_consecutive_quads():
	var big_exclude = [2, 8, 34, 56, 78, 99, 123, 154, 198, 234]
	assert_eq(RMSS2D_Edge.get_consecutive_quads_for_mesh(generate_quads(256)).size(), 1)
	assert_eq(
		RMSS2D_Edge.get_consecutive_quads_for_mesh(generate_quads(256, big_exclude)).size(),
		big_exclude.size() + 1
	)

	var quads = generate_quads(16, [4, 8])
	var quad_arrays = RMSS2D_Edge.get_consecutive_quads_for_mesh(quads)
	assert_eq(quad_arrays.size(), 3)
	var total_quad_count = 0
	for quad_array in quad_arrays:
		for quad in quad_array:
			total_quad_count += 1
	assert_eq(quads.size(), total_quad_count)
	assert_eq(quad_arrays[0].size(), 4)
	assert_eq(quad_arrays[1].size(), 4)
	assert_eq(quad_arrays[2].size(), 8)


func generate_quads(amnt: int, indicies_to_change: Array = []) -> Array:
	var quads = []
	var a = Vector2(-16, -10)
	var d = Vector2(16, -16)
	var c = Vector2(16, 16)
	var b = Vector2(-16, 16)
	var t = null
	var tn = null
	var f = false

	for i in range(0, amnt, 1):
		var offset = Vector2(32 * i, 0)
		if indicies_to_change.has(i):
			f = not f
		quads.push_back(RMSS2D_Quad.new(a + offset, b + offset, c + offset, d + offset, t, tn, f))
	return quads
