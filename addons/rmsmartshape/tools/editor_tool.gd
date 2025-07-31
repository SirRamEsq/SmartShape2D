extends RefCounted
class_name SS2D_EditorTool

const CONFIG_OPTIONS_SECTION = "options"

# NOTE: Access to the editor plugin (plugin.gd) is untyped (for now) to not pollute the "Add node"
# menu with internal SS2D nodes.

var _editor_plugin: EditorPlugin
var _toolbar: Control
var _options_menu: PopupMenu
var _options_entries := {}  ## Dict[int, Callable]


func load_config(_conf: ConfigFile) -> void:
	pass


func save_config(_conf: ConfigFile) -> void:
	pass


## Initialize the tool and register UI controls.
## Derived classes must call the base implementation!
func register(editor_plugin: EditorPlugin) -> void:
	_editor_plugin = editor_plugin

	@warning_ignore("unsafe_property_access")
	_toolbar = _editor_plugin.tb_hb

	@warning_ignore("unsafe_property_access")
	_options_menu = _editor_plugin.tb_options_popup
	_options_menu.index_pressed.connect(_on_options_index_pressed_dispatch)


## Create a tool button in the toolbar.
func create_tool_button(icon: Texture2D, tooltip: String, toggle: bool = true) -> Button:
	@warning_ignore("unsafe_method_access")
	return _editor_plugin.create_tool_button(icon, tooltip, toggle)


func perform_action(action: SS2D_Action) -> void:
	@warning_ignore("unsafe_method_access")
	_editor_plugin.perform_action(action)


func create_options_item(label: String, callback: Callable) -> void:
	_options_menu.add_item(label)
	_options_entries[_options_menu.item_count - 1] = callback


func get_options_menu() -> PopupMenu:
	return _options_menu


func get_toolbar() -> Control:
	return _toolbar


func get_plugin() -> EditorPlugin:
	return _editor_plugin


func get_shape() -> SS2D_Shape:
	@warning_ignore("unsafe_property_access")
	return _editor_plugin.shape


## Adds the dialog node to the tree and displays it.
## Connects to `confirmed` and `canceled` signals to `queue_free()` it when closed.
func show_oneshot_dialog(dialog: AcceptDialog) -> void:
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	_editor_plugin.add_child(dialog)
	dialog.popup_centered()


func _on_options_index_pressed_dispatch(idx: int) -> void:
	var callback: Callable = _options_entries.get(idx)
	if callback:
		callback.call()
