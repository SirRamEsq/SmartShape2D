@tool
@icon("../assets/open_shape.png")
extends SS2D_Shape_Base
class_name SS2D_Shape_Open


#########
# GODOT #
#########
func _init():
	super._init()
	_is_instantiable = true



############
# OVERRIDE #
############
func duplicate_self():
	var _new = super.duplicate()
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()


func should_flip_edges() -> bool:
	return flip_edges
