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
func duplicate_self()->RMSS2D_Shape_Base:
	var _new = .duplicate()
	return _new

# Workaround (class cannot reference itself)
func __new()->RMSS2D_Shape_Base:
	return get_script().new()


func _get_next_point_index(idx: int, points: Array) -> int:
	var new_idx = idx
	new_idx = (idx + 1) % points.size()
	# First and last point are the same when closed
	if points[idx] == points[new_idx]:
		new_idx = _get_next_point_index(new_idx, points)
	return new_idx


func _get_previous_point_index(idx: int, points: Array) -> int:
	var new_idx = idx - 1
	if new_idx < 0:
		new_idx += points.size()
	if points[idx] == points[new_idx]:
		new_idx = _get_previous_point_index(new_idx, points)
	return new_idx

func _get_last_point_index(points: Array) -> int:
	return points.size() - 2
