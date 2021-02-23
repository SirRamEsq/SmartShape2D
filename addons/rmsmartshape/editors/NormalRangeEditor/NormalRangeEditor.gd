tool
extends VBoxContainer
class_name SS2D_NormalRangeEditor

signal value_changed

var start setget _set_start, _get_start
var end setget _set_end, _get_end
var zero_equals_full_circle = true


# Called when the node enters the scene tree for the first time.
func _ready():
	_set_initial_angles()


func _enter_tree():
	_set_initial_angles()


func _set_initial_angles():
	_set_start(get_node("CenterContainer/TextureProgress").radial_initial_angle)
	_set_end(get_node("CenterContainer/TextureProgress").radial_fill_degrees)


func _on_startSlider_value_changed(value):
	_set_start(value)


func _on_endSlider_value_changed(value):
	_set_end(value)


func _set_start(value):
	var fill = get_node("CenterContainer/TextureProgress").radial_fill_degrees
	var init_angle = 360 - fill - value + 90
	get_node("CenterContainer/TextureProgress").radial_initial_angle = _mutate_angle_deg(init_angle)


func _get_start():
	return get_node("CenterContainer/TextureProgress").radial_initial_angle


func _set_end(value):
	get_node("CenterContainer/TextureProgress").radial_fill_degrees = _mutate_angle_deg(value)


func _get_end():
	return get_node("CenterContainer/TextureProgress").radial_fill_degrees


func _on_SS2D_StartEditorSpinSlider_value_changed(value):
	_set_start(value)


func _mutate_angle_deg(v: float) -> float:
	if zero_equals_full_circle and v == 0.0:
		return 360.0
	return v
