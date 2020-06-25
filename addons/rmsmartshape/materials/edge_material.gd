tool
extends Resource
class_name RMSS2D_Material_Edge

"""
This material represents the set of textures used for a single edge
This consists of:
- textures
- corner_textures
- taper_textures
- normals for each texture
"""
# All variations of the main edge texture
# _textures[0] is considered the "main" texture for the EdgeMaterial
#### Will be used to generate an icon representing an edge texture
export (Array, Texture) var textures: Array = [] setget _set_textures
export (Array, Texture) var texture_normals: Array = [] setget _set_texture_normals

# Textures for the final left and right quad of the edge when the angle is steep
export (Texture) var texture_corner_left: Texture = null setget _set_texture_corner_left
export (Texture) var texture_normal_corner_left: Texture = null setget _set_texture_normal_corner_left
export (Texture) var texture_corner_right: Texture = null setget _set_texture_corner_right
export (Texture) var texture_normal_corner_right: Texture = null setget _set_texture_normal_corner_right

# Textures for the final left and right quad of the edge when the angle is shallow
# Named as such because the desired look is that the texture "tapers-off"
export (Texture) var texture_taper_left: Texture = null setget _set_texture_taper_left
export (Texture) var texture_normal_taper_left: Texture = null setget _set_texture_normal_taper_left
export (Texture) var texture_taper_right: Texture = null setget _set_texture_taper_right
export (Texture) var texture_normal_taper_right: Texture = null setget _set_texture_normal_taper_right

# If each quad WITHIN the edge should be welded to each other
export (bool) var weld_quads: bool = true setget _set_weld_quads
# If corner textures should be used
export (bool) var use_corner_texture: bool = true setget _set_use_corner
# If taper textures should be used
export (bool) var use_taper_texture: bool = true setget _set_use_taper

# max angle to use taper textures until. After this angle corners are used
export (float) var taper_angle_max: float = 90.0 setget _set_taper_angle


###########
# Setters #
###########
func _set_textures(ta: Array):
	textures = ta
	emit_signal("changed")


func _set_texture_normals(ta: Array):
	texture_normals = ta
	emit_signal("changed")


func _set_texture_corner_left(t: Texture):
	texture_corner_left = t
	emit_signal("changed")


func _set_texture_normal_corner_left(t: Texture):
	texture_normal_corner_left = t
	emit_signal("changed")


func _set_texture_corner_right(t: Texture):
	texture_corner_right = t
	emit_signal("changed")


func _set_texture_normal_corner_right(t: Texture):
	texture_normal_corner_right = t
	emit_signal("changed")


func _set_texture_taper_left(t: Texture):
	texture_taper_left = t
	emit_signal("changed")


func _set_texture_normal_taper_left(t: Texture):
	texture_normal_taper_left = t
	emit_signal("changed")


func _set_texture_taper_right(t: Texture):
	texture_taper_right = t
	emit_signal("changed")


func _set_texture_normal_taper_right(t: Texture):
	texture_normal_taper_right = t
	emit_signal("changed")


func _set_weld_quads(b: bool):
	weld_quads = b
	emit_signal("changed")


func _set_use_corner(b: bool):
	use_corner_texture = b
	emit_signal("changed")


func _set_use_taper(b: bool):
	use_taper_texture = b
	emit_signal("changed")


func _set_taper_angle(v: float):
	taper_angle_max = v
	emit_signal("changed")


#########
# Usage #
#########
func get_icon_texture() -> Texture:
	"""
	Returns main texture used to visually identify this edge material
	"""
	if not textures.empty():
		return textures[0]
	return null
