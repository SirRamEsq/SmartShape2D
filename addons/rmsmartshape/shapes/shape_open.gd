@tool
@icon("../assets/open_shape.png")
extends SS2D_Shape_Base
class_name SS2D_Shape_Open


#########
# GODOT #
#########
func _init() -> void:
	super._init()
	_is_instantiable = true



############
# OVERRIDE #
############
func should_flip_edges() -> bool:
	return flip_edges
