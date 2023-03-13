@tool
extends Resource
class_name SS2D_NormalRange

## This class will determine if the normal of a vector falls within the specifed angle ranges.
##
## - if begin and end are equal, any angle is considered to be within range [br]
## - 360.0 and 0.0 degrees are considered equivilent [br]

@export_range (0, 360, 1) var begin: float = 0.0 : set = set_begin
@export_range (0, 360, 1) var distance: float = 0.0 : set = set_distance

# This is a hack to support the custom editor, needed a property
# to exist to lock the TextureProgressBar to.  Makes it flow better
# in the Inspector.
@export var edgeRendering: Vector2


func set_distance(f: float) -> void:
	distance = f
	emit_changed()


func set_begin(f: float) -> void:
	begin = f
	emit_changed()


func _to_string() -> String:
	return "NormalRange: %s - %s" % [begin, begin + distance]


static func get_angle_from_vector(vec: Vector2) -> float:
	var normal: Vector2 = vec.normalized()
	# With respect to the X-axis
	# This is how Vector2.angle() is calculated, best to keep it consistent
	var comparison_vector := Vector2(1, 0)

	var ab: Vector2 = normal
	var bc: Vector2 = comparison_vector
	var dot_prod: float = ab.dot(bc)
	var determinant: float = (ab.x * bc.y) - (ab.y * bc.x)
	var angle: float = atan2(determinant, dot_prod)

	# This angle has a range of 360 degrees
	# Is between 180 and - 180
	var deg: float = rad_to_deg(angle)

	# Get range between 0.0 and 360.0
	if deg < 0:
		deg = 360.0 + deg
	return deg


# Get in range between 0.0 and 360.0.
static func _get_positive_angle_deg(degrees: float) -> float:
	while degrees < 0:
		degrees += 360
	return fmod(degrees, 360.0)

# Get in range between -360.0 and 360.0
static func _get_signed_angle_deg(degrees: float) -> float:
	var new_degrees: float = degrees
	while absf(new_degrees) > 360.0:
		new_degrees += (360.0 * signf(degrees) * -1.0)
	return new_degrees


# Saving a scene with this resource requires a parameter-less init method
func _init(_begin: float = 0.0, _distance: float = 0.0) -> void:
	_begin = _get_signed_angle_deg(_begin)
	_distance = _get_signed_angle_deg(_distance)

	begin = _begin
	distance = _distance


func is_in_range(vec: Vector2) -> bool:
	# A Distance of 0 or 360 is the entire circle
	if distance == 0 or _get_positive_angle_deg(distance) == 360.0:
		return true

	var begin_positive: float = _get_positive_angle_deg(begin)
	var end_positive: float = _get_positive_angle_deg(begin + distance)
	# If positive, counter clockwise direction
	# If negative, clockwise direction
	var direction: float = signf(distance)
	var angle: float = get_angle_from_vector(vec)

	# Swap begin and end if direction is negative
	if direction == -1:
		var t: float = begin_positive
		begin_positive = end_positive
		end_positive = t

	if begin_positive < end_positive:
		return ((angle >= begin_positive) and (angle <= end_positive))
	else:
		return ((angle >= begin_positive) or (angle <= end_positive))
