@tool
extends VBoxContainer
class_name SS2D_NormalRangeEditor

signal value_changed

var start: float: get = _get_start, set = _set_start
var end: float: get = _get_end, set = _set_end
var zero_equals_full_circle := true

var _progress_bar: TextureProgressBar:
	get:
		if _progress_bar == null:
			_progress_bar = get_node_or_null("%TextureProgressBar")
		return _progress_bar


func _ready() -> void:
	_set_initial_angles()


func _enter_tree() -> void:
	_set_initial_angles()


func _set_initial_angles() -> void:
	_set_start(_progress_bar.radial_initial_angle)
	_set_end(_progress_bar.radial_fill_degrees)


func _on_startSlider_value_changed(value: float) -> void:
	_set_start(value)


func _on_endSlider_value_changed(value: float) -> void:
	_set_end(value)


func _set_start(value: float) -> void:
	var fill: float = _progress_bar.radial_fill_degrees
	var init_angle: float = 360.0 - fill - value + 90.0
	_progress_bar.radial_initial_angle = _mutate_angle_deg(init_angle)


func _get_start() -> float:
	return _progress_bar.radial_initial_angle


func _set_end(value: float) -> void:
	_progress_bar.radial_fill_degrees = _mutate_angle_deg(value)


func _get_end() -> float:
	return _progress_bar.radial_fill_degrees


func _on_SS2D_StartEditorSpinSlider_value_changed(value: float) -> void:
	_set_start(value)


func _mutate_angle_deg(v: float) -> float:
	if zero_equals_full_circle and v == 0.0:
		return 360.0
	return v
