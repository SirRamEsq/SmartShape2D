extends "res://addons/gut/test.gd"

func test_change_propagate():
	var nr1 = SS2D_NormalRange.new(-90.0, 90.0)
	var nr2 = SS2D_NormalRange.new(91.0, -91.0)

	var edge_mat_1 = SS2D_Material_Edge.new()
	var edge_mat_2 = SS2D_Material_Edge.new()

	var edge_mat_meta_1 = SS2D_Material_Edge_Metadata.new()
	var edge_mat_meta_2 = SS2D_Material_Edge_Metadata.new()
	edge_mat_meta_1.edge_material = edge_mat_1
	edge_mat_meta_2.edge_material = edge_mat_2
	edge_mat_meta_1.normal_range = nr1
	edge_mat_meta_2.normal_range = nr2

	var shape_material = SS2D_Material_Shape.new()
	watch_signals(shape_material)

	assert_signal_emit_count(shape_material, "changed", 0)

	shape_material.set_edge_meta_materials([edge_mat_meta_1, edge_mat_meta_2])
	assert_signal_emit_count(shape_material, "changed", 1)

	edge_mat_meta_1.weld = not edge_mat_meta_1.weld
	assert_signal_emit_count(shape_material, "changed", 2)

	edge_mat_1.use_corner_texture = not edge_mat_1.use_corner_texture
	assert_signal_emit_count(shape_material, "changed", 3)
