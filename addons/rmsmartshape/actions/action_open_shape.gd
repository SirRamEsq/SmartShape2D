extends SS2D_Action

## ActionOpenShape

var _shape: SS2D_Shape
var _cut_idx: int
var _closing_key: int


func _init(shape: SS2D_Shape, edge_start_key: int) -> void:
	_shape = shape
	_cut_idx = shape.get_point_index(edge_start_key)


func get_name() -> String:
	return "Open Shape"


func do() -> void:
	_shape.begin_update()
	var last_idx: int = _shape.get_point_count() - 1
	_closing_key = _shape.get_point_key_at_index(last_idx)
	_shape.open_shape_at_edge(_cut_idx)
	_shape.end_update()


func undo() -> void:
	_shape.begin_update()
	_shape.undo_open_shape_at_edge(_cut_idx, _closing_key)
	_shape.end_update()

