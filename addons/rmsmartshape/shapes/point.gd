tool
extends Reference
class_name RMSS2D_Point

var position: Vector2 = Vector2(0, 0) setget _set_position
var point_in: Vector2 = Vector2(0, 0) setget _set_point_in
var point_out: Vector2 = Vector2(0, 0) setget _set_point_out
var properties: RMS2D_VertexProperties = RMS2D_VertexProperties.new() setget _set_properties

# If class members are written to, the signal may not be emitted
# Signal is only emitted when data is actually changed
# If assigned data is the same as the existing data, no signal is emitted
signal changed(this)

func _init(pos: Vector2 = Vector2(0, 0)):
	position = pos


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


func _set_properties(p: RMS2D_VertexProperties):
	if not properties.equals(p):
		properties = p.duplicate()
		emit_signal("changed", self)
