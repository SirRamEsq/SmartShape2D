extends "res://addons/gut/test.gd"
var TEST_TEXTURE = preload("res://gut/unit/test.png")
var n_right = Vector2(1, 0)
var n_left = Vector2(-1, 0)
var n_down = Vector2(0, 1)
var n_up = Vector2(0, -1)

func test_get_meta_material_to_indicies_simple_squareish_shape():
	var verts = [
		Vector2(-10, -10), # 0
		Vector2(0, -15), # 1
		Vector2(10, -10), # 2
		Vector2(10, 10), # 3
		Vector2(0, 15), # 4
		Vector2(-10, 10) # 5
		# Is not considered closed
		# No vector here matches the left normal (0, -1)
	]
	# Create shape material with 4 quadrants of normal range
	var shape_material = create_shape_material_with_equal_normal_ranges(4)
	var normals = [n_right, n_up, n_left, n_down]

	# Ensure that the correct materials are given for the correct normals
	for i in range(0, normals.size(), 1):
		var n = normals[i]
		var edges = shape_material.get_edge_meta_materials(n)
		assert_not_null(edges)
		assert_eq(1, edges.size())

	var mappings = SS2D_Shape_Base.get_meta_material_to_indicies(shape_material, verts)
	var mappings_materials = []
	for mapping in mappings:
		mappings_materials.push_back(mapping.meta_material)
	# No vector matches the left normal (0, -1)
	assert_eq(mappings.size(), 3)
	assert_false(mappings_materials.has(shape_material.get_edge_meta_materials(n_left)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_right)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_up)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_down)[0]))

	assert_eq(mappings[0].indicies, [0,1,2])
	assert_eq(mappings[1].indicies, [2,3])
	assert_eq(mappings[2].indicies, [3,4,5])

func test_get_meta_material_to_indicies_complex_shape():
	var verts = [
		Vector2(-10, -10), # 0
		Vector2(0, -10), # 1
		Vector2(0, -15), # 2
		Vector2(10, -15), # 3
		Vector2(10, -10), # 4
		Vector2(15, -10), # 5
		Vector2(15, 10), # 6
		Vector2(-10, 10) # 7
		# Is not considered closed
		# No vector here matches the left normal (0, -1)
	]
	# Create shape material with 4 quadrants of normal range
	var shape_material = create_shape_material_with_equal_normal_ranges(4)
	var mappings = SS2D_Shape_Base.get_meta_material_to_indicies(shape_material, verts)
	var mappings_materials = []
	for mapping in mappings:
		mappings_materials.push_back(mapping.meta_material)
	# Should contain the meta_materials of all 4 normal ranges
	assert_eq(mappings.size(), 4)
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_left)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_right)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_up)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_down)[0]))

	assert_eq(mappings[0].indicies, [0,1,3,4])
	assert_eq(mappings[1].indicies, [2,3])
	assert_eq(mappings[2].indicies, [3,4,5])



func create_shape_material_with_equal_normal_ranges(edge_materials_count:int=4)->SS2D_Material_Shape:
	var edge_materials = []
	var edge_materials_meta = []
	for i in range(0, edge_materials_count, 1):
		var edge_mat = SS2D_Material_Edge.new()
		edge_materials.push_back(edge_mat)
		edge_mat.textures = [TEST_TEXTURE]

		var edge_mat_meta = SS2D_Material_Edge_Metadata.new()
		edge_materials_meta.push_back(edge_mat_meta)
		var division = 360.0 / edge_materials_count
		var offset = -45
		var normal_range = SS2D_NormalRange.new((division * i) + offset, division)
		edge_mat_meta.edge_material = edge_mat
		edge_mat_meta.normal_range = normal_range
		assert_not_null(edge_mat_meta.edge_material)

	#for e in edge_materials_meta:
		#print(e.normal_range)

	var s_m = SS2D_Material_Shape.new()
	s_m.set_edge_meta_materials(edge_materials_meta)
	return s_m
