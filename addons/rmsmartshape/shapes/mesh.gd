tool
extends Reference
class_name RMSS2D_Mesh

"""
Used to organize all requested meshes to be rendered by their textures
"""

var texture: Texture = null
var texture_normal: Texture = null
var flip_texture: bool = false
var meshes: Array = []
var mesh_transform: Transform2D = Transform2D()


func render():
	for mesh in meshes:
		draw_mesh(mesh, texture, normal_texture, mesh_transform)
