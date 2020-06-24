tool
extends Resource
class_name RMSS2D_Material_Shape

"""
This material represents the set of edge materials used for a RMSmartShape2D
Each edge represents a set of textures used to render an edge
"""

# List of materials this shape can use
export (Array, Resource) var _edge_materials: Array = []

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

func add_edge_material(e:RMSS2D_Material_Edge_Metadata):
	_edge_materials.push_back(e)
