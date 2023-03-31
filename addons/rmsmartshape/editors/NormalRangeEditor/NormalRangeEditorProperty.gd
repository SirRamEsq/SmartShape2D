extends EditorProperty
class_name SS2D_NormalRangeEditorProperty

var control: Control = preload(
		"res://addons/rmsmartshape/editors/NormalRangeEditor/NormalRangeEditor.tscn"
	).instantiate()


func _init() -> void:
	add_child(control)
	add_focusable(control)


func _enter_tree() -> void:
	control.connect("value_changed", self._value_changed)
	_value_changed()


func _exit_tree() -> void:
	control.disconnect("value_changed", self._value_changed)


func _value_changed() -> void:
	var obj: SS2D_NormalRange = get_edited_object()
	control.end = obj.distance
	control.start = obj.begin
