tool
extends Resource
class_name SS2D_Material_Shape

"""
This material represents the set of edge materials used for a RMSmartShape2D
Each edge represents a set of textures used to render an edge
"""

# List of materials this shape can use
# Should be SS2D_Material_Edge_Metadata
export (Array, Resource) var _edge_meta_materials: Array = [] setget set_edge_meta_materials
export (Array, Texture) var fill_textures: Array = [] setget set_fill_textures
export (Array, Texture) var fill_texture_normals: Array = [] setget set_fill_texture_normals
export (int) var fill_texture_z_index: int = -10 setget set_fill_texture_z_index
export (float) var fill_mesh_offset: float = 0.0 setget set_fill_mesh_offset
export (Material) var fill_mesh_material: Material = null setget set_fill_mesh_material

# How much to offset all edges
export (float, -1.5, 1.5, 0.1) var render_offset: float = 0.0 setget set_render_offset


func set_fill_mesh_material(m: Material):
	fill_mesh_material = m
	emit_signal("changed")


func set_fill_mesh_offset(f: float):
	fill_mesh_offset = f
	emit_signal("changed")


func set_render_offset(f: float):
	render_offset = f
	emit_signal("changed")


# Get all valid edge materials for this normal
func get_edge_meta_materials(normal: Vector2) -> Array:
	var materials = []
	for e in _edge_meta_materials:
		if e == null:
			continue
		if e.normal_range.is_in_range(normal):
			materials.push_back(e)
	return materials


func get_all_edge_meta_materials() -> Array:
	return _edge_meta_materials


func get_all_edge_materials() -> Array:
	var materials = []
	for meta in _edge_meta_materials:
		if meta.edge_material != null:
			materials.push_back(meta.edge_material)
	return materials


func add_edge_material(e: SS2D_Material_Edge_Metadata):
	var new_array = _edge_meta_materials.duplicate()
	new_array.push_back(e)
	set_edge_meta_materials(new_array)


func _on_edge_material_changed():
	emit_signal("changed")


func set_fill_textures(a: Array):
	fill_textures = a
	emit_signal("changed")


func set_fill_texture_normals(a: Array):
	fill_texture_normals = a
	emit_signal("changed")


func set_fill_texture_z_index(i: int):
	fill_texture_z_index = i
	emit_signal("changed")


func set_edge_meta_materials(a: Array):
	for e in _edge_meta_materials:
		if e == null:
			continue
		if not a.has(e):
			e.disconnect("changed", self, "_on_edge_material_changed")

	for e in a:
		if e == null:
			continue
		if not e.is_connected("changed", self, "_on_edge_material_changed"):
			e.connect("changed", self, "_on_edge_material_changed")

	_edge_meta_materials = a
	emit_signal("changed")
