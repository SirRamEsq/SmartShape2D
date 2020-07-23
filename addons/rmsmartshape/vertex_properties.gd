extends Resource
class_name RMS2D_VertexProperties

export (int) var texture_idx: int = 0
export (bool) var flip: bool = false
export (float) var width: float = 1.0


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
func __new() -> RMS2D_VertexProperties:
	return get_script().new()


func equals(other: RMS2D_VertexProperties):
	if other.flip != flip:
		return false
	if other.texture_idx != texture_idx:
		return false
	if other.width != width:
		return false
	return true
