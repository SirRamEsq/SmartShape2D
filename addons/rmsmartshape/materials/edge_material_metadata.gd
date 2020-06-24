tool
extends Resource
class_name RMSS2D_Material_Edge_Metadata

"""
Represents the metadata for an edge material
Used by Shape Material
"""

export (Resource) var edge_material = RMSS2D_Material_Edge.new()
# What range of normals can this edge be used on
export (Resource) var normal_range = RMSS2D_NormalRange.new(0, 360)
# If edge should be welded to the edges surrounding it
export (bool) var weld: bool = true
# z index for an edge
export (int) var z_index: int = 0
# Distance from center
export (float, -1.5, 1.5, 0.1) var offset: float = 0.0
