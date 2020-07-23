tool
extends Resource
class_name RMSS2D_Point

export (Vector2) var position: Vector2 = Vector2(0, 0) setget _set_position
export (Vector2) var point_in: Vector2 = Vector2(0, 0) setget _set_point_in
export (Vector2) var point_out: Vector2 = Vector2(0, 0) setget _set_point_out
export (Resource) var properties = RMS2D_VertexProperties.new() setget _set_properties

# If class members are written to, the 'changed' signal may not be emitted
# Signal is only emitted when data is actually changed
# If assigned data is the same as the existing data, no signal is emitted


func _init(pos: Vector2 = Vector2(0, 0)):
	position = pos
	point_in = Vector2(0, 0)
	point_out = Vector2(0, 0)
	properties = RMS2D_VertexProperties.new()


func equals(other: RMSS2D_Point) -> bool:
	if position != other.position:
		return false
	if point_in != other.point_in:
		return false
	if point_out != other.point_out:
		return false
	if not properties.equals(other.properties):
		return false
	return true


func duplicate(sub_resource: bool = true):
	var _new = __new()
	_new.position = position
	_new.point_in = point_in
	_new.point_out = point_out
	if sub_resource:
		_new.properties = properties.duplicate()
	else:
		_new.properties = properties
	return _new


func _set_position(v: Vector2):
	if position != v:
		position = v
		emit_signal("changed", self)


func _set_point_in(v: Vector2):
	if point_in != v:
		point_in = v
		emit_signal("changed", self)


func _set_point_out(v: Vector2):
	if point_out != v:
		point_out = v
		emit_signal("changed", self)


func _set_properties(other: RMS2D_VertexProperties):
	if not properties.equals(other):
		properties = other.duplicate()
		emit_signal("changed", self)


# Workaround (class cannot reference itself)
func __new() -> RMSS2D_Point:
	return get_script().new()
