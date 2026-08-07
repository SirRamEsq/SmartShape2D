@tool
extends Node
class_name SS2D_Common_Functions


static func sort_z(a, b) -> bool:
	if a.z_index < b.z_index:
		return true
	return false


static func sort_int_ascending(a: int, b: int) -> bool:
	if a < b:
		return true
	return false


static func sort_int_descending(a: int, b: int) -> bool:
	if a < b:
		return false
	return true


static func to_vector3(vector: Vector2) -> Vector3:
	return Vector3(vector.x, vector.y, 0)


static func merge_arrays(arrays: Array) -> Array:
	var new_array := []
	for array: Array in arrays:
		for v: Variant in array:
			new_array.push_back(v)
	return new_array


## Helper for displaying a one-shot AcceptDialog
static func show_dialog(title: String, text: String, tree: Node) -> AcceptDialog:
	var dialog := AcceptDialog.new()
	tree.add_child(dialog)
	dialog.title = "SmartShape2D - %s" % title
	dialog.dialog_text = text
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
	return dialog
