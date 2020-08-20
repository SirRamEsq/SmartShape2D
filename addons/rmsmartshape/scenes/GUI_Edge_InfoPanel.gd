tool
extends PanelContainer

export (NodePath) var p_lbl_idx
export (NodePath) var p_btn_material_override
export (NodePath) var p_ctr_override
export (NodePath) var p_chk_render
export (NodePath) var p_chk_weld
export (NodePath) var p_int_index

var indicies = [-1, -1] setget set_indicies

signal set_material_override(enabled)
signal set_render(enabled)
signal set_weld(enabled)
signal set_z_index(value)


func _ready():
	var n_btn_override = get_node(p_btn_material_override)
	n_btn_override.connect("toggled", self, "_on_toggle_material_override")

	var n_btn_render = get_node(p_chk_render)
	n_btn_render.connect("toggled", self, "_on_toggle_render")

	var n_btn_weld = get_node(p_chk_weld)
	n_btn_weld.connect("toggled", self, "_on_toggle_weld")

	var n_int_index = get_node(p_int_index)
	n_int_index.connect("value_changed", self, "_on_set_z_index")


func set_indicies(a: Array):
	indicies = a
	get_node(p_lbl_idx).text = "IDX: [%s, %s]" % [indicies[0], indicies[1]]


func set_material_override(enabled: bool):
	var n_btn_override = get_node(p_btn_material_override)
	n_btn_override.pressed = enabled
	_on_toggle_material_override(enabled)


func set_render(enabled: bool):
	get_node(p_chk_render).pressed = enabled
	_on_toggle_render(enabled)


func set_weld(enabled: bool):
	get_node(p_chk_weld).pressed = enabled
	_on_toggle_weld(enabled)


func set_z_index(v: int):
	get_node(p_int_index).value = float(v)
	_on_set_z_index(float(v))


func get_render() -> bool:
	return get_node(p_chk_render).pressed


func get_weld() -> bool:
	return get_node(p_chk_weld).pressed


func get_z_index() -> int:
	return get_node(p_int_index).value


func _on_toggle_material_override(pressed: bool):
	var n_override_container = get_node(p_ctr_override)
	n_override_container.visible = pressed
	emit_signal("set_material_override", pressed)


func _on_toggle_render(pressed: bool):
	emit_signal("set_render", pressed)


func _on_toggle_weld(pressed: bool):
	emit_signal("set_weld", pressed)


func _on_set_z_index(v: float):
	emit_signal("set_z_index", int(v))


func load_values_from_meta_material(meta_mat: RMSS2D_Material_Edge_Metadata):
	set_render(meta_mat.render)
	set_weld(meta_mat.weld)
	set_z_index(meta_mat.z_index)


func save_values_to_meta_material(meta_mat: RMSS2D_Material_Edge_Metadata):
	meta_mat.render = get_render()
	meta_mat.weld = get_weld()
	meta_mat.z_index = get_z_index()
