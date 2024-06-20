@tool
extends Resource
class_name SS2D_Material_Edge

## This material represents the set of textures used for a single edge.
##
## This consists of: [br]
## - textures [br]
## - corner_textures [br]
## - taper_textures [br]

## All variations of the main edge texture.[br]
## _textures[0] is considered the "main" texture for the EdgeMaterial.[br][br]
## [b]Note:[/b] Will be used to generate an icon representing an edge texture.[br]
@export var textures: Array[Texture2D] = [] : set = _set_textures

# Textures for the final left and right quad of the edge when the angle is steep
@export var textures_corner_outer: Array[Texture2D] = [] : set = _set_textures_corner_outer
@export var textures_corner_inner: Array[Texture2D] = [] : set = _set_textures_corner_inner

# Textures for the final left and right quad of the edge when the angle is shallow
# Named as such because the desired look is that the texture "tapers-off"
@export var textures_taper_left: Array[Texture2D] = [] : set = _set_textures_taper_left
@export var textures_taper_right: Array[Texture2D] = [] : set = _set_textures_taper_right

## Textures that will be used for the sharp_corner_tapering feature
@export var textures_taper_corner_left: Array[Texture2D] = [] : set = _set_textures_taper_corner_left
@export var textures_taper_corner_right: Array[Texture2D] = [] : set = _set_textures_taper_corner_right

## If the texture choice should be randomized instead of the choice by point setup
@export var randomize_texture: bool = false : set = _set_randomize_texture
## If corner textures should be used
@export var use_corner_texture: bool = true : set = _set_use_corner
## If taper textures should be used
@export var use_taper_texture: bool = true : set = _set_use_taper

## Whether squishing can occur when texture doesn't fit nicely into total length.
enum FITMODE {SQUISH_AND_STRETCH, CROP}
@export var fit_mode: FITMODE = FITMODE.SQUISH_AND_STRETCH : set = _set_fit_texture

@export var material: Material = null : set = _set_material


###########
# SETTERS #
###########
func _set_textures(ta: Array[Texture2D]) -> void:
	textures = ta
	emit_changed()


func _set_textures_corner_outer(a: Array[Texture2D]) -> void:
	textures_corner_outer = a
	emit_changed()


func _set_textures_corner_inner(a: Array[Texture2D]) -> void:
	textures_corner_inner = a
	emit_changed()


func _set_textures_taper_left(a: Array[Texture2D]) -> void:
	textures_taper_left = a
	emit_changed()


func _set_textures_taper_right(a: Array[Texture2D]) -> void:
	textures_taper_right = a
	emit_changed()

func _set_textures_taper_corner_left(a: Array[Texture2D]) -> void:
	textures_taper_corner_left = a
	emit_changed()

func _set_textures_taper_corner_right(a: Array[Texture2D]) -> void:
	textures_taper_corner_right = a
	emit_changed()

func _set_randomize_texture(b: bool) -> void:
	randomize_texture = b
	emit_changed()


func _set_use_corner(b: bool) -> void:
	use_corner_texture = b
	emit_changed()


func _set_use_taper(b: bool) -> void:
	use_taper_texture = b
	emit_changed()


func _set_fit_texture(fitmode: FITMODE) -> void:
	fit_mode = fitmode
	emit_changed()


func _set_material(m: Material) -> void:
	material = m
	emit_changed()


###########
# GETTERS #
###########
func get_texture(idx: int) -> Texture2D:
	return _get_element(idx, textures)


func get_texture_corner_inner(idx: int) -> Texture2D:
	return _get_element(idx, textures_corner_inner)


func get_texture_corner_outer(idx: int) -> Texture2D:
	return _get_element(idx, textures_corner_outer)


func get_texture_taper_left(idx: int) -> Texture2D:
	return _get_element(idx, textures_taper_left)


func get_texture_taper_right(idx: int) -> Texture2D:
	return _get_element(idx, textures_taper_right)


func get_texture_taper_corner_left(idx: int) -> Texture2D:
	return _get_element(idx, textures_taper_corner_left)


func get_texture_taper_corner_right(idx: int) -> Texture2D:
	return _get_element(idx, textures_taper_corner_right)


#########
# USAGE #
#########

## Returns main texture used to visually identify this edge material
func get_icon_texture() -> Texture2D:
	if not textures.is_empty():
		return textures[0]
	return null


############
# INTERNAL #
############
func _get_element(idx: int, a: Array) -> Variant:
	if a.is_empty():
		return null
	return a[_adjust_idx(idx, a)]


func _adjust_idx(idx: int, a: Array) -> int:
	return idx % a.size()
