@tool
extends Resource
class_name SS2D_VertexProperties

# @export (int) var texture_idx: int # setget set_texture_idx
var texture_idx: int # setget set_texture_idx

# @export (bool) var flip: bool #setget set_flip
@export var flip: bool #setget set_flip

# @export (float) var width: float #setget set_width
@export var width: float #setget set_width


func set_texture_idx(i: int):
	texture_idx = i
	emit_signal("changed")
	# property_list_changed_notify()
	notify_property_list_changed()


func set_flip(b: bool):
	flip = b
	emit_signal("changed")
	# property_list_changed_notify()
	notify_property_list_changed()


func set_width(w: float):
	width = w
	emit_signal("changed")
	# property_list_changed_notify()
	notify_property_list_changed()


func _init():
	texture_idx = 0
	flip = false
	width = 1.0


func duplicate(sub_resources: bool = false):
	var _new = __new()
	_new.texture_idx = texture_idx
	_new.flip = flip
	_new.width = width
	return _new


# Workaround (class cannot reference itself)
func __new() -> SS2D_VertexProperties:
	return get_script().new()


func equals(other: SS2D_VertexProperties) -> bool:
	if other.flip != flip:
		return false
	if other.texture_idx != texture_idx:
		return false
	if other.width != width:
		return false
	return true
