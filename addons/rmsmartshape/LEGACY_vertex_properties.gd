extends Reference
class_name RMS2D_VertexProperties

var texture_idx:int = 0
var flip:bool = false
var width:float = 1.0

func duplicate()->RMS2D_VertexProperties:
	var _new = __new()
	_new.texture_idx = texture_idx
	_new.flip = flip
	_new.width = width
	return _new

# Workaround (class cannot reference itself)
func __new()->RMS2D_VertexProperties:
	return get_script().new()
