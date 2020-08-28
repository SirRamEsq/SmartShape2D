tool
extends Reference
class_name SS2D_Mesh

"""
Used to organize all requested meshes to be rendered by their textures
"""

var texture: Texture = null
var texture_normal: Texture = null
var flip_texture: bool = false
# Array of ArrayMesh
var meshes: Array = []
var mesh_transform: Transform2D = Transform2D()


func _init(
	t: Texture = null,
	tn: Texture = null,
	f: bool = false,
	xform: Transform2D = Transform2D(),
	m: Array = []
):
	texture = t
	texture_normal = tn
	flip_texture = f
	meshes = m


func matches(tex: Texture, tex_n: Texture, f: bool, t: Transform2D) -> bool:
	if tex == texture and tex_n == texture_normal and f == flip_texture and t == mesh_transform:
		return true
	return false

func debug_print_array_mesh(am:ArrayMesh)->String:
	var s =  "Faces:%s  |  Surfs:%s  | " % [am.get_faces(), am.get_surface_count()]
	return s

func render(ci: CanvasItem):
	for mesh in meshes:
		ci.draw_mesh(mesh, texture, texture_normal)
