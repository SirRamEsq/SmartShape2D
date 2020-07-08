tool
extends Node
class_name RMSS2D_Common_Functions

static func sort_z(a, b) -> bool:
	if a.z_index < b.z_index:
		return true
	return false

static func to_vector3(vector: Vector2):
	return Vector3(vector.x, vector.y, 0)
