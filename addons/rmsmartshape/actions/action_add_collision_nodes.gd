extends SS2D_Action
class_name SS2D_ActionAddCollisionNodes

var _shape: SS2D_Shape
var _container: Node
var _poly: CollisionPolygon2D
var _old_polygon_path: NodePath


func _init(shape: SS2D_Shape, container: Node) -> void:
	_shape = shape
	_container = container


func get_name() -> String:
	return "Add Collision Nodes"


func do() -> void:
	_old_polygon_path = _shape.collision_polygon_node_path

	_poly = CollisionPolygon2D.new()

	if _container:
		_container.add_child(_poly, true)
	else:
		_shape.add_sibling(_poly, true)

	_poly.owner = _shape.owner
	_shape.collision_polygon_node_path = _shape.get_path_to(_poly)


func undo() -> void:
	_shape.collision_polygon_node_path = _old_polygon_path

	if is_instance_valid(_poly):
		_poly.queue_free()
		_poly = null
