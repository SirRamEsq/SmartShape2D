extends "res://addons/gut/test.gd"

var TEST_TEXTURE = load("res://gut/unit/test.png")


func test_consecutive_quads():
	var big_exclude = [2, 8, 34, 56, 78, 99, 123, 154, 198, 234]
	assert_eq(SS2D_Edge.get_consecutive_quads_for_mesh(generate_quads(256)).size(), 1)
	assert_eq(
		SS2D_Edge.get_consecutive_quads_for_mesh(generate_quads(256, null, big_exclude)).size(),
		big_exclude.size() + 1
	)

	var quads = generate_quads(16, null, [4, 8])
	var quad_arrays = SS2D_Edge.get_consecutive_quads_for_mesh(quads)
	assert_eq(quad_arrays.size(), 3)
	var total_quad_count = 0
	for quad_array in quad_arrays:
		for quad in quad_array:
			total_quad_count += 1
	assert_eq(quads.size(), total_quad_count)
	assert_eq(quad_arrays[0].size(), 4)
	assert_eq(quad_arrays[1].size(), 4)
	assert_eq(quad_arrays[2].size(), 8)


func test_generate_mesh_from_quad_sequence():
	var quad_extent = Vector2(6.0, 6.0)
	var quads = generate_quads(16, TEST_TEXTURE, [4, 8], quad_extent)
	var quad_arrays = SS2D_Edge.get_consecutive_quads_for_mesh(quads)

	for quad_array in quad_arrays:
		var am = SS2D_Edge.generate_array_mesh_from_quad_sequence(quad_array, false)
		assert_eq(am.get_surface_count(), 1)
		var arrays = am.surface_get_arrays(0)
		var verts = arrays[Mesh.ARRAY_VERTEX]
		var uvs = arrays[Mesh.ARRAY_TEX_UV]
		var indicies = arrays[Mesh.ARRAY_INDEX]
		var normals = arrays[Mesh.ARRAY_NORMAL]
		var first_q = quad_array[0]
		var last_q = quad_array[quad_array.size() - 1]
		assert_ne(indicies.size(), 0)
		assert_eq(verts[0], SS2D_Common_Functions.to_vector3(first_q.pt_a))
		assert_eq(verts[verts.size() - 1], SS2D_Common_Functions.to_vector3(last_q.pt_d))
		assert_eq(verts.size(), uvs.size())
		assert_eq(verts.size(), normals.size())
	#var texture_distance_per_quad = quad_extent / TEST_TEXTURE.get_size()
	#for uv in uvs:
	#assert_true(uv.y == 1.0 or uv.y == 0.0, "UV is 1 or 0")
	#var remainder = fmod(uv.x, texture_distance_per_quad.x)
	#gut.p(uv)
	#gut.p(remainder)
	#assert_eq(remainder, 0.0)
	#gut.p(uvs)


func generate_quads(
	amnt: int,
	tex: Texture = null,
	indicies_to_change: Array = [],
	extents: Vector2 = Vector2(16.0, 16.0)
) -> Array:
	var quads = []
	var a = Vector2(-extents.x, -extents.y)
	var b = Vector2(-extents.x, extents.y)
	var c = Vector2(extents.x, extents.y)
	var d = Vector2(extents.x, -extents.y)
	var t = tex
	var tn = null
	var f = false

	for i in range(0, amnt, 1):
		var offset = Vector2(extents.x * 2 * i, 0)
		if indicies_to_change.has(i):
			f = not f
		quads.push_back(SS2D_Quad.new(a + offset, b + offset, c + offset, d + offset, t, tn, f))
	return quads
