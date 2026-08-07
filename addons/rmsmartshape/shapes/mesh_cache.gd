@tool
extends Resource
class_name SS2D_MeshCache

## This class is essentially a wrapper around Array[SS2D_Mesh] with an owner attribute to prevent
## multiple shapes sharing the same SS2D_Mesh objects after duplicate()ing.
## See #208 for more info.

@export var meshes: Array[SS2D_Mesh] = []

var _owner: SS2D_Shape


func _init(owner: SS2D_Shape = null) -> void:
	_owner = owner


## Checks whether the given shape can take ownership of this cache.
## If the cache is already in use by another shape, a copy will be returned.
func claim_ownership_or_copy(shape: SS2D_Shape) -> SS2D_MeshCache:
	if _owner == null:
		_owner = shape
		return self

	if _owner == shape:
		return self

	var new_cache := SS2D_MeshCache.new(shape)
	new_cache.meshes.resize(meshes.size())

	for i in meshes.size():
		new_cache.meshes[i] = meshes[i].clone()

	return new_cache


## Returns a cleared mesh object at the given index.
## If the index is out of bounds, creates and appends a new object.
## Enables easy reusing of SS2D_Mesh objects to prevent VCS noise due to changing resource IDs.
func mesh_buffer_get_or_create(idx: int) -> SS2D_Mesh:
	var mesh: SS2D_Mesh

	if idx < meshes.size():
		mesh = meshes[idx]
		mesh.clear()  # Absolutely ensure working on a clean object
	else:
		assert(idx == meshes.size(), "Index too far out of bounds")
		mesh = SS2D_Mesh.new()
		meshes.push_back(mesh)

	return mesh
