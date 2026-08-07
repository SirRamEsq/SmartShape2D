@tool
extends Resource
class_name SS2D_Mesh

## This is essentially a serializable data buffer with Node2D properties that will be assigned to a
## rendering node later.

@export var texture: Texture2D = null
@export var mesh := ArrayMesh.new()
@export var material: Material = null
@export var z_index: int = 0
@export var z_as_relative: bool = true
@export var show_behind_parent: bool = false
@export var force_no_tiling: bool = false


func clear() -> void:
	texture = null
	mesh.clear_surfaces()
	material = null
	z_index = 0
	z_as_relative = true
	show_behind_parent = false
	force_no_tiling = false


func clone() -> SS2D_Mesh:
	var new_mesh := SS2D_Mesh.new()
	new_mesh.texture = texture
	new_mesh.mesh = mesh.duplicate()
	new_mesh.material = material
	new_mesh.z_index = z_index
	new_mesh.z_as_relative = z_as_relative
	new_mesh.show_behind_parent = show_behind_parent
	new_mesh.force_no_tiling = force_no_tiling
	return new_mesh
