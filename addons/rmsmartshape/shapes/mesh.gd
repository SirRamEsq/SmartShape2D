@tool
extends RefCounted
class_name SS2D_Mesh

## Used to organize all requested meshes to be rendered by their textures.

var texture: Texture2D = null
var flip_texture: bool = false
var meshes: Array[ArrayMesh] = []
var mesh_transform: Transform2D = Transform2D()
var material: Material = null
var z_index: int = 0
var z_as_relative: bool = true
var show_behind_parent: bool = false


func _init(
	t: Texture2D = null,
	f: bool = false,
	xform: Transform2D = Transform2D(),
	m: Array[ArrayMesh] = [],
	mat: Material = null
) -> void:
	texture = t
	flip_texture = f
	meshes = m
	mesh_transform = xform
	material = mat


# Note: Not an override.
func duplicate(subresources: bool = false) -> SS2D_Mesh:
	var copy := SS2D_Mesh.new()
	copy.texture = texture
	copy.flip_texture = flip_texture
	copy.mesh_transform = mesh_transform
	copy.material = material
	copy.z_index = z_index
	copy.z_as_relative = z_as_relative
	copy.show_behind_parent = show_behind_parent
	copy.meshes = []
	if subresources:
		for m in meshes:
			copy.meshes.push_back(m.duplicate(true))
	return copy


func matches(tex: Texture2D, f: bool, t: Transform2D, m: Material, zi: int, zb: bool) -> bool:
	return (
		tex == texture
		and f == flip_texture
		and t == mesh_transform
		and m == material
		and zi == z_index
		and zb == z_as_relative
	)


func mesh_matches(m: SS2D_Mesh) -> bool:
	return matches(
		m.texture,
		m.flip_texture,
		m.mesh_transform,
		m.material,
		m.z_index,
		m.z_as_relative
	)


func debug_print_array_mesh(am: ArrayMesh) -> String:
	var s := "Faces:%s  |  Surfs:%s  | " % [am.get_faces(), am.get_surface_count()]
	return s


func render(ci: CanvasItem) -> void:
	#print("mesh count %s" % meshes.size())
	for mesh in meshes:
		ci.draw_mesh(mesh, texture)
