tool
extends PanelContainer

export (NodePath) var p_lbl_idx
export (NodePath) var p_btn_material_override
export (NodePath) var p_ctr_override
export (NodePath) var p_chk_render
export (NodePath) var p_chk_weld
export (NodePath) var p_int_index
export (NodePath) var p_btn_edge_material
export (NodePath) var p_btn_clear_edge_material
export (NodePath) var p_lbl_edge_material

var indicies = [-1, -1] setget set_indicies
var edge_material = null
var edge_material_selector = FileDialog.new()

signal set_material_override(enabled)
signal set_render(enabled)
signal set_weld(enabled)
signal set_z_index(value)
signal set_edge_material(value)


func _ready():
	var n_btn_override = get_node(p_btn_material_override)
	n_btn_override.connect("toggled", self, "_on_toggle_material_override")

	var n_chk_render = get_node(p_chk_render)
	n_chk_render.connect("toggled", self, "_on_toggle_render")

	var n_btn_weld = get_node(p_chk_weld)
	n_btn_weld.connect("toggled", self, "_on_toggle_weld")

	var n_int_index = get_node(p_int_index)
	n_int_index.connect("value_changed", self, "_on_set_z_index")

	var n_btn_edge_material = get_node(p_btn_edge_material)
	n_btn_edge_material.connect("pressed", self, "_on_set_edge_material_pressed")

	var n_btn_clear_edge_material = get_node(p_btn_clear_edge_material)
	n_btn_clear_edge_material.connect("pressed", self, "_on_set_edge_material_clear_pressed")

	edge_material_selector.mode = FileDialog.MODE_OPEN_FILE
	edge_material_selector.dialog_hide_on_ok = true
	edge_material_selector.show_hidden_files = true
	edge_material_selector.mode_overrides_title = false
	edge_material_selector.window_title = "Select Edge Material"
	edge_material_selector.filters = PoolStringArray(["*.tres"])
	edge_material_selector.connect("file_selected", self, "_on_set_edge_material_file_selected")
	add_child(edge_material_selector)


func _on_set_edge_material_clear_pressed():
	set_edge_material(null)


func _on_set_edge_material_pressed():
	# Update file list
	edge_material_selector.invalidate()
	edge_material_selector.popup_centered_ratio(0.8)


func _on_set_edge_material_file_selected(f: String):
	var rsc = load(f)
	if not rsc is SS2D_Material_Edge:
		push_error("Selected resource is not an Edge Material! (SS2D_Material_Edge)")
		return
	set_edge_material(rsc)


func set_indicies(a: Array):
	indicies = a
	get_node(p_lbl_idx).text = "IDX: [%s, %s]" % [indicies[0], indicies[1]]


func set_material_override(enabled: bool):
	var n_btn_override = get_node(p_btn_material_override)
	n_btn_override.pressed = enabled
	_on_toggle_material_override(enabled)


func set_render(enabled: bool, emit: bool = true):
	get_node(p_chk_render).pressed = enabled
	if emit:
		_on_toggle_render(enabled)


func set_weld(enabled: bool, emit: bool = true):
	get_node(p_chk_weld).pressed = enabled
	if emit:
		_on_toggle_weld(enabled)


func set_edge_material(v: SS2D_Material_Edge, emit: bool = true):
	edge_material = v
	if v == null:
		get_node(p_lbl_edge_material).text = "[No Material]"
		get_node(p_btn_clear_edge_material).visible = false
	else:
		# Call string function 'get_file()' to get the filepath
		get_node(p_lbl_edge_material).text = "[%s]" % (v.resource_path).get_file()
		get_node(p_btn_clear_edge_material).visible = true
	if emit:
		emit_signal("set_edge_material", v)


func set_z_index(v: int, emit: bool = true):
	get_node(p_int_index).value = float(v)
	if emit:
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


func load_values_from_meta_material(meta_mat: SS2D_Material_Edge_Metadata):
	set_render(meta_mat.render)
	set_weld(meta_mat.weld)
	set_z_index(meta_mat.z_index)
	set_edge_material(meta_mat.edge_material)


func save_values_to_meta_material(meta_mat: SS2D_Material_Edge_Metadata):
	meta_mat.render = get_render()
	meta_mat.weld = get_weld()
	meta_mat.z_index = get_z_index()
	meta_mat.edge_material = edge_material
