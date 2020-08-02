tool
extends PanelContainer

export (NodePath) var p_lbl_idx
export (NodePath) var p_btn_material_override
export (NodePath) var p_ctr_override
export (NodePath) var p_chk_render

var indicies = [-1, -1] setget set_indicies

signal set_material_override(enabled)
signal set_render(enabled)


func _ready():
	var n_btn_override = get_node(p_btn_material_override)
	n_btn_override.connect("toggled", self, "_on_toggle_material_override")

	var n_btn_render = get_node(p_chk_render)
	n_btn_render.connect("toggled", self, "_on_toggle_render")


func set_indicies(a: Array):
	indicies = a
	get_node(p_lbl_idx).text = "IDX: [%s, %s]" % [indicies[0], indicies[1]]


func set_material_override(enabled: bool):
	var n_btn_override = get_node(p_btn_material_override)
	n_btn_override.pressed = enabled
	_on_toggle_material_override(enabled)


func set_render(enabled: bool):
	_on_toggle_render(enabled)


func _on_toggle_material_override(pressed: bool):
	var n_override_container = get_node(p_ctr_override)
	n_override_container.visible = pressed
	emit_signal("set_material_override", pressed)


func _on_toggle_render(pressed: bool):
	emit_signal("set_render", pressed)
