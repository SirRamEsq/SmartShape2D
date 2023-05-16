extends SS2D_Action

## ActionCutEdge

var _shape: SS2D_Shape_Base
var _idx: int
var _closing_key: int


func _init(shape: SS2D_Shape_Base, key: int) -> void:
	_shape = shape
	_idx = shape.get_point_index(key)


func get_name() -> String:
	return "Cut Edge"


func do() -> void:
	_shape.begin_update()
	var last_idx: int = _shape.get_point_count() - 1
	_closing_key = _shape.get_point_key_at_index(last_idx)
	_shape.cut_edge(_idx)
	_shape.end_update()


func undo() -> void:
	_shape.begin_update()
	_shape.undo_cut_edge(_idx, _closing_key)
	_shape.end_update()

