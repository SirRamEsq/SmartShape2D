tool
extends SS2D_Shape_Base
class_name SS2D_Shape_Open, "../assets/open_shape.png"


#########
# GODOT #
#########
func _init():
	._init()
	_is_instantiable = true



############
# OVERRIDE #
############
func duplicate_self():
	var _new = .duplicate()
	return _new


# Workaround (class cannot reference itself)
func __new():
	return get_script().new()


func should_flip_edges() -> bool:
	return flip_edges

func import_from_legacy(legacy:RMSmartShape2D):
	# Sanity Check
	if legacy == null:
		push_error("LEGACY SHAPE IS NULL; ABORTING;")
		return
	if legacy.closed_shape:
		push_error("CLOSED LEGACY SHAPE WAS SENT TO SS2D_SHAPE_OPEN; ABORTING;")
		return

	# Properties
	editor_debug = legacy.editor_debug
	flip_edges = legacy.flip_edges
	render_edges = legacy.draw_edges
	tessellation_stages = legacy.tessellation_stages
	tessellation_tolerence = legacy.tessellation_tolerence
	curve_bake_interval = legacy.collision_bake_interval
	collision_polygon_node_path = legacy.collision_polygon_node

	# Points
	_points.clear()
	add_points(legacy.get_vertices())
	for i in range(0, legacy.get_point_count(), 1):
		var key = get_point_key_at_index(i)
		set_point_in(key, legacy.get_point_in(i))
		set_point_out(key, legacy.get_point_out(i))
		set_point_texture_index(key, legacy.get_point_texture_index(i))
		set_point_texture_flip(key, legacy.get_point_texture_flip(i))
		set_point_width(key, legacy.get_point_width(i))


