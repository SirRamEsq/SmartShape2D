tool
extends Reference
class_name RMSS2D_Edge

var quads: Array = []
var z_index: int = 0


static func different_render(q2, q2: QuadInfo) -> bool:
	"""
	Will return true if the 2 quads must be drawn in two calls
	"""
	if (
		q1.texture != q2.texture
		or q1.flip_texture != q2.flip_texture
		or q1.normal_texture != q2.normal_texture
	):
		return true
	return false


func get_meshes() -> Array:
	"""
	Will return all of the meshes required to render this edge
	"""
	var meshes: Array = []
	if quads.empty():
		return meshes

	var first_quad = quads[0]
	var new_mesh = RMSS2D_Mesh.new()
	new_mesh.texture = first_quad.texture
	new_mesh.texture_normal = first_quad.texture_normal
	new_mesh.flip_texture = first_quad.flip_texture
	new_mesh.meshes.push_back(first_quad)
	for q in range(1, quads.size(), 1):
		if different_render(new_mesh.meshes[new_mesh.meshes.size() - 1], q):
			meshes.push_back(new_mesh)
			var new_mesh = RMSS2D_Mesh.new()
			new_mesh.texture = q.texture
			new_mesh.texture_normal = q.texture_normal
			new_mesh.flip_texture = q.flip_texture
			new_mesh.meshes.push_back(q)
		else:
			new_mesh.meshes.push_back(q)

	meshes.push_back(new_mesh)
	return meshes
