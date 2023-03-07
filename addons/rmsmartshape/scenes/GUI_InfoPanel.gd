@tool
extends PanelContainer


@onready var idx_label: Label = %IDX
@onready var tex_label: Label = %Tex
@onready var width_label: Label = %Width
@onready var flip_label: Label = %Flip


func set_idx(i: int) -> void:
	idx_label.text = "IDX: %s" % i


func set_texture_idx(i: int) -> void:
	tex_label.text = "Texture2D: %s" % i


func set_width(f: float) -> void:
	width_label.text = "Width: %s" % f


func set_flip(b: bool) -> void:
	flip_label.text = "Flip: %s" % b
