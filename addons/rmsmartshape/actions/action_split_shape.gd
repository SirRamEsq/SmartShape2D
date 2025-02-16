extends SS2D_Action
class_name SS2D_ActionSplitShape

## How it's done:
## 1. First, the shape is copied and added to the scene tree.
## 2. Then, points of the splitted shape are deleted from first point to split point.
## 3. Finally, points of the original shape are deleted from the point after split point to last point.

var _delete_points_from_original: SS2D_ActionDeletePoints

var _shape: SS2D_Shape
var _splitted: SS2D_Shape
var _splitted_collision: CollisionPolygon2D
var _split_idx: int


func _init(shape: SS2D_Shape, split_point_key: int) -> void:
	var pa := shape.get_point_array()
	assert(pa.is_shape_closed() == false)
	_shape = shape
	_split_idx = pa.get_point_index(split_point_key)
	_splitted = null
	_splitted_collision = null
	_delete_points_from_original = null


func get_name() -> String:
	return "Split Shape"


func do() -> void:
	if not is_instance_valid(_splitted):
		_splitted = _shape.clone()
		var splitted_pa := _splitted.get_point_array()
		splitted_pa.begin_update()
		for i in range(0, _split_idx + 1):
			splitted_pa.remove_point_at_index(0)
		splitted_pa.end_update()
	_shape.get_parent().add_child(_splitted, true)
	_splitted.set_owner(_shape.get_tree().get_edited_scene_root())
	# Add a collision shape node if the original shape has one.
	if (not _shape.collision_polygon_node_path.is_empty() and _shape.has_node(_shape.collision_polygon_node_path)):
		var collision_polygon_original := _shape.get_node(_shape.collision_polygon_node_path) as CollisionPolygon2D
		if not is_instance_valid(_splitted_collision):
			_splitted_collision = CollisionPolygon2D.new()
			_splitted_collision.visible = collision_polygon_original.visible
			_splitted_collision.modulate = collision_polygon_original.modulate
		collision_polygon_original.get_parent().add_child(_splitted_collision, true)
		_splitted_collision.set_owner(collision_polygon_original.get_tree().get_edited_scene_root())
		_splitted.collision_polygon_node_path = _splitted.get_path_to(_splitted_collision)

	if _delete_points_from_original == null:
		var pa := _shape.get_point_array()
		var delete_keys := PackedInt32Array()
		for i in range(pa.get_point_count() - 1, _split_idx, -1):
			delete_keys.append(pa.get_point_key_at_index(i))
		_delete_points_from_original = SS2D_ActionDeletePoints.new(_shape, delete_keys)
	_delete_points_from_original.do()


func undo() -> void:
	_splitted.set_owner(null)
	_splitted.get_parent().remove_child(_splitted)
	if is_instance_valid(_splitted_collision):
		_splitted_collision.set_owner(null)
		_splitted_collision.get_parent().remove_child(_splitted_collision)
	_delete_points_from_original.undo()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_splitted) and _splitted.get_parent() == null:
			_splitted.queue_free()
		if is_instance_valid(_splitted_collision) and _splitted_collision.get_parent() == null:
			_splitted_collision.queue_free()
