tool
extends Resource
class_name RMSS2D_NormalRange
"""
This class will determine if the normal of a vector falls within the specifed angle ranges
- if begin and end are equal, any angle is considered to be within range
- 360.0 and 0.0 degrees are considered equivilent
"""

export (float, 0, 360, 5) var begin = 0
export (float, 0, 360, 5) var end = 0

static func get_angle_from_vector(vec: Vector2) -> float:
	var normal = vec.normalized()
	# With respect to the X-axis
	# This is how Vector2.angle() is calculated, best to keep it consistent
	var comparison_vector = Vector2(1, 0)

	var ab = normal
	var bc = comparison_vector
	var dot_prod = ab.dot(bc)
	var determinant = (ab.x * bc.y) - (ab.y * bc.x)
	var angle = atan2(determinant, dot_prod)

	# This angle has a range of 360 degrees
	# Is between 180 and - 180
	var deg = rad2deg(angle)

	# Get range between 0.0 and 360.0
	if deg < 0:
		deg = 360.0 + deg
	return deg

static func _get_positive_angle_deg(degrees: float) -> float:
	"""
	Get in range between 0.0 and 360.0
	"""
	while degrees < 0:
		degrees += 360
	return fmod(degrees, 360.0)


func _init(_begin: float, _end: float):
	_begin = _get_positive_angle_deg(_begin)
	_end = _get_positive_angle_deg(_end)

	# make _begin negative if greater than _end
	if _begin > _end:
		_begin -= 360.0

	begin = _begin
	end = _end


func is_in_range(vec: Vector2) -> bool:
	# If these are equal, the entire circle is within range
	if end == begin:
		return true

	var angle = get_angle_from_vector(vec)
	if sign(begin) != sign(end):
		return (angle >= (begin + 360.0)) or (angle <= end)
	return (angle >= begin) and (angle <= end)
