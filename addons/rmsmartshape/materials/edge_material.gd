@tool
extends Resource
class_name SS2D_Material_Edge

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
@export var textures: Array[Texture2D] = [] : set = _set_textures
@export var texture_normals: Array[Texture2D] = [] : set = _set_texture_normals

# Textures for the final left and right quad of the edge when the angle is steep
@export var textures_corner_outer: Array[Texture2D] = [] : set = _set_textures_corner_outer
@export var textures_corner_inner: Array[Texture2D] = [] : set = _set_textures_corner_inner
@export var texture_normals_corner_outer: Array[Texture2D] = [] : set = _set_texture_normals_corner_outer
@export var texture_normals_corner_inner: Array[Texture2D] = [] : set = _set_texture_normals_corner_inner

# Textures for the final left and right quad of the edge when the angle is shallow
# Named as such because the desired look is that the texture "tapers-off"
@export var textures_taper_left: Array[Texture2D] = [] : set = _set_textures_taper_left
@export var textures_taper_right: Array[Texture2D] = [] : set = _set_textures_taper_right
@export var texture_normals_taper_left: Array[Texture2D] = [] : set = _set_texture_normals_taper_left
@export var texture_normals_taper_right: Array[Texture2D] = [] : set = _set_texture_normals_taper_right

# If the texture choice should be randomized instead of the choice by point setup
@export var randomize_texture: bool = false : set = _set_randomize_texture
# If corner textures should be used
@export var use_corner_texture: bool = true : set = _set_use_corner
# If taper textures should be used
@export var use_taper_texture: bool = true : set = _set_use_taper
# if set to true, then squishing can occur when texture doesn't fit nicely into total length.
enum FITMODE {SQUISH_AND_STRETCH, CROP}
@export var fit_mode: FITMODE = FITMODE.SQUISH_AND_STRETCH : set = _set_fit_texture

@export var material: Material = null : set = _set_material


###########
# SETTERS #
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


func _set_randomize_texture(b: bool):
	randomize_texture = b
	emit_signal("changed")


func _set_use_corner(b: bool):
	use_corner_texture = b
	emit_signal("changed")


func _set_use_taper(b: bool):
	use_taper_texture = b
	emit_signal("changed")
	
func _set_fit_texture(fitmode):
	fit_mode = fitmode
	emit_signal("changed")

func _set_material(m:Material):
	material = m
	emit_signal("changed")


###########
# GETTERS #
###########
func get_texture(idx: int):
	return _get_element(idx, textures)


func get_texture_normal(idx: int):
	return _get_element(idx, texture_normals)


func get_texture_corner_inner(idx: int):
	return _get_element(idx, textures_corner_inner)


func get_texture_normal_corner_inner(idx: int):
	return _get_element(idx, texture_normals_corner_inner)


func get_texture_corner_outer(idx: int):
	return _get_element(idx, textures_corner_outer)


func get_texture_normal_corner_outer(idx: int):
	return _get_element(idx, texture_normals_corner_outer)


func get_texture_taper_left(idx: int):
	return _get_element(idx, textures_taper_left)


func get_texture_normal_taper_left(idx: int):
	return _get_element(idx, texture_normals_taper_left)


func get_texture_taper_right(idx: int):
	return _get_element(idx, textures_taper_right)


func get_texture_normal_taper_right(idx: int):
	return _get_element(idx, texture_normals_taper_right)


#########
# USAGE #
#########
func get_icon_texture() -> Texture2D:
	"""
	Returns main texture used to visually identify this edge material
	"""
	if not textures.is_empty():
		return textures[0]
	return null


############
# INTERNAL #
############
func _get_element(idx: int, a: Array):
	if a.is_empty():
		return null
	return a[_adjust_idx(idx, a)]


func _adjust_idx(idx: int, a: Array) -> int:
	return idx % a.size()
