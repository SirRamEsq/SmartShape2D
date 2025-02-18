extends GutTest


func test_find_scene_files() -> void:
	var files := SS2D_VersionTransition.find_files("res://examples/sharp_corner_tapering", [ "*.tscn" ])

	assert_eq(files.size(), 1)
	assert_eq(files[0], "res://examples/sharp_corner_tapering/sharp_corner_tapering.tscn")


func test_find_scene_files_no_scenes() -> void:
	var files := SS2D_VersionTransition.find_files("res://addons/rmsmartshape/documentation", [ "*.tscn" ])
	assert_eq(files.size(), 0)


func test_contains_shapes() -> void:
	var analyzer := _get_test_analyzer()
	assert_true(analyzer.contains_shapes())

	analyzer.load("res://tests/unit/res://tests/unit/test_convert_tscn_node_types.gd")
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
	analyzer.load("res://tests/unit/res://tests/unit/test_convert_tscn_node_types.gd")
	var next_line := analyzer._extract_shape_script_ids(shape_ids)

	assert_eq(next_line, -1)
	assert_eq(shape_ids.size(), 0)


func test_find_node_with_property_re() -> void:
	var analyzer := _get_test_analyzer()
	var re := RegEx.create_from_string("^script = ExtResource\\(\"7_d1rup\"\\)")
	var line := analyzer._find_node_with_property_re(0, re)

	assert_eq(line, 291)


func test_convert_tscn() -> void:
	var expected_analyzer := SS2D_VersionTransition.TscnAnalyzer.new()
	expected_analyzer.load("res://tests/unit/scene_with_node2d_shapes_converted.txt")
	var analyzer := _get_test_analyzer()
	var converted := analyzer.change_shape_node_type("Node2D", "MeshInstance2D")

	assert_true(converted)
	assert_eq(analyzer._lines, expected_analyzer._lines)


func test_convert_tscn_check_only() -> void:
	var analyzer := _get_test_analyzer()
	var needs_conversion := analyzer.change_shape_node_type("Node2D", "MeshInstance2D", true)

	assert_true(needs_conversion)
	assert_eq(analyzer._lines, _get_test_analyzer()._lines)

func test_convert_tscn_check_only_needs_no_conversion() -> void:
	var analyzer := SS2D_VersionTransition.TscnAnalyzer.new()
	analyzer.load("res://tests/unit/scene_with_node2d_shapes_converted.txt")

	var needs_conversion := analyzer.change_shape_node_type("Node2D", "MeshInstance2D", true)

	assert_false(needs_conversion)


func _get_test_analyzer() -> SS2D_VersionTransition.TscnAnalyzer:
	var analyzer := SS2D_VersionTransition.TscnAnalyzer.new()
	var success := analyzer.load("res://tests/unit/scene_with_node2d_shapes.txt")
	assert_true(success)
	return analyzer
