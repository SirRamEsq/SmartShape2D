@tool
extends Resource
class_name SS2D_Material_Edge_Metadata

"""
Represents the metadata for an edge material
Used by Shape Material
"""

@export var edge_material: Resource = null : set = set_edge_material
# What range of normals can this edge be used on
@export var normal_range: Resource = SS2D_NormalRange.new(0, 360) : set = set_normal_range
# If edge should be welded to the edges surrounding it
@export var weld: bool = true : set = set_weld
# If this edge should be visible
@export var render: bool = true : set = set_render
# z index for an edge
@export var z_index: int = 0 : set = set_z_index
# z index for an edge
@export var z_as_relative: bool = true : set = set_z_as_relative
# Distance from center
@export_range (-1.5, 1.5, 0.1) var offset: float = 0.0 : set = set_offset


func _to_string() -> String:
	return "%s | %s" % [str(edge_material), normal_range]


func set_render(b: bool):
	render = b
	emit_signal("changed")


func set_edge_material(m: SS2D_Material_Edge):
	if edge_material != null:
		if edge_material.is_connected("changed",Callable(self,"_on_edge_changed")):
			edge_material.disconnect("changed",Callable(self,"_on_edge_changed"))
	edge_material = m
	if edge_material != null:
		edge_material.connect("changed",Callable(self,"_on_edge_changed"))
	emit_signal("changed")


func set_normal_range(nr: SS2D_NormalRange):
	if nr == null:
		return
	if normal_range.is_connected("changed",Callable(self,"_on_edge_changed")):
		normal_range.disconnect("changed",Callable(self,"_on_edge_changed"))
	normal_range = nr
	normal_range.connect("changed",Callable(self,"_on_edge_changed"))
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
