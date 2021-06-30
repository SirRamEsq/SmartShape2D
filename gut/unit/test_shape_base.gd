extends "res://addons/gut/test.gd"
var TEST_TEXTURE = preload("res://gut/unit/test.png")
var n_right = Vector2(1, 0)
var n_left = Vector2(-1, 0)
var n_down = Vector2(0, 1)
var n_up = Vector2(0, -1)

func test_get_meta_material_index_mapping_simple_squareish_shape():
	var verts = [
		Vector2(-10, -10), # 0
		Vector2(0, -15), # 1
		Vector2(10, -10), # 2
		Vector2(10, 10), # 3
		Vector2(0, 15), # 4
		Vector2(-10, 10) # 5
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

	var mappings = SS2D_Shape_Base.get_meta_material_index_mapping(shape_material, verts)
	var mappings_materials = []
	for mapping in mappings:
		mappings_materials.push_back(mapping.object)
	# No vector matches the left normal
	assert_eq(mappings.size(), 3)
	assert_false(mappings_materials.has(shape_material.get_edge_meta_materials(n_left)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_right)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_up)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_down)[0]))

	assert_eq(mappings[0].indicies, [0,1,2])
	assert_eq(mappings[1].indicies, [2,3])
	assert_eq(mappings[2].indicies, [3,4,5])

func test_get_meta_material_index_mapping_complex_shape():
	var verts = [
		# Each point forms a right angle,
		# Should return 7 mappings, each with two indicies (one edge)
		Vector2(-10, -10), # 0
		Vector2(0, -10), # 1
		Vector2(0, -15), # 2
		Vector2(10, -15), # 3
		Vector2(10, -10), # 4
		Vector2(15, -10), # 5
		Vector2(15, 10), # 6
		Vector2(-10, 10), # 7

		# Each of these points form a straight line
		# Should NOT increment the total number of mappings
		# they should have the same normal range as point #7
		Vector2(-15, 10), # 8
		Vector2(-20, 10), # 9
		Vector2(-25, 10), # 10
		Vector2(-30, 10), # 11
	]
	# Create shape material with 4 quadrants of normal range
	var shape_material = create_shape_material_with_equal_normal_ranges(4)
	var mappings = SS2D_Shape_Base.get_meta_material_index_mapping(shape_material, verts)
	var mappings_materials = []
	for mapping in mappings:
		mappings_materials.push_back(mapping.object)
	# Should contain 7 sequences
	assert_eq(mappings.size(), 7)
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_left)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_right)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_up)[0]))
	assert_true(mappings_materials.has(shape_material.get_edge_meta_materials(n_down)[0]))

	assert_eq(mappings[0].indicies, [0,1])
	assert_eq(mappings[1].indicies, [1,2])
	assert_eq(mappings[2].indicies, [2,3])
	assert_eq(mappings[3].indicies, [3,4])
	assert_eq(mappings[4].indicies, [4,5])
	assert_eq(mappings[5].indicies, [5,6])
	assert_eq(mappings[6].indicies, [6,7,8,9,10,11])

func test_build_edge_with_material_basic_square():
	var verts = [
		# Basic square
		Vector2(-10, -10), # 0
		Vector2(10, -10), # 1
		Vector2(10, 10), # 2
		Vector2(-10, 10) # 3
	]
	var point_array = SS2D_Point_Array.new()
	for v in verts:
		point_array.add_point(v)
	var shape_material = create_shape_material_with_equal_normal_ranges(4)
	var shape = SS2D_Shape_Base.new()
	add_child_autofree(shape)
	shape._is_instantiable = true
	shape.shape_material = shape_material
	shape.set_point_array(point_array)

	var index_maps = SS2D_Shape_Base.get_meta_material_index_mapping(shape_material, verts)
	var edges = []
	var offset = 1.0

	assert_eq(index_maps.size(), 3)
	for index_map in index_maps:
		edges.push_back(shape._build_edge_with_material(index_map, offset, false))
		assert_true(index_map.is_valid())

	assert_eq(edges.size(), 3)
	var i = 0
	for edge in edges:
		assert_eq(edge.quads.size(), 1)
		assert_eq(edge.first_point_key, point_array.get_point_key_at_index(i))
		assert_eq(edge.last_point_key, point_array.get_point_key_at_index(i+1))
		i += 1

##############################################
# QUAD POINT ILLUSTRATION #                  #
##############################################
#                WIDTH                       #
#           <-------------->                 #
#      pt_a -> O--------O <- pt_d  ▲         #
#              |        |          |         #
#              |   pt   |          | HEIGHT  #
#              |        |          |         #
#      pt_b -> O--------O <- pt_c  ▼         #
##############################################
var width_params = [1.0, 1.5, 0.5, 0.0, 10.0, -1.0]
func test_build_quad_no_texture(width = use_parameters(width_params)):
	var pt: Vector2 = Vector2(0,0)
	var pt_next: Vector2 = Vector2(16,0)
	var tex: Texture = null
	var tex_normal: Texture = null
	var size: Vector2 = Vector2(8,8)
	var flip_x: bool = false
	var flip_y: bool = false
	var first_point: bool = false
	var last_point: bool = false
	var custom_offset: float = 0.0
	var custom_extends: float = 0.0
	var fit_texture: int = SS2D_Material_Edge.FITMODE.SQUISH_AND_STRETCH
	var q = SS2D_Shape_Base.build_quad_from_two_points(
		pt, pt_next,
		tex, tex_normal,
		width,
		flip_x, flip_y,
		first_point, last_point,
		custom_offset, custom_extends,
		fit_texture
	)
	assert_not_null(q)
	var variance = Vector2(0.0, 0.0)
	# There is no texture, should have a width of 'width'
	assert_eq(abs(q.pt_a.y - q.pt_b.y), abs(width))
	assert_almost_eq((q.pt_a - q.pt_b).length(), abs(width), 0.01)
	var half_width = width/2.0
	var half_width_n = half_width * -1
	assert_quad_point_eq(gut,q,Vector2(0, half_width_n),Vector2(0,half_width),Vector2(16,half_width_n),Vector2(16,half_width),variance)

	# Run again, move 2nd point up 16 pixels
	#q = SS2D_Shape_Base.build_quad_from_two_points(
		#pt, pt_next + Vector2(0, -16),
		#tex, tex_normal,
		#width,
		#flip_x, flip_y,
		#first_point, last_point,
		#custom_offset, custom_extends,
		#fit_texture
	#)
	#variance = Vector2(0.5, 0.5)
	## There is no texture, should have a width of about 'width'
	#assert_almost_eq((q.pt_a - q.pt_b).length(), width, 0.01)
	#assert_quad_point_eq(gut,q,Vector2(-2.8,-2.8),Vector2(2.8,2.8),Vector2(13.1,-18.8),Vector2(18.8,-13.1),variance)


func assert_quad_point_eq(gut,q,a,b,d,c,variance):
	assert_almost_eq(q.pt_a, a, variance, "Test Pt A")
	assert_almost_eq(q.pt_b, b, variance, "Test Pt B")
	assert_almost_eq(q.pt_d, d, variance, "Test Pt D")
	assert_almost_eq(q.pt_c, c, variance, "Test Pt C")

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