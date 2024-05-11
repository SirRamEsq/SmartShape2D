extends RefCounted
class_name SS2D_TesselationVertexMapping

## Provides mappings from tesselated point indices to their corresponding vertex indices and vice-versa.

var _t_point_idx_to_point_idx := PackedInt32Array()
var _point_idx_to_t_points_idx: Array[PackedInt32Array] = []


## Rebuild the mapping using the given tesselated points and vertices.
func build(tesselated_points: PackedVector2Array, vertices: PackedVector2Array) -> void:
	_t_point_idx_to_point_idx.clear()
	_point_idx_to_t_points_idx.clear()

	var point_idx := -1

	for t_point_idx in tesselated_points.size():
		var next_point_idx := SS2D_PluginFunctionality.get_next_point_index_wrap_around(point_idx, vertices)

		if tesselated_points[t_point_idx] == vertices[next_point_idx]:
			point_idx = next_point_idx
			_point_idx_to_t_points_idx.push_back(PackedInt32Array())

		_t_point_idx_to_point_idx.push_back(point_idx)
		_point_idx_to_t_points_idx[point_idx].push_back(t_point_idx)


## Returns the vertex index corresponding to the given tesselated point index
func tess_to_vertex_index(tesselated_idx: int) -> int:
	return _t_point_idx_to_point_idx[tesselated_idx]


## Returns a list of tesselated point indices corresponding to the given vertex index
func vertex_to_tess_indices(vertex_idx: int) -> PackedInt32Array:
	return _point_idx_to_t_points_idx[vertex_idx]
