@tool
extends Resource
class_name SS2D_Point

@export var position: Vector2 : set = _set_position
@export var point_in: Vector2 : set = _set_point_in
@export var point_out: Vector2 : set = _set_point_out
@export var texture_idx: int = 0 : set = set_texture_idx
@export var flip: bool = false : set = set_flip
@export var width: float = 1.0 : set = set_width

## Deprecated. Exists only for backwards compatibility (scene loading).
## Will always be null when accessed!
## @deprecated
@export_storage var properties: SS2D_VertexProperties : set = _set_properties, get = _get_properties

# If class members are written to, the 'changed' signal may not be emitted
# Signal is only emitted when data is actually changed
# If assigned data is the same as the existing data, no signal is emitted


func _init(pos: Vector2 = Vector2.ZERO) -> void:
	position = pos


func equals(other: SS2D_Point) -> bool:
	return other and \
		position == other.position and \
		point_in == other.point_in and \
		point_out == other.point_out and \
		texture_idx == other.texture_idx and \
		flip == other.flip and \
		width == other.width


func _set_position(v: Vector2) -> void:
	if position != v:
		position = v
		emit_changed()


func _set_point_in(v: Vector2) -> void:
	if point_in != v:
		point_in = v
		emit_changed()


func _set_point_out(v: Vector2) -> void:
	if point_out != v:
		point_out = v
		emit_changed()


func _set_properties(other: SS2D_VertexProperties) -> void:
	if not other:  # Happens when duplicate()ing an SS2D_Point
		return

	if texture_idx != other.texture_idx or flip != other.flip or width != other.width:
		# This generates warnings upon scene load but it's unavoidable
		SS2D_PluginFunctionality.show_deprecation_warning("SS2D_VertexProperties", "SS2D_Point members", "A scene re-save likely fixes this warning.")

	# Copy values to members but leave `properties` null to update scene files.
	texture_idx = other.texture_idx
	flip = other.flip
	width = other.width


func _get_properties() -> SS2D_VertexProperties:
	# This will break existing user code (if any), but it's the only effective way to prevent saving and ID changing.
	return null


func set_texture_idx(i: int) -> void:
	if texture_idx != i:
		texture_idx = i
		emit_changed()


func set_flip(b: bool) -> void:
	if flip != b:
		flip = b
		emit_changed()


func set_width(w: float) -> void:
	if width != w:
		width = w
		emit_changed()


func _to_string() -> String:
	return "<SS2D_Point %s>" % [position]
