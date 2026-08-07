extends GutTest

func test_find_scene_files() -> void:
	var files := SS2D_VersionTransition.find_files("res://addons/rmsmartshape/examples/sharp_corner_tapering", [ "*.tscn" ])

	assert_eq(files.size(), 1)
	assert_eq(files[0], "res://addons/rmsmartshape/examples/sharp_corner_tapering/sharp_corner_tapering.tscn")


func test_find_scene_files_no_scenes() -> void:
	var files := SS2D_VersionTransition.find_files("res://addons/rmsmartshape/documentation", [ "*.tscn" ])
	assert_eq(files.size(), 0)


func test_contains_shapes() -> void:
	var analyzer := _get_test_analyzer()
	assert_true(analyzer.contains_shapes())

	analyzer.load("res://tests/unit/test_tscn_analyzer.gd")
	assert_false(analyzer.contains_shapes())


func test_extract_shape_script_ids() -> void:
	var analyzer := _get_test_analyzer()
	var shape_ids := analyzer._shape_script_ids

	assert_eq(shape_ids.size(), 3)
	assert_eq(shape_ids[0], "1_bf561")
	assert_eq(shape_ids[1], "6_vhs31")
	assert_eq(shape_ids[2], "7_d1rup")
	assert_eq(analyzer._content_start_line, 11)

	shape_ids.clear()
	analyzer.load("res://tests/unit/test_tscn_analyzer.gd")
	var next_line := analyzer._extract_shape_script_ids(shape_ids)

	assert_eq(next_line, -1)
	assert_eq(shape_ids.size(), 0)


func test_find_node() -> void:
	var analyzer := _get_test_analyzer()
	var line := 0
	var node_lines := []

	while true:
		line = analyzer.find_node(line)

		if line < 0:
			break

		node_lines.append(line)
		line += 1

	assert_eq(node_lines, [275, 277, 279, 284, 289, 291, 296, 299])


func test_find_property_in_node() -> void:
	var analyzer := _get_test_analyzer()
	var re := RegEx.create_from_string("^script = ExtResource\\(\"7_d1rup\"\\)")

	assert_eq(analyzer.find_property_in_node(291, re), 292)
	assert_eq(analyzer.find_property_in_node(284, re), -289)
	assert_eq(analyzer.find_property_in_node(299, re), -301)


func test_find_shape_node_lines() -> void:
	var analyzer := _get_test_analyzer()
	var lines := analyzer.find_shape_node_lines()
	assert_eq(lines, PackedInt32Array([ 279, 284, 291 ]))


func test_ShapeNodeTypeConverter() -> void:
	var converted_analyzer := _get_test_analyzer("res://tests/unit/scene_with_node2d_shapes_converted.txt")
	var converter := SS2D_VersionTransition.ShapeNodeTypeConverter.new("Node2D", "MeshInstance2D")
	var analyzer := _get_test_analyzer()

	assert_true(converter.convert_scene(analyzer, false))
	assert_eq(analyzer._lines, converted_analyzer._lines)


func test_ShapeNodeTypeConverter_check_only() -> void:
	var converter := SS2D_VersionTransition.ShapeNodeTypeConverter.new("Node2D", "MeshInstance2D")
	var analyzer := _get_test_analyzer()
	var original_lines := PackedStringArray(analyzer._lines)

	assert_true(converter.convert_scene(analyzer, true))
	assert_eq(analyzer._lines, original_lines)  # Should be unmodified


func _get_test_analyzer(scene_path: String = "res://tests/unit/scene_with_node2d_shapes.txt") -> SS2D_VersionTransition.TscnAnalyzer:
	var analyzer := SS2D_VersionTransition.TscnAnalyzer.new()
	var success := analyzer.load(scene_path)
	assert_true(success)
	return analyzer
