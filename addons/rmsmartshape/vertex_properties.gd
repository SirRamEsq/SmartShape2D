@tool
extends Resource
class_name SS2D_VertexProperties

@export var texture_idx: int # : set = set_texture_idx
@export var flip: bool #: set = set_flip
@export var width: float #: set = set_width


func set_texture_idx(i: int) -> void:
	texture_idx = i
	emit_changed()
	notify_property_list_changed()


func set_flip(b: bool) -> void:
	flip = b
	emit_changed()
	notify_property_list_changed()


func set_width(w: float) -> void:
	width = w
	emit_changed()
	notify_property_list_changed()


func _init() -> void:
	texture_idx = 0
	flip = false
	width = 1.0


func equals(other: SS2D_VertexProperties) -> bool:
	if other.flip != flip:
		return false
	if other.texture_idx != texture_idx:
		return false
	if other.width != width:
		return false
	return true
