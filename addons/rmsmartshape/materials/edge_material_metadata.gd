tool
extends Resource
class_name RMSS2D_Material_Edge_Metadata

"""
Represents the metadata for an edge material
Used by Shape Material
"""

export (Resource) var edge_material = RMSS2D_Material_Edge.new() setget set_edge_material
# What range of normals can this edge be used on
export (Resource) var normal_range = RMSS2D_NormalRange.new(0, 360) setget set_normal_range
# If edge should be welded to the edges surrounding it
export (bool) var weld: bool = true setget set_weld
# z index for an edge
export (int) var z_index: int = 0 setget set_z_index
# Distance from center
export (float, -1.5, 1.5, 0.1) var offset: float = 0.0 setget set_offset


func _to_string() -> String:
	return "%s | %s" % [str(edge_material), normal_range]


func set_edge_material(m: RMSS2D_Material_Edge):
	if edge_material != null:
		if edge_material.is_connected("changed", self, "_on_edge_changed"):
			edge_material.disconnect("changed", self, "_on_edge_changed")
	edge_material = m
	edge_material.connect("changed", self, "_on_edge_changed")
	emit_signal("changed")


func set_normal_range(nr: RMSS2D_NormalRange):
	if nr == null:
		return
	normal_range = nr
	emit_signal("changed")


func set_weld(b: bool):
	weld = b
	emit_signal("changed")


func set_z_index(z: int):
	z_index = z
	emit_signal("changed")


func set_offset(f: float):
	offset = f
	emit_signal("changed")


func _on_edge_changed():
	emit_signal("changed")
