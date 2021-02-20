tool
extends VBoxContainer
class_name SS2D_NormalRangeEditor

signal valueChanged

var start setget _setstart, _getstart
var end setget _setend, _getend

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_initial_angles()
	
func _enter_tree():
	_set_initial_angles()

func _set_initial_angles():
	_setstart(get_node("CenterContainer/TextureProgress").radial_initial_angle)
	_setend(get_node("CenterContainer/TextureProgress").radial_fill_degrees)

func _on_startSlider_value_changed(value):
	_setstart(value)

func _on_endSlider_value_changed(value):
	_setend(value)

func _setstart(value):
	var fill = get_node("CenterContainer/TextureProgress").radial_fill_degrees
	get_node("CenterContainer/TextureProgress").radial_initial_angle = 360 - fill - value + 90
	
func _getstart():
	return get_node("CenterContainer/TextureProgress").radial_initial_angle
	
func _setend(value):
	get_node("CenterContainer/TextureProgress").radial_fill_degrees = value
	
func _getend():
	return get_node("CenterContainer/TextureProgress").radial_fill_degrees

func _on_SS2D_StartEditorSpinSlider_value_changed(value):
	_setstart(value)
