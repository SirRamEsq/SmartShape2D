tool
extends RMSS2D_Shape_Base
class_name RMSS2D_Shape_Closed, "../closed_shape.png"

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

func _build_meshes(edges: Array) -> Array:
	var meshes = []

	var produced_fill_mesh = false
	for e in edges:
		if not produced_fill_mesh:
			if e.z_index > shape_material.fill_texture_z_index:
				# Produce Fill Meshes
				for m in _build_fill_mesh(get_tessellated_points(), shape_material):
					meshes.push_back(m)
				produced_fill_mesh = true

		# Produce edge Meshes
		for m in e.get_meshes():
			meshes.push_back(m)
	return meshes
