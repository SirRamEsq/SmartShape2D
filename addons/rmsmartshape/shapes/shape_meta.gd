tool
extends SS2D_Shape_Base
class_name SS2D_Shape_Meta, "../assets/meta_shape.png"

"""
This shape will set the point_array data of all children shapes
"""


#############
# OVERRIDES #
#############
func _init():
	._init()
	_is_instantiable = true

func _ready():
	for s in _get_shapes():
		_add_to_meta(s)
	._ready()

func _draw():
	pass


func add_child(node: Node, legible_unique_name: bool = false):
	_add_to_meta(node)
	.add_child(node, legible_unique_name)


func _on_dirty_update():
	pass

func set_as_dirty():
	_update_shapes()


########
# META #
########
func _get_shapes() -> Array:
	var shapes = []
	for c in get_children():
		if c is SS2D_Shape_Base:
			shapes.push_back(c)
	return shapes


func _add_to_meta(n: Node):
	if not n is SS2D_Shape_Base:
		return
	# Assign node to have the same point array data as this meta shape
	n.set_point_array(_points, false)
	n.connect("points_modified", self, "_update_shapes", [[n]])

func _update_shapes(except:Array=[]):
	for s in _get_shapes():
		if not except.has(s):
			s.set_as_dirty()
			s._update_curve(s.get_point_array())
	_update_curve(_points)


func _remove_from_meta(n: Node):
	if not n is SS2D_Shape_Base:
		return
	# Make Point Data Unique
	n.set_point_array(n.get_point_array(), true)
	n.disconnect("points_modified", self, "_update_shapes")
