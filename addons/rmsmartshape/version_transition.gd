extends RefCounted
class_name SS2D_VersionTransition


## Interface for version converters.
## Converters should not build any internal cache because other converters could potentially make
## changes that would silently invalidate the cache.
class IVersionConverter:
	extends RefCounted

	# Returns whether conversion is needed.
	func needs_conversion() -> bool:
		return false

	# Perform conversion. Should return true and do nothing if no conversion is needed.
	func convert() -> bool:
		return true


class BaseSceneConverter:
	extends IVersionConverter

	## Returns true when changes were made / would have been made if check_only is true.
	## Override this in sub-classes.
	@warning_ignore("unused_parameter")
	func convert_scene(analyzer: TscnAnalyzer, check_only: bool) -> bool:
		return false

	## Runs conversion and returns true on success, including when no changes were made.
	## If check_only is true, returns true if conversion is needed.
	func _convert(check_only: bool) -> bool:
		var analyzer := TscnAnalyzer.new()

		for path in SS2D_VersionTransition.find_files("res://", [ "*.tscn" ]):
			if not analyzer.load(path):
				continue

			if convert_scene(analyzer, check_only):
				if check_only:
					return true

				if not analyzer.write():
					return false

		# Return false because no conversion was needed, otherwise report success
		if check_only:
			return false

		return true

	func needs_conversion() -> bool:
		return _convert(true)

	func convert() -> bool:
		return _convert(false)


## Changes the node type of shape nodes from one given type to another given type.
class ShapeNodeTypeConverter:
	extends BaseSceneConverter

	var _re_match_node_type: RegEx
	var _replace_string: String

	func _init(from: String, to: String) -> void:
		_re_match_node_type = RegEx.create_from_string("type=\"%s\"" % from)
		_replace_string = "type=\"%s\"" % to

	## Returns true when changes were made / would have been made if check_only is true.
	func convert_scene(analyzer: TscnAnalyzer, check_only: bool) -> bool:
		if not analyzer.contains_shapes():
			return false

		var lines := analyzer.get_lines()
		var dirty := false

		for node_line in analyzer.find_shape_node_lines():
			var original_line := lines[node_line]
			var new_line := _re_match_node_type.sub(original_line, _replace_string)

			if new_line != original_line:
				if check_only:
					return true

				lines[node_line] = new_line
				dirty = true

		return dirty


class TscnAnalyzer:
	extends RefCounted

	var _path: String
	var _lines: PackedStringArray
	var _shape_script_ids: PackedStringArray
	var _content_start_line: int  # Points to the first line after [ext_resource] section

	func load(tscn_path: String) -> bool:
		_path = tscn_path
		_shape_script_ids.clear()
		var content := FileAccess.get_file_as_string(tscn_path)

		if not content:
			_lines.clear()
			_content_start_line = 0
			return false

		_lines = content.split("\n")
		_content_start_line = _extract_shape_script_ids(_shape_script_ids)
		return true

	func get_path() -> String:
		return _path

	func contains_shapes() -> bool:
		return _shape_script_ids.size() > 0

	func get_lines() -> PackedStringArray:
		return _lines

	## Writes the internal buffer to the given file. If no file is specified, writes to the loaded file.
	## Returns true on success.
	func write(file_path: String = "") -> bool:
		file_path = file_path if file_path else _path

		var f := FileAccess.open(file_path, FileAccess.WRITE)

		if not f:
			push_error("Failed to open file for writing: ", file_path)
			return false

		f.store_string("\n".join(_lines))
		f.close()
		return true

	## Returns a list of line numbers for each shape node definition found in the scene file.
	## The line number corresponds to the line with the [node ...] tag
	func find_shape_node_lines() -> PackedInt32Array:
		var lines: PackedInt32Array

		if not _shape_script_ids or _content_start_line == -1:
			return lines

		var next_line := _content_start_line
		var re_match_script := RegEx.create_from_string("^script\\s*=\\s*ExtResource\\(\"(%s)\"\\)" % "|".join(_shape_script_ids))

		while true:
			var node_line := find_node(next_line)

			if node_line < 0:
				break

			var script_line := find_property_in_node(node_line, re_match_script)

			if script_line < 0:
				next_line = absi(script_line)
				continue

			lines.push_back(node_line)
			next_line = script_line + 1

		return lines

	## Searches for a line matching the given regex under a [node] tag starting at the given line.
	## Returns a positive integer indicating the line where a match was found or a negative integer
	## indicating the line where the search stopped because EOF or a new tag was started.
	func find_property_in_node(node_line: int, re: RegEx) -> int:
		for i in range(node_line + 1, _lines.size()):
			var line := _lines[i]

			if line.begins_with("["):
				return -i

			if re.search(line):
				return i

		return -_lines.size()


	## Searches for the next [node] tag starting at the given line.
	## Returns -1 when EOF was reached without finding a tag.
	func find_node(start_line: int) -> int:
		for i in range(start_line, _lines.size()):
			var line := _lines[i]

			if line.begins_with("[node"):
				return i

		return -1

	## Examines [ext_resource] entries and updates the given list to include all resource IDs referring
	## to shapes (shape/shape_open/shape_closed.gd).
	## Returns -1 when EOF was reached, otherwise the index of the first non-[ext_resource] line.
	func _extract_shape_script_ids(out_shape_ids: PackedStringArray) -> int:
		var re_ext_resource_path_is_shape := RegEx.create_from_string("path=\"(res://addons/rmsmartshape/shapes/(?:shape|shape_closed|shape_open).gd\")")
		var re_extract_id := RegEx.create_from_string("id=\"([0-9a-z_]+)\"")
		var found_something := false

		for i in _lines.size():
			var line := _lines[i]

			if line.begins_with("[ext_resource"):
				if re_ext_resource_path_is_shape.search(line):
					out_shape_ids.append(re_extract_id.search(line).get_string(1))
					found_something = true
				continue

			# Any other tag like [sub_resource] or [node]. Usually there shouldn't be any intermixed ext_resource tags
			if found_something and line.begins_with("["):
				return i

		return -1


## Recursively searches for files in the given searchpath.
## Returns a list of files matching the given glob expressions.
static func find_files(searchpath: String, globs: PackedStringArray) -> PackedStringArray:
	var root := DirAccess.open(searchpath)

	if not root:
		push_error("Failed to open directory: ", searchpath)

	root.include_navigational = false
	root.list_dir_begin()

	var files: PackedStringArray
	var root_path := root.get_current_dir()

	while true:
		var fname := root.get_next()

		if fname.is_empty():
			break

		var path := root_path.path_join(fname)

		if root.current_is_dir():
			files.append_array(find_files(path, globs))
		else:
			for expr in globs:
				if fname.match(expr):
					files.append(path)
					break

	root.list_dir_end()
	return files
