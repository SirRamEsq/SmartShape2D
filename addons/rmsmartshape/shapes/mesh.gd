@tool
extends RefCounted
class_name SS2D_Mesh

## Used to organize all requested meshes to be rendered by their textures.
## This is essentially a serializable data buffer with Node2D properties that will be assigned to a
## rendering node later.

var texture: Texture2D = null
var mesh: ArrayMesh
var material: Material = null
var z_index: int = 0
var z_as_relative: bool = true
var show_behind_parent: bool = false
var force_no_tiling: bool = false


func _init(
	tex: Texture2D,
	m: ArrayMesh,
	mat: Material,
	z_idx: int,
	z_as_relative_: bool,
	show_behind_parent_: bool,
) -> void:
	texture = tex
	mesh = m
	material = mat
	z_index = z_idx
	z_as_relative = z_as_relative_
	show_behind_parent = show_behind_parent_
