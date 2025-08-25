extends SS2D_EditorTool
class_name SS2D_CollisionEditorTool

const ICON_COLLISION: Texture2D = preload("res://addons/rmsmartshape/assets/icon_collision_polygon_2d.svg")
const CONFIG_KEY = "collision_container_path"

var _collision_container_path: String
var _options_dialog := OptionsDialog.new()


# NOTE: Could be a scene, but it's rather simple and has static typing without polluting the "Add node" dialog.
class OptionsDialog:
	extends AcceptDialog

	var line_edit: LineEdit

	func _init() -> void:
		title = SS2D_Strings.EN_OPTIONS_COLLISIONS
		exclusive = false  # Prevent error when opening node selection dialog

		var content := VBoxContainer.new()
		add_child(content)

		var label := Label.new()
		label.text = """
		Enter a node path, a group name or a scene unique name.
		The first node found is used as parent for collision polygons generated using the Collision Tool.
		If empty, the collision polygon is created as sibling to the shape node.

		For example: %StaticBody2D, %level/StaticBody2D, collision_body_group, etc.
		""".dedent().strip_edges()
		content.add_child(label)

		line_edit = LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		register_text_enter(line_edit)

		var select_node := Button.new()
		select_node.text = "Select"
		select_node.pressed.connect(EditorInterface.popup_node_selector.bind(_on_node_selected))

		var hbox := HBoxContainer.new()
		hbox.add_child(line_edit)
		hbox.add_child(select_node)
		content.add_child(hbox)

	func _on_node_selected(path: NodePath) -> void:
		if not visible:  # Dialog could be closed while node selection is still open
			return

		if not path.is_empty():
			var node := get_tree().edited_scene_root.get_node(path)

			if node.unique_name_in_owner:
				line_edit.text = "%" + node.name
			else:
				line_edit.text = path

	func set_selected_node_path(path: NodePath) -> void:
		line_edit.text = path

	func get_selected_node_path() -> NodePath:
		return NodePath(line_edit.text)


func load_config(conf: ConfigFile) -> void:
	_collision_container_path = conf.get_value(CONFIG_OPTIONS_SECTION, CONFIG_KEY, "")


func save_config(conf: ConfigFile) -> void:
	conf.set_value(CONFIG_OPTIONS_SECTION, CONFIG_KEY, _collision_container_path)


func register(editor_plugin: EditorPlugin) -> void:
	super.register(editor_plugin)
	create_options_item(SS2D_Strings.EN_OPTIONS_COLLISIONS, _on_options_clicked)
	create_tool_button(ICON_COLLISION, SS2D_Strings.EN_TOOLTIP_COLLISION, false).pressed.connect(_on_tool_clicked)

	_options_dialog.confirmed.connect(_on_options_confirmed)
	get_plugin().add_child(_options_dialog)


func _on_tool_clicked() -> void:
	if get_shape():
		perform_action(SS2D_ActionAddCollisionNodes.new(get_shape(), _get_collision_container_node()))


func _on_options_clicked() -> void:
	_options_dialog.set_selected_node_path(_collision_container_path)
	_options_dialog.popup_centered()


func _on_options_confirmed() -> void:
	_collision_container_path = _options_dialog.get_selected_node_path()


func _get_collision_container_node() -> Node:
	if not _collision_container_path:
		return null

	var tree := get_plugin().get_tree()
	var node := tree.edited_scene_root.get_node_or_null(_collision_container_path)

	if node:
		return node

	return tree.get_first_node_in_group(_collision_container_path)
