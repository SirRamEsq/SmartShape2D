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
	mesh_transform = xform

func duplicate(sub_resource: bool = false):
	var _new = __new()
	_new.texture = texture
	_new.texture_normal = texture_normal
	_new.flip_texture = flip_texture
	_new.mesh_transform = mesh_transform
	_new.meshes = []
	if sub_resource:
		for m in meshes:
			_new.meshes.push_back(m.duplicate(true))
	return _new



func matches(tex: Texture, tex_n: Texture, f: bool, t: Transform2D) -> bool:
	if tex == texture and tex_n == texture_normal and f == flip_texture and t == mesh_transform:
		return true
	return false

func debug_print_array_mesh(am:ArrayMesh)->String:
	var s =  "Faces:%s  |  Surfs:%s  | " % [am.get_faces(), am.get_surface_count()]
	return s

func render(ci: CanvasItem):
	#print("mesh count %s" % meshes.size())
	for mesh in meshes:
		ci.draw_mesh(mesh, texture, texture_normal)

# Workaround (class cannot reference itself)
func __new() -> SS2D_Point:
	return get_script().new()
