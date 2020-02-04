tool
extends Resource
class_name RMSmartShapeMaterial

export (Texture) var fill_texture = null setget _set_fill_texture
export (Texture) var fill_texture_normal = null setget _set_fill_texture_normal

export (float, 0, 180.0) var top_texture_tilt = 20.0 setget _set_top_texture_tilt
export (float, 0, 180.0) var bottom_texture_tilt = 20.0 setget _set_bottom_texture_tilt

export (Array, Texture) var top_texture setget _set_top_texture
export (Array, Texture) var top_texture_normal setget _set_top_texture_normal

export (Array, Texture) var left_texture setget _set_left_texture
export (Array, Texture) var left_texture_normal setget _set_left_texture_normal

export (Array, Texture) var right_texture setget _set_right_texture
export (Array, Texture) var right_texture_normal setget _set_right_texture_normal

export (Array, Texture) var bottom_texture setget _set_bottom_texture
export (Array, Texture) var bottom_texture_normal setget _set_bottom_texture_normal

export (bool) var weld_edges = false setget _set_weld_edges
export (float, -1.0, 1.0) var top_offset = 0.0 setget _set_top_offset
export (float, -1.0, 1.0) var bottom_offset = 0.0 setget _set_bottom_offset
export (float, -1.0, 1.0) var right_offset = 0.0 setget _set_right_offset
export (float, -1.0, 1.0) var left_offset = 0.0 setget _set_left_offset

export (float,0, 1.5) var collision_width = 1.0 setget _set_collision_width
export (float,-1.5, 1.5) var collision_offset = 0.0 setget _set_collision_offset
export (float,-1.0, 1.0) var collision_extends = 0.0 setget _set_collision_extends


func _set_fill_texture(value):
	fill_texture = value
	emit_signal("changed")
	pass
	
func _set_fill_texture_normal(value):
	fill_texture_normal = value
	emit_signal("changed")
	pass
	
func _set_top_offset(value):
	top_offset = value
	emit_signal("changed")
	
func _set_bottom_offset(value):
	bottom_offset = value
	emit_signal("changed")
	
func _set_right_offset(value):
	right_offset = value
	emit_signal("changed")	
	
func _set_left_offset(value):
	left_offset = value
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
	
func _set_collision_width(value):
	collision_width = value
	emit_signal("changed")
	
func _set_collision_offset(value):
	collision_offset = value
	emit_signal("changed")
	
func _set_collision_extends(value):
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
