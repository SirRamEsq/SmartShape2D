@tool
extends Resource
class_name RMS2D_Material

@export var fill_texture: Texture2D = null : set = _set_fill_texture
@export var fill_texture_normal: Texture2D = null : set = _set_fill_texture_normal

@export_range (0, 180.0) var top_texture_tilt: float = 20.0 : set = _set_top_texture_tilt
@export_range (0, 180.0) var bottom_texture_tilt: float = 20.0 : set = _set_bottom_texture_tilt

@export var top_texture: Array[Texture2D] : set = _set_top_texture
@export var top_texture_normal: Array[Texture2D] : set = _set_top_texture_normal

@export var left_texture: Array[Texture2D] : set = _set_left_texture
@export var left_texture_normal: Array[Texture2D] : set = _set_left_texture_normal

@export var right_texture: Array[Texture2D] : set = _set_right_texture
@export var right_texture_normal: Array[Texture2D] : set = _set_right_texture_normal

@export var bottom_texture: Array[Texture2D] : set = _set_bottom_texture
@export var bottom_texture_normal: Array[Texture2D] : set = _set_bottom_texture_normal

@export var use_corners: bool = true : set = _set_use_corners
# Textures for 90 angles
# Inner Angles
@export var top_left_inner_texture: Texture2D : set = _set_top_left_inner_texture
@export var top_left_inner_texture_normal: Texture2D : set = _set_top_left_inner_texture_normal

@export var top_right_inner_texture: Texture2D : set = _set_top_right_inner_texture
@export var top_right_inner_texture_normal: Texture2D : set = _set_top_right_inner_texture_normal

@export var bottom_right_inner_texture: Texture2D : set = _set_bottom_right_inner_texture
@export var bottom_right_inner_texture_normal: Texture2D : set = _set_bottom_right_inner_texture_normal

@export var bottom_left_inner_texture: Texture2D : set = _set_bottom_left_inner_texture
@export var bottom_left_inner_texture_normal: Texture2D : set = _set_bottom_left_inner_texture_normal

# Outer Angles
@export var top_left_outer_texture: Texture2D : set = _set_top_left_outer_texture
@export var top_left_outer_texture_normal: Texture2D : set = _set_top_left_outer_texture_normal

@export var top_right_outer_texture: Texture2D : set = _set_top_right_outer_texture
@export var top_right_outer_texture_normal: Texture2D : set = _set_top_right_outer_texture_normal

@export var bottom_right_outer_texture: Texture2D : set = _set_bottom_right_outer_texture
@export var bottom_right_outer_texture_normal: Texture2D : set = _set_bottom_right_outer_texture_normal

@export var bottom_left_outer_texture: Texture2D : set = _set_bottom_left_outer_texture
@export var bottom_left_outer_texture_normal: Texture2D : set = _set_bottom_left_outer_texture_normal

@export var weld_edges: bool = false : set = _set_weld_edges
@export_range (-1.0, 1.0) var render_offset: float = 0.0 : set = _set_render_offset

"""
The multiplier applied to the width of the quads
"""
@export_range (0, 1.5) var collision_width: float = 1.0 : set = _set_collision_width
"""
The offset applied to the position of the quads
"""
@export_range (-1.5, 1.5) var collision_offset: float = 0.0 : set = _set_collision_offset
"""
The amount the first and final quads extend past the texture (Does not apply to closed shapes)
"""
@export_range (-1.0, 1.0) var collision_extends: float = 0.0 : set = _set_collision_extends


func _set_fill_texture(value):
	fill_texture = value
	emit_signal("changed")


func _set_fill_texture_normal(value):
	fill_texture_normal = value
	emit_signal("changed")


func _set_render_offset(value):
	render_offset = value
	emit_signal("changed")

func _set_bottom_texture(value):
	bottom_texture = value
	emit_signal("changed")


func _set_bottom_texture_normal(value):
	bottom_texture_normal = value
	emit_signal("changed")


func _set_bottom_texture_tilt(value):
	bottom_texture_tilt = value
	emit_signal("changed")


func _set_collision_width(value:float):
	collision_width = value
	emit_signal("changed")


func _set_collision_offset(value:float):
	collision_offset = value
	emit_signal("changed")


func _set_collision_extends(value:float):
	collision_extends = value
	emit_signal("changed")


func _set_left_texture(value):
	left_texture = value
	emit_signal("changed")


func _set_left_texture_normal(value):
	left_texture_normal = value
	emit_signal("changed")


func _set_right_texture(value):
	right_texture = value
	emit_signal("changed")


func _set_right_texture_normal(value):
	right_texture_normal = value
	emit_signal("changed")


func _set_top_texture(value):
	top_texture = value
	emit_signal("changed")


func _set_top_texture_normal(value):
	top_texture_normal = value
	emit_signal("changed")


func _set_top_texture_tilt(value):
	top_texture_tilt = value
	emit_signal("changed")


func _set_weld_edges(value):
	weld_edges = value
	emit_signal("changed")


func _set_use_corners(value):
	use_corners = value
	emit_signal("changed")


func _set_top_left_inner_texture(value):
	top_left_inner_texture = value
	emit_signal("changed")


func _set_top_right_inner_texture(value):
	top_right_inner_texture = value
	emit_signal("changed")


func _set_bottom_right_inner_texture(value):
	bottom_right_inner_texture = value
	emit_signal("changed")


func _set_bottom_left_inner_texture(value):
	bottom_left_inner_texture = value
	emit_signal("changed")


func _set_top_left_inner_texture_normal(value):
	top_left_inner_texture_normal = value
	emit_signal("changed")


func _set_top_right_inner_texture_normal(value):
	top_right_inner_texture_normal = value
	emit_signal("changed")


func _set_bottom_right_inner_texture_normal(value):
	bottom_right_inner_texture_normal = value
	emit_signal("changed")


func _set_bottom_left_inner_texture_normal(value):
	bottom_left_inner_texture_normal = value
	emit_signal("changed")


func _set_top_left_outer_texture(value):
	top_left_outer_texture = value
	emit_signal("changed")


func _set_top_right_outer_texture(value):
	top_right_outer_texture = value
	emit_signal("changed")


func _set_bottom_right_outer_texture(value):
	bottom_right_outer_texture = value
	emit_signal("changed")


func _set_bottom_left_outer_texture(value):
	bottom_left_outer_texture = value
	emit_signal("changed")


func _set_top_left_outer_texture_normal(value):
	top_left_outer_texture_normal = value
	emit_signal("changed")


func _set_top_right_outer_texture_normal(value):
	top_right_outer_texture_normal = value
	emit_signal("changed")


func _set_bottom_right_outer_texture_normal(value):
	bottom_right_outer_texture_normal = value
	emit_signal("changed")


func _set_bottom_left_outer_texture_normal(value):
	bottom_left_outer_texture_normal = value
	emit_signal("changed")
