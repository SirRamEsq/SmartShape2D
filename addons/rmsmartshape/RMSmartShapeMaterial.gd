@tool
extends RefCounted 
class_name RMS2D_Material

# @export (Texture) var fill_texture = null setget _set_fill_texture
var _fill_texture = null
@export var fill_texture : Texture:
	get: return _fill_texture
	set(v): _set_fill_texture

# @export (Texture) var fill_texture_normal = null setget _set_fill_texture_normal
var _fill_texture_normal = null
@export var fill_texture_normal : Texture:
	get: return _fill_texture
	set(v): _set_fill_texture_normal

# @export (float, 0, 180.0) var top_texture_tilt = 20.0 setget _set_top_texture_tilt
var _top_texture_tilt = 20.0
@export_range(0, 180.0, 1) var top_texture_tilt : float:
	get: return _top_texture_tilt
	set(v): _set_top_texture_tilt

# @export (float, 0, 180.0) var bottom_texture_tilt = 20.0 setget _set_bottom_texture_tilt
var _bottom_texture_tilt = 20.0
@export var bottom_texture_tilt : float:
	get: return _bottom_texture_tilt
	set(v): _set_bottom_texture_tilt

# @export (Array, Texture) var top_texture setget _set_top_texture
var _top_texture
@export var top_texture : Array[Texture]:
	get: return _top_texture
	set(v): _set_top_texture

# @export (Array, Texture) var top_texture_normal setget _set_top_texture_normal
var _top_texture_normal
@export var top_texture_normal : Array[Texture]:
	get: return _top_texture_normal
	set(v): _set_top_texture_normal

# @export (Array, Texture) var left_texture setget _set_left_texture
var _left_texture
@export var left_texture : Array[Texture]:
	get: return _left_texture
	set(v): _set_left_texture

# @export (Array, Texture) var left_texture_normal setget _set_left_texture_normal
var _left_texture_normal
var left_texture_normal : Array[Texture]:
	get: return _left_texture_normal
	set(v): _set_left_texture_normal

# @export (Array, Texture) var right_texture setget _set_right_texture
var _right_texture 
@export var right_texture : Array[Texture]:
	get: return _right_texture
	set(v): _set_right_texture

# @export (Array, Texture) var right_texture_normal setget _set_right_texture_normal
var _right_texture_normal
var right_texture_normal : Array[Texture]:
	get: return _right_texture_normal
	set(v): _set_right_texture_normal

# @export (Array, Texture) var bottom_texture setget _set_bottom_texture
var _bottom_texture
@export var bottom_texture : Array[Texture]:
	get: return _bottom_texture
	set(v): _set_bottom_texture

# @export (Array, Texture) var bottom_texture_normal setget _set_bottom_texture_normal
var _bottom_texture_normal
@export var bottom_texture_normal : Array[Texture]:
	get: return _bottom_texture_normal
	set(v): _set_bottom_texture_normal

# @export (bool) var use_corners = true setget _set_use_corners
var _use_corners = true
@export var use_corners : bool:
	get: return _use_corners
	set(v): _set_use_corners

# Textures for 90 angles
# Inner Angles
# @export (Texture) var top_left_inner_texture setget _set_top_left_inner_texture
var _top_left_inner_texture
@export var top_left_inner_texture : Texture:
	get: return _top_left_inner_texture
	set(v): _set_top_left_inner_texture

# @export (Texture) var top_left_inner_texture_normal setget _set_top_left_inner_texture_normal
var _top_left_inner_texture_normal 
@export var top_left_inner_texture_normal : Texture:
	get: return _top_left_inner_texture_normal
	set(v): _set_top_left_inner_texture_normal

# @export (Texture) var top_right_inner_texture setget _set_top_right_inner_texture
var _top_right_inner_texture 
@export var top_right_inner_texture : Texture:
	get: return _top_right_inner_texture
	set(v): _set_top_right_inner_texture

# @export (Texture) var top_right_inner_texture_normal setget _set_top_right_inner_texture_normal
var _top_right_inner_texture_normal 
@export var top_right_inner_texture_normal : Texture:
	get: return _top_right_inner_texture_normal
	set(v): _set_top_right_inner_texture_normal

# @export (Texture) var bottom_right_inner_texture setget _set_bottom_right_inner_texture
var _bottom_right_inner_texture 
@export var bottom_right_inner_texture : Texture:
	get: return _bottom_right_inner_texture
	set(v): _set_bottom_right_inner_texture

# @export (Texture) var bottom_right_inner_texture_normal setget _set_bottom_right_inner_texture_normal
var _bottom_right_inner_texture_normal 
@export var bottom_right_inner_texture_normal : Texture:
	get: return _bottom_right_inner_texture_normal
	set(v): _set_bottom_right_inner_texture_normal

# @export (Texture) var bottom_left_inner_texture setget _set_bottom_left_inner_texture
var _bottom_left_inner_texture 
@export var bottom_left_inner_texture : Texture:
	get: return _bottom_left_inner_texture
	set(v): _set_bottom_left_inner_texture

# @export (Texture) var bottom_left_inner_texture_normal setget _set_bottom_left_inner_texture_normal
var _bottom_left_inner_texture_normal 
@export var bottom_left_inner_texture_normal : Texture:
	get: return _bottom_left_inner_texture_normal
	set(v): _set_bottom_left_inner_texture_normal

# Outer Angles
# @export (Texture) var top_left_outer_texture setget _set_top_left_outer_texture
var _top_left_outer_texture 
@export var top_left_outer_texture : Texture:
	get: return _top_left_outer_texture
	set(v): _set_top_left_outer_texture

# @export (Texture) var top_left_outer_texture_normal setget _set_top_left_outer_texture_normal
var _top_left_outer_texture_normal 
@export var top_left_outer_texture_normal : Texture:
	get: return _top_left_outer_texture_normal
	set(v): _set_top_left_outer_texture_normal

# @export (Texture) var top_right_outer_texture setget _set_top_right_outer_texture
var _top_right_outer_texture 
@export var top_right_outer_texture : Texture:
	get: return _top_right_outer_texture
	set(v): _set_top_right_outer_texture

# @export (Texture) var top_right_outer_texture_normal setget _set_top_right_outer_texture_normal
var _top_right_outer_texture_normal 
@export var top_right_outer_texture_normal :Texture:
	get: return _top_right_outer_texture_normal
	set(v): _set_top_right_outer_texture_normal

# @export (Texture) var bottom_right_outer_texture setget _set_bottom_right_outer_texture
var _bottom_right_outer_texture 
@export var bottom_right_outer_texture : Texture:
	get: return _bottom_right_outer_texture
	set(v): _set_bottom_right_outer_texture

# @export (Texture) var bottom_right_outer_texture_normal setget _set_bottom_right_outer_texture_normal
var _bottom_right_outer_texture_normal 
@export var bottom_right_outer_texture_normal : Texture:
	get: return _bottom_right_outer_texture_normal
	set(v):_set_bottom_right_outer_texture_normal

# @export (Texture) var bottom_left_outer_texture setget _set_bottom_left_outer_texture
var _bottom_left_outer_texture 
@export var bottom_left_outer_texture : Texture:
	get: return _bottom_left_outer_texture
	set(v): _set_bottom_left_outer_texture

# @export (Texture) var bottom_left_outer_texture_normal setget _set_bottom_left_outer_texture_normal
var _bottom_left_outer_texture_normal
@export var bottom_left_outer_texture_normal : Texture:
	get: return _bottom_left_outer_texture_normal
	set(v): _set_bottom_left_outer_texture_normal

# @export (bool) var weld_edges = false setget _set_weld_edges
var _weld_edges = false 
@export var weld_edges : bool:
	get: return _weld_edges
	set(v): _set_weld_edges

# @export (float, -1.0, 1.0) var render_offset = 0.0 setget _set_render_offset
var _render_offset = 0.0 
@export var render_offset : float:
	get: return _render_offset 
	set(v): _set_render_offset

#"""
#The multiplier applied to the width of the quads
#"""

# @export (float, 0, 1.5) var collision_width = 1.0 setget _set_collision_width
var _collision_width = 1.0 
@export var collision_width : float:
	get: return _collision_width 
	set(v): _set_collision_width

#"""
#The offset applied to the position of the quads
#"""

# @export (float, -1.5, 1.5) var collision_offset = 0.0 setget _set_collision_offset
var _collision_offset = 0.0 
@export var collision_offset : float:
	get: return _collision_offset
	set(v): _set_collision_offset

#"""
#The amount the first and final quads extend past the texture (Does not apply to closed shapes)
#"""

# @export (float, -1.0, 1.0) var collision_extends = 0.0 setget _set_collision_extends
var _collision_extends = 0.0 
@export var collision_extends : float:
	get: return _collision_extends 
	set(v): _set_collision_extends


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
