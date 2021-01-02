tool
extends Resource
class_name SS2D_Material_Edge_Metadata

"""
Represents the metadata for an edge material
Used by Shape Material
"""

export (Resource) var edge_material = null setget set_edge_material
# What range of normals can this edge be used on
export (Resource) var normal_range = SS2D_NormalRange.new(0, 360) setget set_normal_range
# If edge should be welded to the edges surrounding it
export (bool) var weld: bool = true setget set_weld
# If this edge should be visible
export (bool) var render: bool = true setget set_render
# z index for an edge
export (int) var z_index: int = 0 setget set_z_index
# z index for an edge
export (int) var z_as_relative: bool = true setget set_z_as_relative
# Distance from center
export (float, -1.5, 1.5, 0.1) var offset: float = 0.0 setget set_offset


func _to_string() -> String:
	return "%s | %s" % [str(edge_material), normal_range]


func set_render(b: bool):
	render = b
	emit_signal("changed")


func set_edge_material(m: SS2D_Material_Edge):
	if edge_material != null:
		if edge_material.is_connected("changed", self, "_on_edge_changed"):
			edge_material.disconnect("changed", self, "_on_edge_changed")
	edge_material = m
	if edge_material != null:
		edge_material.connect("changed", self, "_on_edge_changed")
	emit_signal("changed")


func set_normal_range(nr: SS2D_NormalRange):
	if nr == null:
		return
	if normal_range.is_connected("changed", self, "_on_edge_changed"):
		normal_range.disconnect("changed", self, "_on_edge_changed")
	normal_range = nr
	normal_range.connect("changed", self, "_on_edge_changed")
	emit_signal("changed")


func set_weld(b: bool):
	weld = b
	emit_signal("changed")


func set_z_index(z: int):
	z_index = z
	emit_signal("changed")

func set_z_as_relative(b: bool):
	z_as_relative = b
	emit_signal("changed")

func set_offset(f: float):
	offset = f
	emit_signal("changed")


func _on_edge_changed():
	emit_signal("changed")
