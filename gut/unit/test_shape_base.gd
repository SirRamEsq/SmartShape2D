extends "res://addons/gut/test.gd"
var TEST_TEXTURE = preload("res://gut/unit/test.png")
var n_right = Vector2(1, 0)
var n_left = Vector2(-1, 0)
var n_down = Vector2(0, 1)
var n_up = Vector2(0, -1)

##############################################
# QUAD POINT ILLUSTRATION #                  #
##############################################
#                LENGTH                       #
#           <-------------->                 #
#      pt_a -> O--------O <- pt_d  ▲         #
#              |        |          |         #
#              |   pt   |          | WIDTH   #
#              |        |          |         #
#      pt_b -> O--------O <- pt_c  ▼         #
##############################################

func test_tessellated_idx_and_point_idx():
	var verts = [
		Vector2(-10, -10), # 0
		Vector2(10, -10), # 1
		Vector2(10, 10), # 2
		Vector2(-10, 10) # 3
	]
	var t_verts = [
		Vector2(-10, -10), # 0 (0)
		Vector2(0, -11), # 1 (0)
		Vector2(10, -10), # 2 (1)
		Vector2(12, 0), # 3 (1)
		Vector2(10, 10), # 4 (2)
		Vector2(0, 12), # 5 (2)
		Vector2(-10, 10) # 6 (3)
	]
	assert_eq(SS2D_Shape_Base.get_tessellated_idx_from_point(verts, t_verts, 0), 0)
	assert_eq(SS2D_Shape_Base.get_tessellated_idx_from_point(verts, t_verts, 1), 2)
	assert_eq(SS2D_Shape_Base.get_tessellated_idx_from_point(verts, t_verts, 2), 4)
	assert_eq(SS2D_Shape_Base.get_tessellated_idx_from_point(verts, t_verts, 3), 6)
	assert_eq(SS2D_Shape_Base.get_tessellated_idx_from_point(verts, t_verts, 400), 6)
	assert_eq(SS2D_Shape_Base.get_tessellated_idx_from_point(verts, t_verts, -1), 0)
	assert_eq(SS2D_Shape_Base.get_tessellated_idx_from_point(verts, t_verts, -100), 0)

	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 0), 0)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 1), 0)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 2), 1)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 3), 1)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 4), 2)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 5), 2)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 6), 3)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, 600), 3)
	assert_eq(SS2D_Shape_Base.get_vertex_idx_from_tessellated_point(verts, t_verts, -600), 0)

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

var offset_params = [1.0, 1.5, 0.5, 0.0, 10.0, -1.0]
func test_build_edge_with_material_basic_square(offset = use_parameters(offset_params)):
	# Basic square
	var verts = [
		Vector2(-10, -10), # 0
		Vector2(10, -10), # 1
		Vector2(10, 10), # 2
		Vector2(-10, 10) # 3
	]
	var point_array = SS2D_Point_Array.new()
	for v in verts:
		point_array.add_point(v)
	var tex = TEST_TEXTURE
	var tex_size = tex.get_size()
	var shape_material = create_shape_material_with_equal_normal_ranges(4, tex)
	var shape = SS2D_Shape_Base.new()
	add_child_autofree(shape)
	shape._is_instantiable = true
	shape.shape_material = shape_material
	shape.set_point_array(point_array)

	var index_maps = SS2D_Shape_Base.get_meta_material_index_mapping(shape_material, verts)
	var edges = []

	assert_eq(index_maps.size(), 3)
	for index_map in index_maps:
		edges.push_back(shape._build_edge_with_material(index_map, offset, 0))
		assert_true(index_map.is_valid())

	assert_eq(edges.size(), 3)
	assert_eq(edges[0].quads[0].pt_a.y, verts[0].y - tex_size.y/2.0 - (offset*tex_size.y)/2.0, "Ensure quad has correct offset")
	assert_eq(edges[1].quads[0].pt_a.x, verts[1].x + tex_size.x/2.0 + (offset*tex_size.x)/2.0, "Ensure quad has correct offset")
	assert_eq(edges[2].quads[0].pt_a.y, verts[2].y + tex_size.y/2.0 + (offset*tex_size.y)/2.0, "Ensure quad has correct offset")
	assert_eq(abs(edges[0].quads[0].pt_a.y - edges[0].quads[0].pt_b.y), tex_size.y, "Ensure quad has correct width")
	assert_eq(abs(edges[1].quads[0].pt_a.x - edges[1].quads[0].pt_b.x), tex_size.y, "Ensure quad has correct width")
	assert_eq(abs(edges[2].quads[0].pt_a.y - edges[2].quads[0].pt_b.y), tex_size.y, "Ensure quad has correct width")
	var i = 0
	for edge in edges:
		assert_eq(edge.quads.size(), 1)
		assert_eq(edge.first_point_key, point_array.get_point_key_at_index(i))
		assert_eq(edge.last_point_key, point_array.get_point_key_at_index(i+1))
		gut.p(edge.quads)
		i += 1

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
	assert_quad_point_eq(gut,q,Vector2(0, half_width_n),Vector2(0,half_width),
						Vector2(16,half_width),Vector2(16,half_width_n),variance)

func test_build_quad_with_texture(width_scale = use_parameters(width_params)):
	var pt: Vector2 = Vector2(0,0)
	var pt_next: Vector2 = Vector2(16,0)
	var tex: Texture = TEST_TEXTURE
	var tex_height = tex.get_size().y
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
		width_scale * tex_height,
		flip_x, flip_y,
		first_point, last_point,
		custom_offset, custom_extends,
		fit_texture
	)
	assert_not_null(q)
	var variance = Vector2(0.0, 0.0)
	# There is a texture, should have a width of 'width' * texture_height
	var width = width_scale * tex_height
	assert_eq(abs(q.pt_a.y - q.pt_b.y), abs(width))
	assert_almost_eq((q.pt_a - q.pt_b).length(), abs(width), 0.01)
	var half_width = width/2.0
	var half_width_n = half_width * -1
	assert_quad_point_eq(gut,q,Vector2(0, half_width_n),Vector2(0,half_width),Vector2(16,half_width),Vector2(16,half_width_n),variance)

func test_should_edge_generate_corner():
	# L Shape
	var pt_prev: Vector2 = Vector2(-16, 00)
	var pt: Vector2 =      Vector2(000, 00)
	var pt_next: Vector2 = Vector2(000, 16)
	var corner = SS2D_Shape_Base.edge_should_generate_corner(pt_prev, pt, pt_next, false)
	assert_eq(corner, SS2D_Quad.CORNER.OUTER)
	corner = SS2D_Shape_Base.edge_should_generate_corner(pt_prev, pt, pt_next, true)
	assert_eq(corner, SS2D_Quad.CORNER.INNER)

	# V Shape
	pt_prev = Vector2(-8, -8)
	pt =      Vector2(00, 00)
	pt_next = Vector2(-8, 08)
	corner = SS2D_Shape_Base.edge_should_generate_corner(pt_prev, pt, pt_next, false)
	assert_eq(corner, SS2D_Quad.CORNER.OUTER)
	corner = SS2D_Shape_Base.edge_should_generate_corner(pt_prev, pt, pt_next, true)
	assert_eq(corner, SS2D_Quad.CORNER.INNER)

func test_build_corner_quad():
	var pt_prev: Vector2 = Vector2(-16, 00)
	var pt: Vector2 =      Vector2(000, 00)
	var pt_next: Vector2 = Vector2(000, 16)
	var tex: Texture = TEST_TEXTURE
	var tex_height = tex.get_size().y
	var tex_normal: Texture = null
	var width  = 1.0
	var width_prev  = 1.0
	var size: Vector2 = Vector2(8,8)
	var flip_edges: bool = false
	var custom_scale: float = 1.0
	var custom_offset: float = 0.0
	var fit_texture: int = SS2D_Material_Edge.FITMODE.SQUISH_AND_STRETCH

	var corner_status = SS2D_Shape_Base.edge_should_generate_corner(pt_prev, pt, pt_next, flip_edges)
	var q = SS2D_Shape_Base.build_quad_corner(
		pt_next, pt, pt_prev,
		width, width_prev,
		flip_edges,
		corner_status,
		tex, tex_normal,
		size,
		custom_scale, custom_offset
	)
	gut.p("Test custom_scale")
	assert_quad_point_eq(gut,q, Vector2(-4,-4),Vector2(-4,4),Vector2(4,4),Vector2(4,-4),Vector2(0,0))
	q = SS2D_Shape_Base.build_quad_corner(
		pt_next, pt, pt_prev,
		width, width_prev,
		flip_edges,
		corner_status,
		tex, tex_normal,
		size,
		custom_scale*2, custom_offset
	)
	assert_quad_point_eq(gut,q, Vector2(-8,-8),Vector2(-8,8),Vector2(8,8),Vector2(8,-8),Vector2(0,0))

	gut.p("Test width")
	q = SS2D_Shape_Base.build_quad_corner(
		pt_next, pt, pt_prev,
		width*2, width_prev,
		flip_edges,
		corner_status,
		tex, tex_normal,
		size,
		custom_scale, custom_offset
	)
	assert_quad_point_eq(gut,q, Vector2(-8,-4),Vector2(-8,4),Vector2(8,4),Vector2(8,-4),Vector2(0,0))

	gut.p("Test width + custom_scale")
	q = SS2D_Shape_Base.build_quad_corner(
		pt_next, pt, pt_prev,
		width*2, width_prev*2,
		flip_edges,
		corner_status,
		tex, tex_normal,
		size,
		custom_scale*2, custom_offset
	)
	assert_quad_point_eq(gut,q, Vector2(-16,-16),Vector2(-16,16),Vector2(16,16),Vector2(16,-16),Vector2(0,0))
	gut.p("Test width_prev")
	q = SS2D_Shape_Base.build_quad_corner(
		pt_next, pt, pt_prev,
		width, width_prev*2,
		flip_edges,
		corner_status,
		tex, tex_normal,
		size,
		custom_scale, custom_offset
	)
	assert_quad_point_eq(gut,q, Vector2(-4,-8),Vector2(-4,8),Vector2(4,8),Vector2(4,-8),Vector2(0,0))

	gut.p("Test custom_offset")
	gut.p("For this shape, shoud offset up and to the right (postivie x, negative y)")
	custom_offset = 1.0
	q = SS2D_Shape_Base.build_quad_corner(
		pt_next, pt, pt_prev,
		width, width_prev,
		flip_edges,
		corner_status,
		tex, tex_normal,
		size,
		custom_scale, custom_offset
	)
	var extents = size / 2.0
	var offset = custom_offset * extents * (Vector2(1,0).normalized() + Vector2(0,-1).normalized())
	assert_quad_point_eq(gut,q, Vector2(-4,-4)+offset,Vector2(-4,4)+offset,
								Vector2(4,4)+offset,Vector2(4,-4)+offset,
								Vector2(0,0))

func assert_quad_point_eq(gut,q,a,b,c,d,variance=Vector2(0,0)):
	assert_almost_eq(q.pt_a, a, variance, "Test Pt A")
	assert_almost_eq(q.pt_b, b, variance, "Test Pt B")
	assert_almost_eq(q.pt_c, c, variance, "Test Pt C")
	assert_almost_eq(q.pt_d, d, variance, "Test Pt D")

func test_weld_quads():
	var left = SS2D_Quad.new(Vector2(-4,-4),Vector2(-4,4),Vector2(4,4),Vector2(4,-4), null, null, false)
	var right = SS2D_Quad.new(Vector2(-8,-8),Vector2(-8,8),Vector2(8,8),Vector2(8,-8), null, null, false)
	var custom_scale:float=1.0
	SS2D_Shape_Base.weld_quads(left, right, custom_scale)
	var pt_top = (left.pt_d + right.pt_a)/2.0
	var pt_bottom = (left.pt_c + right.pt_b)/2.0
	assert_quad_point_eq(gut,left, left.pt_a, left.pt_b, pt_bottom, pt_top)
	assert_quad_point_eq(gut,right, pt_top, pt_bottom, right.pt_c, right.pt_d)

func create_shape_material_with_equal_normal_ranges(edge_materials_count:int=4, tex:Texture=TEST_TEXTURE)->SS2D_Material_Shape:
	var edge_materials = []
	var edge_materials_meta = []
	for i in range(0, edge_materials_count, 1):
		var edge_mat = SS2D_Material_Edge.new()
		edge_materials.push_back(edge_mat)
		edge_mat.textures = [tex]

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
