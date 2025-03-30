extends RefCounted
class_name SS2D_VersionTransition


class IVersionConverter:
	extends RefCounted

	# Initialize internal state. Must be called before using any other functionality.
	func init() -> void:
		pass

	func needs_conversion() -> bool:
		return false

	# Perform conversion. Should return true and do nothing if no conversion is needed.
	func convert() -> bool:
		return true


class ShapeNodeTypeConverter:
	extends IVersionConverter

	var _files: PackedStringArray
	var _from_type: String
	var _to_type: String

	func _init(from: String, to: String) -> void:
		_from_type = from
		_to_type = to

	func init() -> void:
		var analyzer := TscnAnalyzer.new()
		for path in SS2D_VersionTransition.find_files("res://", [ "*.tscn" ]):
			if analyzer.load(path):
				if analyzer.change_shape_node_type(_from_type, _to_type, true):
					_files.append(path)

	func needs_conversion() -> bool:
		return _files.size() > 0

	func convert() -> bool:
		var analyzer := TscnAnalyzer.new()

		for path in _files:
			analyzer.load(path)
			analyzer.change_shape_node_type(_from_type, _to_type)

			if not analyzer.write():
				return false

			print("SS2D: Converted scene ", path)

		return true


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

	func contains_shapes() -> bool:
		return _shape_script_ids.size() > 0

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

	## Changes the node type of shape nodes from the given type to the given type.
	## Returns true if changes were made.
	## If check_only is true, it returns true when conversion is needed, but no modifications are made.
	func change_shape_node_type(from: String, to: String, check_only: bool = false) -> bool:
		if not _shape_script_ids or _content_start_line == -1:
			return false

		var next_line := _content_start_line
		var re_match_script := RegEx.create_from_string("^script\\s*=\\s*ExtResource\\(\"(%s)\"\\)" % "|".join(_shape_script_ids))
		var re_match_node_type := RegEx.create_from_string("type=\"%s\"" % from)
		var replace_string := "type=\"%s\"" % to
		var dirty := false

		while true:
			var node_line := _find_node_with_property_re(next_line, re_match_script)
			next_line = node_line + 1

			if node_line == -1:
				break

			var replaced := re_match_node_type.sub(_lines[node_line], replace_string)

			# No change -> nothing to do here
			if replaced == _lines[node_line]:
				continue

			if check_only:
				return true

			_lines[node_line] = replaced
			dirty = true

		return dirty

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

	## Searches for property definitions under [node] tags matching the given regex.
	## Returns the line of the [node] tag if a match was found, otherwise -1.
	func _find_node_with_property_re(start_line: int, re: RegEx) -> int:
		var node_line: int = -1

		for i in range(start_line, _lines.size()):
			var line := _lines[i]

			if line.begins_with("[node"):
				node_line = i
			elif line.begins_with("["):  # There are likely no other tags intermixed but just to be sure
				node_line = -1
			elif node_line != -1:
				if re.search(line):
					return node_line

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
