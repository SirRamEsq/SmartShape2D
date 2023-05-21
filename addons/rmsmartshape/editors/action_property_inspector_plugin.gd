extends EditorInspectorPlugin

## This inspector plugin will show an Execute button for action properties in
## SS2D_Shape.
##
## To add an action property export it with:
##
##   @export_placeholder("ActionProperty") var ...
##
## Then, when an action is executed by user (by pressing an Execute button in inspector),
## setter will be called with non-empty string:
##
##   func _action_property_setter(value: String) -> void:
##       if value.size() > 0:
##           ## Action is executed
##

class ActionPropertyEditor:
	extends EditorProperty

	signal action_pressed

	var button: Button

	func _init() -> void:
		button = Button.new()
		button.text = "Execute"
		add_child(button)
		button.connect("pressed", func(): emit_signal("action_pressed"))

	func _ready() -> void:
		button.icon = get_theme_icon("TextEditorPlay", "EditorIcons")


func _can_handle(object: Object) -> bool:
	if object is SS2D_Shape:
		return true
	return false


func _parse_property(
	object: Object,
	_type: Variant.Type,
	name: String,
	_hint_type: PropertyHint,
	hint_string: String,
	_usage_flags,
	_wide: bool
) -> bool:
	if hint_string == "ActionProperty":
		var prop_editor := ActionPropertyEditor.new()
		add_property_editor(name, prop_editor)
		prop_editor.connect("action_pressed", self._on_action_pressed.bind(object, name))
		return true
	return false


func _on_action_pressed(object: Object, prop_name: String) -> void:
	prints("Action executed:", prop_name.capitalize())
	object.set(prop_name, "executed")
