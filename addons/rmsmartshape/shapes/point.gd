@tool
extends Resource
class_name SS2D_Point

@export var position: Vector2 : set = _set_position
@export var point_in: Vector2 : set = _set_point_in
@export var point_out: Vector2 : set = _set_point_out
@export var properties: SS2D_VertexProperties : set = _set_properties

# If class members are written to, the 'changed' signal may not be emitted
# Signal is only emitted when data is actually changed
# If assigned data is the same as the existing data, no signal is emitted


func _init(pos: Vector2 = Vector2(0, 0)) -> void:
	position = pos
	point_in = Vector2(0, 0)
	point_out = Vector2(0, 0)
	properties = SS2D_VertexProperties.new()


func equals(other: SS2D_Point) -> bool:
	if position != other.position:
		return false
	if point_in != other.point_in:
		return false
	if point_out != other.point_out:
		return false
	print ("E! %s" % properties.equals(other.properties))
	if not properties.equals(other.properties):
		return false
	return true


func _set_position(v: Vector2) -> void:
	if position != v:
		position = v
		emit_changed()
	notify_property_list_changed()


func _set_point_in(v: Vector2) -> void:
	if point_in != v:
		point_in = v
		emit_changed()
	notify_property_list_changed()


func _set_point_out(v: Vector2) -> void:
	if point_out != v:
		point_out = v
		emit_changed()
	notify_property_list_changed()


func _set_properties(other: SS2D_VertexProperties) -> void:
	if properties == null or not properties.equals(other):
		properties = other.duplicate(true)
		emit_changed()
		notify_property_list_changed()


func _to_string() -> String:
	return "<SS2D_Point %s>" % [position]
