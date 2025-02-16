extends SS2D_Action
class_name SS2D_ActionOpenShape

var _shape: SS2D_Shape
var _cut_idx: int
var _closing_key: int


func _init(shape: SS2D_Shape, edge_start_key: int) -> void:
	_shape = shape
	_cut_idx = shape.get_point_array().get_point_index(edge_start_key)


func get_name() -> String:
	return "Open Shape"


func do() -> void:
	var pa := _shape.get_point_array()
	var last_idx: int = pa.get_point_count() - 1
	_closing_key = pa.get_point_key_at_index(last_idx)
	pa.begin_update()
	pa.open_shape_at_edge(_cut_idx)
	pa.end_update()


func undo() -> void:
	var pa := _shape.get_point_array()
	pa.begin_update()
	pa.undo_open_shape_at_edge(_cut_idx, _closing_key)
	pa.end_update()

