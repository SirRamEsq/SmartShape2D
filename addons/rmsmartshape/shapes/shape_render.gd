@tool
extends Node2D
class_name SS2D_Shape_Render

## Node is used to render shape geometry.

var mesh: SS2D_Mesh = null : set = set_mesh


func set_mesh(m: SS2D_Mesh) -> void:
	mesh = m
	if m != null:
		material = mesh.material
		z_index = mesh.z_index
		z_as_relative = mesh.z_as_relative
		show_behind_parent = mesh.show_behind_parent
	else:
		material = null
		z_index = 0
		z_as_relative = true
		show_behind_parent = false
	queue_redraw()


func _draw() -> void:
	if mesh != null:
		mesh.render(self)
