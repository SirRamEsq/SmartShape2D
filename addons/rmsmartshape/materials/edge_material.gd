@tool
extends RefCounted
class_name SS2D_Material_Edge

# """
# This material represents the set of textures used for a single edge
# This consists of:
# - textures
# - corner_textures
# - taper_textures
# - normals for each texture
# """
# All variations of the main edge texture
# _textures[0] is considered the "main" texture for the EdgeMaterial
#### Will be used to generate an icon representing an edge texture

# export (Array, Texture) var textures: Array = [] setget _set_textures
var _textures: Array[Texture] = [] 
@export var textures : Array[Texture]:
	get: return _textures
	set(v): _set_textures

# export (Array, Texture) var texture_normals: Array = [] setget _set_texture_normals
var _texture_normals: Array[Texture] = [] 
@export var texture_normals : Array[Texture]:
	get: return _texture_normals
	set(v): _set_texture_normals

# Textures for the final left and right quad of the edge when the angle is steep
# export (Array, Texture) var textures_corner_outer: Array = [] setget _set_textures_corner_outer
var _textures_corner_outer: Array = [] 
@export var textures_corner_outer : Array[Texture]:
	get: return _textures_corner_outer
	set(v): _set_textures_corner_outer

# export (Array, Texture) var textures_corner_inner: Array = [] setget _set_textures_corner_inner
var _textures_corner_inner: Array = []
@export var textures_corner_inner: Array[Texture]:
	get: return _textures_corner_inner
	set(v): _set_textures_corner_inner

# export (Array, Texture) var texture_normals_corner_outer: Array = [] setget _set_texture_normals_corner_outer
var _texture_normals_corner_outer: Array = []
@export var texture_normals_corner_outer : Array[Texture]:
	get: return _texture_normals_corner_outer
	set(v): _set_texture_normals_corner_outer

# export (Array, Texture) var texture_normals_corner_inner: Array = [] setget _set_texture_normals_corner_inner
var _texture_normals_corner_inner: Array = []
@export var texture_normals_corner_inner : Array[Texture]:
	get: return _texture_normals_corner_inner
	set(v): _set_texture_normals_corner_inner

# Textures for the final left and right quad of the edge when the angle is shallow
# Named as such because the desired look is that the texture "tapers-off"
# export (Array, Texture) var textures_taper_left: Array = [] setget _set_textures_taper_left
var _textures_taper_left: Array = []
@export var textures_taper_left : Array[Texture]:
	get: return _textures_taper_left
	set(v): _set_textures_taper_left

# export (Array, Texture) var textures_taper_right: Array = [] setget _set_textures_taper_right
var _textures_taper_right: Array = []
@export var textures_taper_right : Array[Texture]:
	get: return _textures_taper_right
	set(v): _set_textures_taper_right

# export (Array, Texture) var texture_normals_taper_left: Array = [] setget _set_texture_normals_taper_left
var _texture_normals_taper_left: Array = []
@export var texture_normals_taper_left: Array[Texture]:
	get: return _texture_normals_taper_left
	set(v): _set_texture_normals_taper_left

# export (Array, Texture) var texture_normals_taper_right: Array = [] setget _set_texture_normals_taper_right
var _texture_normals_taper_right: Array = []
@export var texture_normals_taper_right : Array[Texture]:
	get: return _texture_normals_taper_right
	set(v): _set_texture_normals_taper_right

# If the texture choice should be randomized instead of the choice by point setup
# export (bool) var randomize_texture: bool = false setget _set_randomize_texture
var _randomize_texture: bool = false
@export var randomize_texture : bool:
	get: return _randomize_texture
	set(v): _set_randomize_texture

# If corner textures should be used
# export (bool) var use_corner_texture: bool = true setget _set_use_corner
var _use_corner_texture: bool = true 
@export var use_corner_texture : bool:
	get: return _use_corner_texture
	set(v): _set_use_corner

# If taper textures should be used
# export (bool) var use_taper_texture: bool = true setget _set_use_taper
var _use_taper_texture: bool = true
@export var use_taper_texture : bool:
	get: return _use_taper_texture
	set(v): _set_use_taper

# if set to true, then squishing can occur when texture doesn't fit nicely into total length.
enum FITMODE {SQUISH_AND_STRETCH, CROP}
# export (FITMODE) var fit_mode = FITMODE.SQUISH_AND_STRETCH setget _set_fit_texture
var _fit_mode = FITMODE.SQUISH_AND_STRETCH
@export var fit_mode : FITMODE:
	get: return _fit_mode
	set(v): _set_fit_texture


# export (Material) var material: Material = null setget _set_material
var material: Material = null



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
func get_icon_texture() -> Texture:
	# """
	# Returns main texture used to visually identify this edge material
	# """
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
