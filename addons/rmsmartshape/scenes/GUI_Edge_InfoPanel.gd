@tool
extends PanelContainer
class_name SS2D_EdgeInfoPanel

signal material_override_toggled(enabled: bool)
signal render_toggled(enabled: bool)
signal weld_toggled(enabled: bool)
signal z_index_changed(value: int)
signal edge_material_changed(value: SS2D_Material_Edge)

var indicies := Vector2i(-1, -1) : set = set_indicies
var edge_material: SS2D_Material_Edge = null
var edge_material_selector := FileDialog.new()

@onready var idx_label: Label = %IDX
@onready var material_override_button: Button = %MaterialOverride
@onready var override_container: Container = %OverrideContainer
@onready var render_checkbox: CheckBox = %Render
@onready var weld_checkbox: CheckBox = %Weld
@onready var z_index_spinbox: SpinBox = %ZIndex
@onready var set_material_button: Button = %SetMaterial
@onready var clear_material_button: Button = %ClearMaterial
@onready var material_status: Label = %MaterialStatus


func _ready() -> void:
	material_override_button.connect("toggled", self._on_toggle_material_override)
	render_checkbox.connect("toggled", self._on_toggle_render)
	weld_checkbox.connect("toggled", self._on_toggle_weld)
	z_index_spinbox.connect("value_changed", self._on_set_z_index)
	set_material_button.connect("pressed", self._on_set_edge_material_pressed)
	clear_material_button.connect("pressed", self._on_set_edge_material_clear_pressed)

	override_container.hide()
	clear_material_button.hide()

	edge_material_selector.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	edge_material_selector.dialog_hide_on_ok = true
	edge_material_selector.show_hidden_files = true
	edge_material_selector.mode_overrides_title = false
	edge_material_selector.title = "Select Edge Material"
	edge_material_selector.filters = PackedStringArray(["*.tres"])
	edge_material_selector.connect("file_selected", self._on_set_edge_material_file_selected)
	add_child(edge_material_selector)


func _on_set_edge_material_clear_pressed() -> void:
	set_edge_material(null)


func _on_set_edge_material_pressed() -> void:
	# Update file list
	edge_material_selector.invalidate()
	edge_material_selector.popup_centered_ratio(0.8)


func _on_set_edge_material_file_selected(f: String) -> void:
	var rsc := load(f)
	if not rsc is SS2D_Material_Edge:
		push_error("Selected resource is not an Edge Material! (SS2D_Material_Edge)")
		return
	set_edge_material(rsc)


func set_indicies(t: Vector2i) -> void:
	indicies = t
	idx_label.text = "IDX: %s" % indicies


func set_material_override(enabled: bool) -> void:
	material_override_button.button_pressed = enabled
	_on_toggle_material_override(enabled)


func set_render(enabled: bool, emit: bool = true) -> void:
	render_checkbox.button_pressed = enabled
	if emit:
		_on_toggle_render(enabled)


func set_weld(enabled: bool, emit: bool = true) -> void:
	weld_checkbox.button_pressed = enabled
	if emit:
		_on_toggle_weld(enabled)


func set_edge_material(v: SS2D_Material_Edge, emit: bool = true) -> void:
	edge_material = v
	if v == null:
		material_status.text = "[No Material]"
		clear_material_button.visible = false
	else:
		# Call string function 'get_file()' to get the filepath
		material_status.text = "[%s]" % (v.resource_path).get_file()
		clear_material_button.visible = true
	if emit:
		emit_signal("edge_material_changed", v)


func set_edge_z_index(v: int, emit: bool = true) -> void:
	z_index_spinbox.value = float(v)
	if emit:
		_on_set_z_index(float(v))


func get_render() -> bool:
	return render_checkbox.button_pressed


func get_weld() -> bool:
	return weld_checkbox.button_pressed


func get_edge_z_index() -> int:
	return int(z_index_spinbox.value)


func _on_toggle_material_override(pressed: bool) -> void:
	override_container.visible = pressed
	emit_signal("material_override_toggled", pressed)


func _on_toggle_render(pressed: bool) -> void:
	emit_signal("render_toggled", pressed)


func _on_toggle_weld(pressed: bool) -> void:
	emit_signal("weld_toggled", pressed)


func _on_set_z_index(v: float) -> void:
	emit_signal("z_index_changed", int(v))


func load_values_from_meta_material(meta_mat: SS2D_Material_Edge_Metadata) -> void:
	set_render(meta_mat.render)
	set_weld(meta_mat.weld)
	set_z_index(meta_mat.z_index)
	set_edge_material(meta_mat.edge_material)


func save_values_to_meta_material(meta_mat: SS2D_Material_Edge_Metadata) -> void:
	meta_mat.render = get_render()
	meta_mat.weld = get_weld()
	meta_mat.z_index = get_z_index()
	meta_mat.edge_material = edge_material
