tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Open, "../open_shape.png"


#########
# GODOT #
#########
func _init():
	_is_instantiable = true


############
# OVERRIDE #
############
func duplicate_self():
	var _new = .duplicate()
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()
