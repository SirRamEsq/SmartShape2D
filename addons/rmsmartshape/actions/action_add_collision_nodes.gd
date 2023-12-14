extends SS2D_Action

## ActionAddCollisionNodes

var _shape: SS2D_Shape

var _saved_index: int
var _saved_pos: Vector2


func _init(shape: SS2D_Shape) -> void:
	_shape = shape


func get_name() -> String:
	return "Add Collision Nodes"


func do() -> void:
	_saved_index = _shape.get_index()
	_saved_pos = _shape.position

	var owner := _shape.owner
	var static_body := StaticBody2D.new()
	static_body.position = _shape.position
	_shape.position = Vector2.ZERO

	_shape.get_parent().add_child(static_body, true)
	static_body.owner = owner

	_shape.get_parent().remove_child(_shape)
	static_body.add_child(_shape, true)
	_shape.owner = owner

	var poly: CollisionPolygon2D = CollisionPolygon2D.new()
	static_body.add_child(poly, true)
	poly.owner = owner
	# TODO: Make this a option at some point
	poly.modulate.a = 0.3
	poly.visible = false
	_shape.collision_polygon_node_path = _shape.get_path_to(poly)


func undo() -> void:
	var owner := _shape.owner
	var parent := _shape.get_parent()
	var grandparent := _shape.get_parent().get_parent()
	parent.remove_child(_shape)
	grandparent.remove_child(parent)
	parent.free()

	grandparent.add_child(_shape)
	_shape.owner = owner
	grandparent.move_child(_shape, _saved_index)
	_shape.position = _saved_pos

