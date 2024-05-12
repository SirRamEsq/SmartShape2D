extends SS2D_Action

## ActionCutEdge
##
## A delegate action that selects an action to perform based on the edge
## location and shape state.

var ActionOpenShape := preload("res://addons/rmsmartshape/actions/action_open_shape.gd")
var ActionDeletePoint := preload("res://addons/rmsmartshape/actions/action_delete_point.gd")
var ActionSplitShape := preload("res://addons/rmsmartshape/actions/action_split_shape.gd")

var _shape: SS2D_Shape
var _action: SS2D_Action


func _init(shape: SS2D_Shape, key_edge_start: int, key_edge_end: int) -> void:
	_shape = shape

	var key_first: int = shape.get_point_key_at_index(0)
	var key_last: int = shape.get_point_key_at_index(shape.get_point_count()-1)
	if _shape.is_shape_closed():
		_action = ActionOpenShape.new(shape, key_edge_start)
	elif key_edge_start == key_first:
		_action = ActionDeletePoint.new(shape, key_edge_start)
	elif  key_edge_end == key_last:
		_action = ActionDeletePoint.new(shape, key_edge_end)
	else:
		_action = ActionSplitShape.new(shape, key_edge_start)


func get_name() -> String:
	return _action.get_name()


func do() -> void:
	_action.do()


func undo() -> void:
	_action.undo()

