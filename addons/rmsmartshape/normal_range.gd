tool
extends Resource
class_name SS2D_NormalRange
"""
This class will determine if the normal of a vector falls within the specifed angle ranges
- if begin and end are equal, any angle is considered to be within range
- 360.0 and 0.0 degrees are considered equivilent
"""

export (int, 0, 360, 0) var begin = 0.0 setget set_begin
export (int, 0, 360, 0) var distance = 0.0 setget set_distance

# Deprecated variable
var end = 0.0 setget set_end

# This is a hack to support the custom editor, needed a property
# to exist to lock the TextureProgress to.  Makes it flow better
# in the Inspector.
export (Vector2) var edgeRendering


func set_distance(f: float):
	distance = f
	# Deprecated
	end = begin + distance
	emit_signal("changed")


func set_begin(f: float):
	begin = f
	# Deprecated
	end = begin + distance
	emit_signal("changed")


func set_end(f: float):
	end = f
	# COMPATIBILITY FIX:
	# This class used to use "begin" and "end" variables to define the range
	# Now uses Begin + Distance and end is used for the widget
	# The following line of code maintains compatiblity with older versions of SS2D (2.2 Backward)
	# TODO This function
	distance = end - begin
	emit_signal("changed")


func _to_string() -> String:
	return "NormalRange: %s - %s" % [begin, end]


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

static func _get_signed_angle_deg(degrees: float) -> float:
	"""
	Get in range between -360.0 and 360.0
	"""
	var new_degrees = degrees
	while abs(new_degrees) > 360:
		new_degrees += (360 * sign(degrees) * -1)
	return new_degrees


# Saving a scene with this resource requires a parameter-less init method
func _init(_begin: float = 0.0, _distance: float = 0.0):
	_begin = _get_signed_angle_deg(_begin)
	_distance = _get_signed_angle_deg(_distance)

	begin = _begin
	distance = _distance
	end = begin + distance


func is_in_range(vec: Vector2) -> bool:
	# A Distance of 0 or 360 is the entire circle
	if distance == 0 or _get_positive_angle_deg(distance) == 360:
		return true

	var begin_positive = _get_positive_angle_deg(begin)
	var end_positive = _get_positive_angle_deg(begin + distance)
	# If positive, counter clockwise direction
	# If negative, clockwise direction
	var direction = sign(distance)
	var angle = get_angle_from_vector(vec)

	# Swap begin and end if direction is negative
	if direction == -1:
		var t = begin_positive
		begin_positive = end_positive
		end_positive = t

	if begin_positive < end_positive:
		return ((angle >= begin_positive) and (angle <= end_positive))
	else:
		return ((angle >= begin_positive) or (angle <= end_positive))
