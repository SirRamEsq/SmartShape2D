tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Closed

export (Resource) var shape_material = RMSS2D_Material_Shape.new() setget _set_material

#####################
# SETTERS / GETTERS #
#####################

func _set_material(m:RMSS2D_Material_Shape):
	if m == null:
		return
	shape_material = m



############
# OVERRIDE #
############
func duplicate_self():
	var _new = .duplicate()
	_new.shape_material = m
	return _new

# Workaround (class cannot reference itself)
func __new():
	return get_script().new()
