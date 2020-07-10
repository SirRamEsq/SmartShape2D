tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Open, "../open_shape.png"

#########
# GODOT #
#########
func _init():
	pass


func _ready():
	if _curve == null:
		_curve = Curve2D.new()

############
# OVERRIDE #
############
func duplicate_self():
	var _new = .duplicate()
	return _new

# Workaround (class cannot reference itself)
func __new():
	return get_script().new()
