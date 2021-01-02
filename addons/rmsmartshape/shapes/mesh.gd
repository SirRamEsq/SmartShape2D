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
var material: Material = null
var z_index: int = 0
var z_as_relative: bool = true


func _init(
	t: Texture = null,
	tn: Texture = null,
	f: bool = false,
	xform: Transform2D = Transform2D(),
	m: Array = [],
	mat: Material = null
):
	texture = t
	texture_normal = tn
	flip_texture = f
	meshes = m
	mesh_transform = xform
	material = mat


func duplicate(sub_resource: bool = false):
	var _new = __new()
	_new.texture = texture
	_new.texture_normal = texture_normal
	_new.flip_texture = flip_texture
	_new.mesh_transform = mesh_transform
	_new.material = material
	_new.z_index = z_index
	_new.z_as_relative = z_as_relative
	_new.meshes = []
	if sub_resource:
		for m in meshes:
			_new.meshes.push_back(m.duplicate(true))
	return _new


func matches(tex: Texture, tex_n: Texture, f: bool, t: Transform2D, m: Material, zi: int, zb: bool) -> bool:
	if (
		tex == texture
		and tex_n == texture_normal
		and f == flip_texture
		and t == mesh_transform
		and m == material
		and zi == z_index
		and zb == z_as_relative
	):
		return true
	return false


func mesh_matches(m) -> bool:
	return matches(
		m.texture,
		m.texture_normal,
		m.flip_texture,
		m.mesh_transform,
		m.material,
		m.z_index,
		m.z_as_relative
	)


func debug_print_array_mesh(am: ArrayMesh) -> String:
	var s = "Faces:%s  |  Surfs:%s  | " % [am.get_faces(), am.get_surface_count()]
	return s


func render(ci: CanvasItem):
	#print("mesh count %s" % meshes.size())
	for mesh in meshes:
		ci.draw_mesh(mesh, texture, texture_normal)


# Workaround (class cannot reference itself)
func __new() -> SS2D_Point:
	return get_script().new()
