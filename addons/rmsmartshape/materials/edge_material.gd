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
export (Array, Texture) var textures_corner_outer: Array = [] setget _set_textures_corner_outer
export (Array, Texture) var textures_corner_inner: Array = [] setget _set_textures_corner_inner
export (Array, Texture) var texture_normals_corner_outer: Array = [] setget _set_texture_normals_corner_outer
export (Array, Texture) var texture_normals_corner_inner: Array = [] setget _set_texture_normals_corner_inner

# Textures for the final left and right quad of the edge when the angle is shallow
# Named as such because the desired look is that the texture "tapers-off"
export (Array) var textures_taper_left: Array = [] setget _set_textures_taper_left
export (Array) var textures_taper_right: Array = [] setget _set_textures_taper_right
export (Array) var texture_normals_taper_left: Array = [] setget _set_texture_normals_taper_left
export (Array) var texture_normals_taper_right: Array = [] setget _set_texture_normals_taper_right

# If each quad WITHIN the edge should be welded to each other
export (bool) var weld_quads: bool = true setget _set_weld_quads
# If corner textures should be used
export (bool) var use_corner_texture: bool = true setget _set_use_corner
# If taper textures should be used
export (bool) var use_taper_texture: bool = true setget _set_use_taper
# Angle steepness at which to start using corner textures
export (float) var corner_angle: float = 90.0 setget _set_corner_angle


###########
# Setters #
###########
func _set_textures(ta: Array):
	textures = ta
	emit_signal("changed")


func _set_texture_normals(ta: Array):
	texture_normals = ta
	emit_signal("changed")


func _set_textures_corner_outer(a: Array):
	textures_corner_outer = a
	emit_signal("changed")


func _set_texture_normals_corner_outer(a: Array):
	texture_normals_corner_outer = a
	emit_signal("changed")


func _set_textures_corner_inner(a: Array):
	textures_corner_inner = a
	emit_signal("changed")


func _set_texture_normals_corner_inner(a: Array):
	texture_normals_corner_inner = a
	emit_signal("changed")


func _set_textures_taper_left(a: Array):
	textures_taper_left = a
	emit_signal("changed")


func _set_texture_normals_taper_left(a: Array):
	texture_normals_taper_left = a
	emit_signal("changed")


func _set_textures_taper_right(a: Array):
	textures_taper_right = a
	emit_signal("changed")


func _set_texture_normals_taper_right(a: Array):
	texture_normals_taper_right = a
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


func _set_corner_angle(v: float):
	corner_angle = v
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
