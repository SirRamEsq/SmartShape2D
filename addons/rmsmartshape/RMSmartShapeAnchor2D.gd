tool
extends Node2D

class_name RMSmartShapeAnchor2D, "shape_anchor.png"

export (NodePath) var monitored_shape setget _set_monitored_shape
export (int) var track_control_point setget _set_track_control_point
export (float) var normal_length = 10.0 setget _set_normal_length
export (float, -1.0, 1.0) var control_point_offset setget _set_control_point_offset
export (float, -3.14159, 3.14159) var rotation_offset = 0 setget _set_rotation_offset
export (bool) var copy_scale = false setget _set_copy_scale

var connected = false

var monitored_transform

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _process(delta):
	if monitored_shape != null and monitored_shape == "":
		_set_monitored_shape(null)
		return

	# Cannot connect until node is in tree
	if connected == false and monitored_shape != null:
		_set_monitored_shape(monitored_shape)
		
	# Watch for changes to attached node
	if monitored_shape != null:
		if has_node(monitored_shape):
			var n = get_node(monitored_shape)
			if n.is_queued_for_deletion()==false:
				if n.get_global_transform() != monitored_transform:
					refresh()
					monitored_transform = n.get_global_transform()
	pass

func _set_monitored_shape(value):
	if value == null and monitored_shape != null:
		get_node(monitored_shape).disconnect("points_modified", self, "_handle_point_change")
		get_node(monitored_shape).disconnect("tree_exiting", self, "_monitored_node_leaving")
		connected = false
	
	if value=="":
		value = null
	
	if value != null:
		if has_node(value):
			get_node(value).connect("points_modified", self, "_handle_point_change")
			connected = get_node(value).is_connected("points_modified", self, "_handle_point_change")
			get_node(value).connect("tree_exiting", self, "_monitored_node_leaving")
			
	monitored_shape = value
	refresh()
	pass
	
func _monitored_node_leaving():
	_set_monitored_shape(null)
	pass
	
func _set_copy_scale(value):
	copy_scale = value
	refresh()
	pass
	
func _set_rotation_offset(value):
	rotation_offset = value
	refresh()
	pass
	
func _set_track_control_point(value):
	track_control_point = value
	refresh()
	pass
	
func _set_normal_length(value):
	normal_length = value
	refresh()
	pass
	
func _set_control_point_offset(value):
	control_point_offset = value
	refresh()
	pass
	
func _handle_point_change():
	refresh()
	pass
	
func refresh():
	if monitored_shape != null:
		if has_node(monitored_shape) == true:
			var node = get_node(monitored_shape)
			if is_instance_valid(node) == false:
				return
			if node.is_queued_for_deletion() == true:
				node.disconnect("points_modified", self, "_handle_point_change")
				return
				
				
			var pt_a_index = track_control_point
			var pt_b_index = track_control_point + 1
			if control_point_offset < 0:
				pt_b_index = pt_a_index -1

			# fixup indexes by wrapping if necessary
			if pt_b_index < 0:
				pt_b_index = node.get_point_count() - pt_b_index
				
			pt_a_index = pt_a_index % node.get_point_count()
			pt_b_index = pt_b_index % node.get_point_count()
				
			var pt_a = node.global_transform.xform( node.get_point_position(pt_a_index) )
			var pt_b = node.global_transform.xform( node.get_point_position(pt_b_index) )
			
			var n_pt
			var angle = 0.0
			
			if (control_point_offset >= 0):
				n_pt = pt_a + ((pt_b - pt_a) * control_point_offset)
				angle = atan2(pt_a.y - pt_b.y, pt_a.x - pt_b.x)
			else:
				n_pt = pt_a + ((pt_a - pt_b) * control_point_offset)
				angle = atan2(pt_b.y - pt_a.y, pt_b.x - pt_a.x)
			
			self.global_transform = Transform2D(angle + rotation_offset, n_pt)
			
			if copy_scale == true:
				self.scale = node.scale

	
	update()
	pass
	
func _draw():
	if Engine.editor_hint == true:
		draw_line(Vector2.ZERO, Vector2(0,-normal_length), self.modulate)
	pass
