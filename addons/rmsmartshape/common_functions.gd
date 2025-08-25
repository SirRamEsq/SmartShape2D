@tool
extends Node
class_name SS2D_Common_Functions


static func sort_z(a, b) -> bool:
	if a.z_index < b.z_index:
		return true
	return false


static func sort_int_ascending(a: int, b: int) -> bool:
	if a < b:
		return true
	return false


static func sort_int_descending(a: int, b: int) -> bool:
	if a < b:
		return false
	return true


static func to_vector3(vector: Vector2) -> Vector3:
	return Vector3(vector.x, vector.y, 0)


static func merge_arrays(arrays: Array) -> Array:
	var new_array := []
	for array: Array in arrays:
		for v: Variant in array:
			new_array.push_back(v)
	return new_array


## Returns a cleared mesh object in the given buffer at the given index.
## If the index is out of bounds, creates and appends a new object.
## Used for caching and reusing SS2D_Mesh objects to prevent changing resource IDs even if there was
## no change which in turn causes VCS noise.
static func mesh_buffer_get_or_create(mesh_buffer: Array[SS2D_Mesh], idx: int) -> SS2D_Mesh:
	var mesh: SS2D_Mesh

	if idx < mesh_buffer.size():
		mesh = mesh_buffer[idx]
		mesh.clear()  # Absolutely ensure working on a clean object
	else:
		mesh = SS2D_Mesh.new()
		mesh_buffer.push_back(mesh)

	return mesh
