extends "res://addons/gut/test.gd"

var TEST_TEXTURE: Texture2D = preload("res://tests/unit/test.png")


class z_sort:
	var z_index: int = 0

	func _init(z: int) -> void:
		z_index = z


func test_z_sort() -> void:
	var a := [z_sort.new(3), z_sort.new(5), z_sort.new(0), z_sort.new(-12)]
	a = SS2D_Shape.sort_by_z_index(a)
	assert_eq(a[0].z_index, -12)
	assert_eq(a[1].z_index, 0)
	assert_eq(a[2].z_index, 3)
	assert_eq(a[3].z_index, 5)


func test_on_segment() -> void:
	var p1 := Vector2(0, 0)
	var p2 := Vector2(-100, 0)
	var p3 := Vector2(100, 0)
	var p4 := Vector2(100, 10)
	var p5 := Vector2(100, 20)
	assert_true(SS2D_Shape.on_segment(p2, p1, p3))
	assert_false(SS2D_Shape.on_segment(p2, p3, p1))
	assert_false(SS2D_Shape.on_segment(p1, p2, p3))
	assert_false(SS2D_Shape.on_segment(p1, p3, p2))
	assert_false(SS2D_Shape.on_segment(p3, p2, p1))
	assert_true(SS2D_Shape.on_segment(p3, p1, p2))

	assert_true(SS2D_Shape.on_segment(p3, p4, p5))
	assert_false(SS2D_Shape.on_segment(p3, p5, p4))

	assert_true(SS2D_Shape.on_segment(p1, p1, p1))


func test_are_points_clockwise() -> void:
	var shape := SS2D_Shape.new()
	var pa := shape.get_point_array()
	add_child_autofree(shape)
	var points_clockwise := [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	var points_c_clockwise := points_clockwise.duplicate()
	points_c_clockwise.reverse()

	pa.add_points(points_clockwise)

	assert_true(pa.are_points_clockwise())

	pa.clear()
	pa.add_points(points_c_clockwise)
	assert_false(pa.are_points_clockwise())


func test_invert_point_order() -> void:
	var shape := SS2D_Shape.new()
	add_child_autofree(shape)
	var pa := shape.get_point_array()
	var points := get_clockwise_points()
	var size := points.size()
	var last_idx := size - 1
	var keys := pa.add_points(points)
	pa.get_point(keys[0]).width = 5.0
	assert_eq(points[0], pa.get_point_at_index(0).position)
	assert_eq(points[last_idx], pa.get_point_at_index(last_idx).position)

	assert_eq(1.0, pa.get_point_at_index(last_idx).width)
	assert_eq(5.0, pa.get_point_at_index(0).width)

	pa.invert_point_order()

	assert_eq(5.0, pa.get_point_at_index(last_idx).width)
	assert_eq(1.0, pa.get_point_at_index(0).width)

	assert_eq(points[0], pa.get_point_at_index(last_idx).position)
	assert_eq(points[last_idx], pa.get_point_at_index(0).position)

	assert_eq(points[1], pa.get_point_at_index(last_idx - 1).position)
	assert_eq(points[last_idx - 1], pa.get_point_at_index(1).position)

	assert_eq(points[2], pa.get_point_at_index(last_idx - 2).position)
	assert_eq(points[last_idx - 2], pa.get_point_at_index(2).position)


# TODO Fix this test and flesh it out
#func test_duplicate():
#var shape = SS2D_Shape_Open.new()
#add_child_autofree(shape)
#var points = get_clockwise_points()
#shape.get_point_array().add_points(points)
#
#shape.set_point_width(0, 5.0)
#shape.set_point_width(2, 3.0)
#shape.set_point_width(5, 4.0)
#
#shape.set_point_texture_index(0, 1)
#shape.set_point_texture_index(2, 2)
#shape.set_point_texture_index(3, 3)
#shape.set_point_texture_index(5, 5)
#
#shape.set_point_texture_flip(1, true)
#shape.set_point_texture_flip(2, true)
#shape.set_point_texture_flip(4, true)
#
#var copy = shape.duplicate()
#add_child_autofree(copy)
#assert_ne(shape.get_curve(), copy.get_curve())
#assert_eq(shape.get_point_count(), copy.get_point_count())
#for i in range(-1, points.size(), 1):
#var s = "Test Point %s: " % i
#assert_eq(shape.get_point_width(i), copy.get_point_width(i), s + "Width")
#assert_eq(shape.get_point_texture_flip(i), copy.get_point_texture_flip(i), s + "Flip")
#assert_eq(
#shape.get_point_texture_index(i), copy.get_point_texture_index(i), s + "Index"
#)


func test_get_edge_meta_materials_one() -> void:
	var shape := SS2D_Shape.new()
	var pa := shape.get_point_array()
	assert_eq(pa.get_material_overrides().size(), 0)
	add_child_autofree(shape)
	assert_eq(pa.get_material_overrides().size(), 0)

	var edge_mat := SS2D_Material_Edge.new()
	edge_mat.textures = Array([TEST_TEXTURE], TYPE_OBJECT, "Texture2D", null)

	var edge_mat_meta := SS2D_Material_Edge_Metadata.new()
	var normal_range := SS2D_NormalRange.new(0, 360.0)
	edge_mat_meta.edge_material = edge_mat
	edge_mat_meta.normal_range = normal_range
	assert_not_null(edge_mat_meta.edge_material)

	var s_m := SS2D_Material_Shape.new()
	s_m.set_edge_meta_materials([edge_mat_meta])
	for e in s_m.get_edge_meta_materials(Vector2(1, 0)):
		assert_not_null(e)
		assert_not_null(e.edge_material)
		assert_eq(e, edge_mat_meta)
		assert_eq(e.edge_material, edge_mat)

	var points := get_clockwise_points()
	pa.add_points(points)
	assert_eq(pa.get_material_overrides().size(), 0)
	var mappings := SS2D_Shape.get_meta_material_index_mapping(s_m, points, false)

	# Should be 1 edge, as the normal range specified covers the full 360.0 degrees
	assert_eq(mappings.size(), 1, "Should be one EdgeData specified")
	for mapping in mappings:
		assert_not_null(mapping)
		assert_not_null(mapping.object)
		assert_eq(mapping.object.edge_material, edge_mat)


func test_get_edge_meta_materials_many() -> void:
	var shape := SS2D_Shape.new()
	add_child_autofree(shape)
	assert_eq(shape.get_point_array().get_material_overrides().size(), 0)

	var edge_materials_count := 4
	var edge_materials := []
	var edge_materials_meta: Array[SS2D_Material_Edge_Metadata] = []
	for i in range(0, edge_materials_count, 1):
		var edge_mat := SS2D_Material_Edge.new()
		edge_materials.push_back(edge_mat)
		edge_mat.textures = Array([TEST_TEXTURE], TYPE_OBJECT, "Texture2D", null)

		var edge_mat_meta := SS2D_Material_Edge_Metadata.new()
		edge_materials_meta.push_back(edge_mat_meta)
		var division := 360.0 / edge_materials_count
		var offset := -45
		var normal_range := SS2D_NormalRange.new((division * i) + offset, division)
		edge_mat_meta.edge_material = edge_mat
		edge_mat_meta.normal_range = normal_range
		assert_not_null(edge_mat_meta.edge_material)

	for e in edge_materials_meta:
		print(e.normal_range)

	var s_m := SS2D_Material_Shape.new()
	s_m.set_edge_meta_materials(edge_materials_meta)
	var n_right := Vector2(1, 0)
	var n_left := Vector2(-1, 0)
	var n_down := Vector2(0, 1)
	var n_up := Vector2(0, -1)
	var normals: Array[Vector2] = [n_right, n_up, n_left, n_down]

	# Ensure that the correct matierlas are given for the correct normals
	for i in range(0, normals.size(), 1):
		var n := normals[i]
		for e in s_m.get_edge_meta_materials(n):
			assert_not_null(e)
			assert_not_null(e.edge_material)
			assert_eq(e, edge_materials_meta[i])
			assert_eq(e.edge_material, edge_materials[i])

	var points := get_square_points()
	shape.get_point_array().add_points(points)

	assert_eq(shape.get_point_array().get_material_overrides().size(), 0)
	assert_eq(shape.get_point_array().get_vertices().size(), 6)
	assert_eq(s_m.get_all_edge_meta_materials().size(), edge_materials_meta.size())
	var mappings := SS2D_Shape.get_meta_material_index_mapping(s_m, points, false)
	assert_eq(mappings.size(), edge_materials_count, "Expecting %s materials" % edge_materials_count)
	var expected_indicies := [PackedInt32Array([0, 1, 2]), PackedInt32Array([2, 3]), PackedInt32Array([3, 4]), PackedInt32Array([4, 5])]
	for i in range(0, mappings.size(), 1):
		var mapping := mappings[i]
		assert_eq(expected_indicies[i], mapping.indicies, "Actual indicies match expected?")


var width_params := [1.0, 1.5, 0.5, 0.0, 10.0, -1.0]


func test_build_quad_from_point_width(width: float = use_parameters(width_params)) -> void:
	var shape := SS2D_Shape.new()
	add_child_autofree(shape)

	var pt_prev := Vector2(100, 100)
	var pt := Vector2(200, 100)
	var pt_next := Vector2(300, 100)
	var points: Array[Vector2] = [pt_prev, pt, pt_next]

	var c_scale := 1.0
	var c_offset := 0.0
	var c_extends := 0.0
	var delta := points[1] - points[0]
	var normal := Vector2(delta.y, -delta.x).normalized()
	var tex_size := TEST_TEXTURE.get_size()
	var vtx: Vector2 = normal * (tex_size * 0.5)

	var quad := SS2D_Shape.build_quad_from_two_points(
		pt,
		pt_next,
		TEST_TEXTURE,
		width * TEST_TEXTURE.get_size().y * c_scale,
		false,
		false,
		false,
		false,
		c_offset,
		c_extends,
		SS2D_Material_Edge.FITMODE.SQUISH_AND_STRETCH
	)
	var expected_points: Array[Vector2] = [
		pt + (width * vtx), pt - (width * vtx), pt_next - (width * vtx), pt_next + (width * vtx)
	]
	assert_eq(quad.pt_a, expected_points[0])
	assert_eq(quad.pt_b, expected_points[1])
	assert_eq(quad.pt_c, expected_points[2])
	assert_eq(quad.pt_d, expected_points[3])


func test_get_width_for_tessellated_point() -> void:
	var shape := SS2D_Shape.new()
	var pa := shape.get_point_array()
	add_child_autofree(shape)
	var points := get_clockwise_points()
	pa.add_points(points)
	var idx1 := 1
	var idx2 := 2
	var k1 := pa.get_point_key_at_index(idx1)
	var k2 := pa.get_point_key_at_index(idx2)
	var w1 := 5.3
	var w2 := 3.15
	var w_average := (w1 + w2) / 2.0
	pa.get_point(k1).width = w1
	pa.get_point(k2).width = w2
	var point_in := Vector2(-16, 0)
	var point_out := point_in * -1
	pa.set_point_in(k1, point_in)
	pa.set_point_out(k1, point_out)
	pa.set_point_in(k2, point_in)
	pa.set_point_out(k2, point_out)

	var tmapping := pa.get_tesselation_vertex_mapping()
	var t_idx_1 := tmapping.vertex_to_tess_indices(idx1)[0]
	var t_idx_2 := tmapping.vertex_to_tess_indices(idx2)[0]
	var test_t_idx := int(floor((t_idx_1 + t_idx_2) / 2.0))

	assert_ne(t_idx_1, t_idx_2)
	assert_ne(test_t_idx, t_idx_1)
	assert_ne(test_t_idx, t_idx_2)
	var test_width := shape._get_width_for_tessellated_point(points, test_t_idx)
	assert_almost_eq(test_width, w_average, 0.15)


func get_clockwise_points() -> PackedVector2Array:
	return [
		Vector2(0, 0),
		Vector2(50, -50),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(-50, 150),
		Vector2(-100, 100)
	]


func get_square_points() -> Array:
	return [
		Vector2(-100, -100),
		Vector2(0, -100),
		Vector2(100, -100),
		Vector2(100, 100),
		Vector2(-100, 100),
		Vector2(-100, -100)
	]
