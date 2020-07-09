tool
extends Resource
class_name RMSS2D_Material_Shape

"""
This material represents the set of edge materials used for a RMSmartShape2D
Each edge represents a set of textures used to render an edge
"""

# List of materials this shape can use
export (Array, Resource) var _edge_materials: Array = [] setget set_edge_materials

export (Array, Texture) var fill_textures: Array = []
export (Array, Texture) var fill_texture_normals: Array = []
export (int) var fill_texture_z_index: int = 0

# How much to offset all edges
export (float, -1.5, 1.5, 0.1) var render_offset: float = 0.0

# Width of collision quads
export (float, -1.5, 1.5, 0.1) var collision_width: float = 1.0
# Offset of collision quads
export (float, -1.5, 1.5, 0.1) var collision_offset: float = 0.0
# Extents of collision quads for open shapes
export (float, -1.5, 1.5, 0.1) var collision_extends: float = 0.0


# Get all valid edge materials for this normal
func get_edge_materials(normal: Vector2) -> Array:
	var materials = []
	for e in _edge_materials:
		if e.normal_range.is_in_range(normal):
			materials.push_back(e)
	return materials


func get_all_edge_materials() -> Array:
	return _edge_materials


func add_edge_material(e: RMSS2D_Material_Edge_Metadata):
	var new_array = _edge_materials.duplicate()
	new_array.push_back(e)
	set_edge_materials(new_array)


func _on_edge_material_changed():
	emit_signal("changed")


func set_edge_materials(a: Array):
	for e in _edge_materials:
		if not a.has(e):
			e.disconnect("changed", self, "_on_edge_material_changed")

	for e in a:
		if not e.is_connected("changed", self, "_on_edge_material_changed"):
			e.connect("changed", self, "_on_edge_material_changed")

	_edge_materials = a
	emit_signal("changed")
