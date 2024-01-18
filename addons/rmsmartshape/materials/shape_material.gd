@tool
extends Resource
class_name SS2D_Material_Shape

## This material represents the set of edge materials used for a smart shape.
##
## Each edge represents a set of textures used to render an edge.

## List of materials this shape can use.
@export var _edge_meta_materials: Array[SS2D_Material_Edge_Metadata] = [] : set = set_edge_meta_materials
@export var fill_textures: Array[Texture2D] = [] : set = set_fill_textures
@export var fill_texture_z_index: int = -10 : set = set_fill_texture_z_index
@export var fill_texture_show_behind_parent: bool = false : set = set_fill_texture_show_behind_parent

## Scale the fill texture
@export_range(0.1, 4, 0.01, "or_greater") var fill_texture_scale: float = 1.0 : set = set_fill_texture_scale

## Whether the fill texture should start at the global 0/0 instead of the node's 0/0
@export var fill_texture_absolute_position: bool = false : set = set_fill_texture_absolute_position

## Whether the fill texture should ignore the node's rotation
@export var fill_texture_absolute_rotation: bool = false : set = set_fill_texture_absolute_rotation

## How many pixels the fill texture should be shifted in x and y direction
@export var fill_texture_offset: Vector2 = Vector2.ZERO : set = set_fill_texture_offset

## Added rotation of the texture in degrees
@export_range(-180, 180, 0.1) var fill_texture_angle_offset: float = 0.0 : set = set_fill_texture_angle_offset

@export var fill_mesh_offset: float = 0.0 : set = set_fill_mesh_offset
@export var fill_mesh_material: Material = null : set = set_fill_mesh_material

## How much to offset all edges
@export_range (-1.5, 1.5, 0.1) var render_offset: float = 0.0 : set = set_render_offset


func set_fill_mesh_material(m: Material) -> void:
	fill_mesh_material = m
	emit_changed()


func set_fill_mesh_offset(f: float) -> void:
	fill_mesh_offset = f
	emit_changed()


func set_render_offset(f: float) -> void:
	render_offset = f
	emit_changed()


## Get all valid edge materials for this normal.
func get_edge_meta_materials(normal: Vector2) -> Array[SS2D_Material_Edge_Metadata]:
	var materials: Array[SS2D_Material_Edge_Metadata] = []
	for e in _edge_meta_materials:
		if e == null:
			continue
		if e.normal_range.is_in_range(normal):
			materials.push_back(e)
	return materials


func get_all_edge_meta_materials() -> Array[SS2D_Material_Edge_Metadata]:
	return _edge_meta_materials


func get_all_edge_materials() -> Array[SS2D_Material_Edge]:
	var materials: Array[SS2D_Material_Edge] = []
	for meta in _edge_meta_materials:
		if meta.edge_material != null:
			materials.push_back(meta.edge_material)
	return materials


func add_edge_material(e: SS2D_Material_Edge_Metadata) -> void:
	var new_array := _edge_meta_materials.duplicate()
	new_array.push_back(e)
	set_edge_meta_materials(new_array)


func _on_edge_material_changed() -> void:
	emit_changed()


func set_fill_textures(a: Array[Texture2D]) -> void:
	fill_textures = a
	emit_changed()


func set_fill_texture_z_index(i: int) -> void:
	fill_texture_z_index = i
	emit_changed()


func set_fill_texture_show_behind_parent(value: bool) -> void:
	fill_texture_show_behind_parent = value
	emit_changed()


func set_edge_meta_materials(a: Array[SS2D_Material_Edge_Metadata]) -> void:
	for e in _edge_meta_materials:
		if e == null:
			continue
		if not a.has(e):
			e.disconnect("changed", self._on_edge_material_changed)

	for e in a:
		if e == null:
			continue
		if not e.is_connected("changed", self._on_edge_material_changed):
			e.connect("changed", self._on_edge_material_changed)

	_edge_meta_materials = a
	emit_changed()


func set_fill_texture_offset(value: Vector2) -> void:
	fill_texture_offset = value
	emit_changed()


func set_fill_texture_scale(value:float) -> void:
	fill_texture_scale = value
	emit_changed()


func set_fill_texture_absolute_rotation(value: bool) -> void:
	fill_texture_absolute_rotation = value
	emit_changed()


func set_fill_texture_angle_offset(value: float) -> void:
	fill_texture_angle_offset = value
	emit_changed()


func set_fill_texture_absolute_position(value: bool) -> void:
	fill_texture_absolute_position = value
	emit_changed()