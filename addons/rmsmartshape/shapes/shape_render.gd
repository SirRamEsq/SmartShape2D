tool
extends Node2D
class_name SS2D_Shape_Render

"""
Node is used to render shape geometry
"""

var mesh = null setget set_mesh

func set_mesh(m):
	mesh = m
	update()

func _draw():
	if mesh != null:
		mesh.render(self)
