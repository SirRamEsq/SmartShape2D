@tool
extends Node2D

class_name RMSmartShapeAnchor2D, "./assets/LEGACY_shape_anchor.png"

# @export (NodePath) var monitored_shape setget _set_monitored_shape
var _monitored_shape: NodePath
@export var monitored_shape : NodePath:
	get: return _monitored_shape
	set(v): _set_monitored_shape

# @export (int) var track_control_point setget _set_track_control_point
var _track_control_point : int
@export var track_control_point : int:
	get: return _track_control_point
	set(v): _set_track_control_point

# @export (float) var normal_length = 100.0 setget _set_normal_length
var _normal_length : float = 100.0
@export var normal_length : float:
	get: return _normal_length
	set(v): _set_normal_length

# @export (float, -1.0, 1.0) var control_point_offset setget _set_control_point_offset
var _contol_point_offset: float
@export_range(0.0, 10.0, 0.2, "or_lesser" ) var control_point_offset : float:
	get: return _contol_point_offset
	set(v): _set_control_point_offset

# @export (float, -3.14159, 3.14159) var rotation_offset = 0 setget _set_rotation_offset
var _rotation_offset : float = 0
@export var rotation_offset : float:
	get: return _rotation_offset
	set(v): _set_rotation_offset

# @export (bool) var copy_scale = false setget _set_copy_scale
var _copy_scale : bool = false
@export var copy_scale : bool:
	get: return _copy_scale
	set(v): _set_copy_scale

var connected = false

var monitored_transform

func _process(delta):
	if str(monitored_shape) != null and str(monitored_shape) == "":
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
					
func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float):
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)

	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)

	var s = r0.lerp(r1, t)
	return s

func _set_monitored_shape(value):
	if value == null and monitored_shape != null:
		if has_node(monitored_shape):
			# get_node(monitored_shape).disconnect("points_modified", self, "_handle_point_change")
			get_node(monitored_shape).points_modified.disconnect(_handle_point_change)
			# get_node(monitored_shape).disconnect("tree_exiting", self, "_monitored_node_leaving")
			get_node(monitored_shape).tree_exiting.disconnect(_monitored_node_leaving)
		connected = false

	if value=="":
		value = null

	if value != null:
		if has_node(value):
			# get_node(value).connect("points_modified", self, "_handle_point_change")
			get_node(value).points_modified.connect(_handle_point_change)
			# connected = get_node(value).is_connected("points_modified", self, "_handle_point_change")
			connected = get_node(value).points_modified.is_connected(_handle_point_change)
			# get_node(value).connect("tree_exiting", self, "_monitored_node_leaving")
			get_node(value).tree_exiting.connect(_monitored_node_leaving)

	monitored_shape = value
	refresh()

func _monitored_node_leaving():
	_set_monitored_shape(null)

func _set_copy_scale(value):
	copy_scale = value
	refresh()

func _set_rotation_offset(value):
	rotation_offset = value
	refresh()

func _set_track_control_point(value):
	if value==track_control_point:
		return

	if monitored_shape==null:
		return

	if has_node(monitored_shape) == true:
		var node = get_node(monitored_shape)
		if node.is_closed_shape():
			if value>node.get_point_count()-2:
				value = 0
			if value<0:
				value = node.get_point_count()-2
		else:
			if value>=node.get_point_count():
				value = 0
			if value<0:
				value = node.get_point_count()-1

	track_control_point = value
	refresh()

	_set_control_point_offset(control_point_offset)

func _set_normal_length(value):
	normal_length = value
	refresh()

func _set_control_point_offset(value):
	if has_node(monitored_shape):
		var node = get_node(monitored_shape)
		if not node.is_closed_shape():
			if track_control_point==0 and value<0:
				value = 0.001
				# property_list_changed_notify()
				notify_property_list_changed()
			if track_control_point==node.get_point_count()-1 and value>0:
				value = -0.001
				# property_list_changed_notify()
				notify_property_list_changed()

	control_point_offset = value
	refresh()

func _handle_point_change():
	refresh()

func refresh():
	if monitored_shape != null:
		if has_node(monitored_shape) == true:
			var node = get_node(monitored_shape)
			if is_instance_valid(node) == false:
				return
			if node.is_queued_for_deletion() == true:
				node.points_modified.disconnect(_handle_point_change)
				return

			var point_count = node.get_point_count()
			#print("RMSmartShapeAnchor2D::refresh Point Count: %s" %s point_count)
			var pt_a_index = track_control_point + point_count
			var pt_b_index = track_control_point + point_count + 1
			
			if control_point_offset < 0:
				pt_b_index -= 2
			
			if control_point_offset < 0:
				pt_b_index = pt_a_index - 1

			if node.is_closed_shape():
				if (track_control_point % point_count) == 0:
					if control_point_offset < 0:
						pt_b_index = point_count - 2

			# fixup indexes by wrapping if necessary
			#if pt_b_index < 0:
				#pt_b_index = node.get_point_count() - pt_b_index

			pt_a_index = pt_a_index % node.get_point_count()
			pt_b_index = pt_b_index % node.get_point_count()

			var pt_a:Vector2 = node.global_transform.xform( node.get_point_position(pt_a_index) )
			var pt_b:Vector2 = node.global_transform.xform( node.get_point_position(pt_b_index) )
			
			# might need to know the direction of the shape before determining which in/out
			# is needed.
			var pt_a_handle:Vector2
			var pt_b_handle:Vector2

			var n_pt:Vector2
			var n_pt_a:Vector2
			var n_pt_b:Vector2
			
			var angle = 0.0

			if (control_point_offset >= 0):
				pt_a_handle = node.global_transform.xform( node.get_point_position(pt_a_index) + node.get_point_out(pt_a_index))
				pt_b_handle = node.global_transform.xform( node.get_point_position(pt_b_index) + node.get_point_in(pt_b_index))
				
				n_pt = _cubic_bezier(pt_a, pt_a_handle, pt_b_handle, pt_b, control_point_offset)
				n_pt_a = _cubic_bezier(pt_a, pt_a_handle, pt_b_handle, pt_b, clamp(control_point_offset-0.1,0.0,1.0))
				n_pt_b = _cubic_bezier(pt_a, pt_a_handle, pt_b_handle, pt_b, clamp(control_point_offset+0.1,0.0,1.0))

				angle = atan2(n_pt_a.y - n_pt_b.y, n_pt_a.x - n_pt_b.x)
			else:
				pt_a_handle = node.global_transform.xform( node.get_point_position(pt_a_index) + node.get_point_in(pt_a_index))
				pt_b_handle = node.global_transform.xform( node.get_point_position(pt_b_index) + node.get_point_out(pt_b_index))
				
				n_pt = _cubic_bezier(pt_a, pt_a_handle, pt_b_handle, pt_b, -control_point_offset)
				n_pt_a = _cubic_bezier(pt_a, pt_a_handle, pt_b_handle, pt_b, clamp(-control_point_offset-0.1,0.0,1.0))
				n_pt_b = _cubic_bezier(pt_a, pt_a_handle, pt_b_handle, pt_b, clamp(-control_point_offset+0.1,0.0,1.0))

				angle = atan2(n_pt_b.y - n_pt_a.y, n_pt_b.x - n_pt_a.x)

			self.global_transform = Transform2D(angle + rotation_offset, n_pt)

			if copy_scale == true:
				self.scale = node.scale

	update()

func _draw():
	if Engine.editor_hint == true:
		draw_line(Vector2.ZERO, Vector2(0,-normal_length), self.modulate)
