tool
extends Node2D
class_name RMSmartShape2D, "./assets/LEGACY_shape.png"

"""
- This class assumes that points are in clockwise orientation
- This class does not support polygons with a counter-clockwise orientation
	- To remedy this, it contains functions to detect and invert the orientation if needed
		- Inverting the orientation will need to be called by the code using this class
		- Inverting the orientation isn't autmoatically done by the class
			- This would change the indices of points and would cause weird issues
"""

enum DIRECTION {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
	TOP_LEFT_INNER,
	TOP_RIGHT_INNER,
	BOTTOM_RIGHT_INNER,
	BOTTOM_LEFT_INNER,
	TOP_LEFT_OUTER,
	TOP_RIGHT_OUTER,
	BOTTOM_RIGHT_OUTER,
	BOTTOM_LEFT_OUTER,
	FILL
}


func _dir_to_string(d: int):
	match d:
		DIRECTION.TOP:
			return "TOP"
		DIRECTION.RIGHT:
			return "RIGHT"
		DIRECTION.LEFT:
			return "LEFT"
		DIRECTION.BOTTOM:
			return "BOTTOM"
		DIRECTION.FILL:
			return "FILL"
		DIRECTION.TOP_LEFT_INNER:
			return "TOP-LEFT-INNER"
		DIRECTION.TOP_RIGHT_INNER:
			return "TOP-RIGHT-INNER"
		DIRECTION.BOTTOM_RIGHT_INNER:
			return "BOTTOM-RIGHT-INNER"
		DIRECTION.BOTTOM_LEFT_INNER:
			return "BOTTOM-LEFT-INNER"
		DIRECTION.TOP_LEFT_OUTER:
			return "TOP-LEFT-OUTER"
		DIRECTION.TOP_RIGHT_OUTER:
			return "TOP-RIGHT-OUTER"
		DIRECTION.BOTTOM_RIGHT_OUTER:
			return "BOTTOM-RIGHT-OUTER"
		DIRECTION.BOTTOM_LEFT_OUTER:
			return "BOTTOM-LEFT-OUTER"
	return "???"


class MeshInfo:
	extends Reference
	"""
	Extends from Reference to avoid memory leaks
	Used to organize all requested meshes to be rendered by their texture
	"""
	var texture: Texture = null
	var normal_texture: Texture = null
	var meshes: Array
	var direction: int


class QuadInfo:
	extends Reference
	"""
	Extends from Reference to avoid memory leaks
	Used to describe the welded quads that form the edge data
	"""
	var pt_a: Vector2
	var pt_b: Vector2
	var pt_c: Vector2
	var pt_d: Vector2

	var tex: Texture
	var normal_tex: Texture
	var color: Color

	var flip_texture: bool = false
	var width_factor: float = 1.0
	var direction: int
	var control_point_index: int

	func get_length() -> float:
		return (pt_d.distance_to(pt_a) + pt_c.distance_to(pt_b)) / 2.0

	func different_render(q: QuadInfo) -> bool:
		"""
		Will return true if this quad is part of a different render sequence than q
		"""
		if (
			q.direction != direction
			or q.tex != tex
			or q.flip_texture != flip_texture
			or q.normal_tex != normal_tex
		):
			return true
		return false


export (bool) var editor_debug = false setget _set_editor_debug
export (Curve2D) var curve: Curve2D = null setget _set_curve
export (bool) var closed_shape = false setget _set_close_shape
export (bool) var auto_update_collider = false setget _set_auto_update_collider
export (int, 1, 8) var tessellation_stages = 5 setget _set_tessellation_stages
export (int, 1, 8) var tessellation_tolerence = 4 setget _set_tolerence
export (bool) var use_global_space = false setget _set_use_global_space
export (NodePath) var collision_polygon_node
export (int, 1, 512) var collision_bake_interval = 20
export (bool) var draw_edges: bool = false setget _set_has_edge
export (bool) var flip_edges: bool = false setget _set_flip_edge

export (Resource) var shape_material = RMS2D_Material.new() setget _set_material

# This will set true if it is time to rebake mesh, should prevent unnecessary
# mesh creation unless a change to a property deems it necessary
var _dirty: bool = true

var vertex_properties = RMS2D_VertexPropertiesArray.new(0)

# For rendering fill and edges
var meshes: Array = Array()
var _quads: Array

# Reduce clockwise check if points don't change
var is_clockwise: bool = false setget , are_points_clockwise

# Signals
signal points_modified
signal on_dirty_update
signal on_closed_change


#########
# GODOT #
#########
func _init():
	pass

func _has_minimum_point_count() -> bool:
	if closed_shape:
		return get_point_count() >= 3
	return get_point_count() >= 2

func _ready():
	if curve == null:
		curve = Curve2D.new()


func _process(delta):
	if not is_inside_tree():
		return
	_on_dirty_update()


func _enter_tree():
	pass


func _exit_tree():
	if shape_material != null:
		if ClassDB.class_has_signal("RMS2D_Material", "changed"):
			shape_material.disconnect("changed", self, "_handle_material_change")


func _on_dirty_update():
	if _dirty:
		fix_close_shape()
		if auto_update_collider:
			bake_collision()
		bake_mesh()
		update()
		_dirty = false
		emit_signal("on_dirty_update")


"""
Will make sure a shape is closed or open after removing / adding / changing a point
"""


func fix_close_shape():
	if not _has_minimum_point_count():
		return
	var point_count = get_point_count()
	var first_point = curve.get_point_position(0)
	var final_point = curve.get_point_position(point_count - 1)
	if closed_shape and first_point != final_point:
		add_point_to_curve(get_point_position(0))
		set_as_dirty()
	elif (
		not closed_shape
		and get_point_position(0) == get_point_position(point_count - 1)
		and point_count > 2
	):
		remove_point(point_count - 1)
		set_as_dirty()


func _draw():
	if not is_inside_tree():
		return

	# Draw fill
	var mesh_transform = Transform2D()
	for mesh in meshes:
		if (
			mesh != null
			and mesh.meshes.size() != 0
			and mesh.texture != null
			and mesh.direction == DIRECTION.FILL
		):
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture, mesh_transform)

	# Draw Left and Right
	for mesh in meshes:
		if (
			mesh != null
			and mesh.meshes.size() != 0
			and mesh.texture != null
			and (mesh.direction == DIRECTION.LEFT or mesh.direction == DIRECTION.RIGHT)
		):
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# Draw Bottom
	for mesh in meshes:
		if (
			mesh != null
			and mesh.meshes.size() != 0
			and mesh.texture != null
			and mesh.direction == DIRECTION.BOTTOM
		):
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# Draw Top
	for mesh in meshes:
		if (
			mesh != null
			and mesh.meshes.size() != 0
			and mesh.texture != null
			and mesh.direction == DIRECTION.TOP
		):
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# Draw Corners
	for mesh in meshes:
		if (
			mesh != null
			and mesh.meshes.size() != 0
			and mesh.texture != null
			and _is_corner_direction(mesh.direction)
		):
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# Draw edge quads for debug purposes (ONLY IN EDITOR)
	if Engine.editor_hint and editor_debug:
		for q in _quads:
			var t: QuadInfo = q
			draw_line(t.pt_a, t.pt_b, t.color)
			draw_line(t.pt_b, t.pt_c, t.color)
			draw_line(t.pt_c, t.pt_d, t.color)
			draw_line(t.pt_d, t.pt_a, t.color)

		var _range
		if not closed_shape:
			_range = range(1, _quads.size())
		else:
			_range = range(_quads.size())

		for index in _range:
			if not (index % 3 == 0):
				continue
			# Skip the first and last vert if the shape isn't closed
			if not closed_shape and (index == 0 or index == _quads.size()):
				continue
			var this_quad: QuadInfo = _quads[index % _quads.size()]
			draw_circle(this_quad.pt_a, 3, Color(0.5, 0, 0))
			draw_circle(this_quad.pt_b, 3, Color(0, 0, 0.5))
			draw_circle(this_quad.pt_c, 3, Color(0, 0.5, 0))
			draw_circle(this_quad.pt_d, 3, Color(0.5, 0, 0.5))
		for index in _range:
			if not ((index + 1) % 3 == 0):
				continue
			# Skip the first and last vert if the shape isn't closed
			if not closed_shape and (index == 0 or index == _quads.size()):
				continue
			var this_quad: QuadInfo = _quads[index % _quads.size()]
			draw_circle(this_quad.pt_a, 2, Color(0.75, 0, 0))
			draw_circle(this_quad.pt_b, 2, Color(0, 0, 0.75))
			draw_circle(this_quad.pt_c, 2, Color(0, 0.75, 0))
			draw_circle(this_quad.pt_d, 2, Color(0.75, 0, 0.75))
		for index in _range:
			if not ((index + 2) % 3 == 0):
				continue
			# Skip the first and last vert if the shape isn't closed
			if not closed_shape and (index == 0 or index == _quads.size()):
				continue
			var this_quad: QuadInfo = _quads[index % _quads.size()]
			draw_circle(this_quad.pt_a, 1, Color(1, 0, 0))
			draw_circle(this_quad.pt_b, 1, Color(0, 0, 1))
			draw_circle(this_quad.pt_c, 1, Color(0, 1, 0))
			draw_circle(this_quad.pt_d, 1, Color(1, 0, 1))


#####################
# SETTERS / GETTERS #
#####################
func _set_tessellation_stages(value: int):
	tessellation_stages = value
	set_as_dirty()


func _set_tolerence(value: int):
	tessellation_tolerence = value
	set_as_dirty()


func _set_material(value: RMS2D_Material):
	if (
		shape_material != null
		and shape_material.is_connected("changed", self, "_handle_material_change")
	):
		shape_material.disconnect("changed", self, "_handle_material_change")

	shape_material = value
	if shape_material != null:
		shape_material.connect("changed", self, "_handle_material_change")
	set_as_dirty()


func _set_close_shape(value):
	closed_shape = value
	fix_close_shape()
	emit_signal("on_closed_change")
	if Engine.editor_hint:
		property_list_changed_notify()


func _set_auto_update_collider(value: bool):
	auto_update_collider = value
	if auto_update_collider:
		bake_collision()


func _set_curve(value: Curve2D):
	curve = value

	if vertex_properties.resize(curve.get_point_count()):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


######################
# SET/GET FOR ARRAYS #
######################
func set_point_width(width: float, at_position: int):
	if vertex_properties.set_width(width, at_position):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_width(at_position: int) -> float:
	return vertex_properties.get_width(at_position)


func is_closed_shape() -> bool:
	return closed_shape


func set_point_texture_index(point_index: int, tex_index: int):
	if vertex_properties.set_texture_idx(tex_index, point_index):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func get_point_texture_index(at_position: int) -> int:
	return vertex_properties.get_texture_idx(at_position)


func get_point_texture_flip(at_position: int) -> bool:
	return vertex_properties.get_flip(at_position)


func set_point_texture_flip(flip: bool, at_position: int):
	if vertex_properties.set_flip(flip, at_position):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


######################
######################
######################


func set_point_in(idx: int, p: Vector2):
	if curve != null:
		curve.set_point_in(idx, p)
		set_as_dirty()
		emit_signal("points_modified")


func set_point_out(idx: int, p: Vector2):
	if curve != null:
		curve.set_point_out(idx, p)
		set_as_dirty()
		emit_signal("points_modified")


func get_point_in(idx: int) -> Vector2:
	if curve != null:
		return curve.get_point_in(idx)
	return Vector2(0, 0)


func get_point_out(idx: int) -> Vector2:
	if curve != null:
		return curve.get_point_out(idx)
	return Vector2(0, 0)


func get_closest_point(to_point: Vector2):
	if curve != null:
		return curve.get_closest_point(to_point)
	return null


func get_closest_offset(to_point: Vector2):
	if curve != null:
		return curve.get_closest_offset(to_point)
	return null


func _set_editor_debug(value: bool):
	editor_debug = value
	set_as_dirty()


func _set_flip_edge(value):
	flip_edges = value
	set_as_dirty()


func _set_has_edge(value):
	draw_edges = value
	set_as_dirty()


func _set_use_global_space(value):
	use_global_space = value
	set_as_dirty()


func get_point_count():
	if curve == null:
		return 0
	return curve.get_point_count()


func get_point_position(at_position: int):
	if curve != null:
		if at_position < curve.get_point_count() and at_position >= 0:
			return curve.get_point_position(at_position)
	return null


############
# GEOMETRY #
############
func _add_mesh(mesh: ArrayMesh, texture: Texture, normal_texture: Texture, direction: int):
	var found: bool = false

	# Is there already a MeshInfo with these textures?
	for m in meshes:
		if m.texture == texture and m.normal_texture == normal_texture:
			# if so, add this mesh to that MeshInfo
			m.meshes.push_back(mesh)
			found = true

	if not found:
		# If not, make a new mesh for these textures
		var m = MeshInfo.new()
		m.meshes = [mesh]
		m.texture = texture
		m.normal_texture = normal_texture
		m.direction = direction
		meshes.push_back(m)


func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)


func are_points_clockwise() -> bool:
	if not _has_minimum_point_count():
		return true
	var sum = 0.0
	var point_count = curve.get_point_count()
	for i in point_count:
		var pt = curve.get_point_position(i)
		var pt2 = curve.get_point_position((i + 1) % point_count)
		sum += pt.cross(pt2)

	is_clockwise = sum > 0.0
	return is_clockwise


func _weld_quads(quads: Array, custom_scale: float = 1.0):
	for index in range(quads.size()):
		# Skip the first and last vert if the shape isn't closed
		if not closed_shape and (index == 0 or index == quads.size()):
			continue

		var previous_quad: QuadInfo = quads[(index - 1) % quads.size()]
		var this_quad: QuadInfo = quads[index % quads.size()]
		var next_quad: QuadInfo = quads[(index + 1) % quads.size()]

		var needed_length: float = 0.0
		if previous_quad.tex != null and this_quad.tex != null:
			needed_length = (
				(
					previous_quad.tex.get_size().y
					+ (this_quad.tex.get_size().y * this_quad.width_factor)
				)
				* 0.5
			)

		if (
			not _is_corner_direction(previous_quad.direction)
			and not _is_corner_direction(this_quad.direction)
		):
			var pt1 = (previous_quad.pt_d + this_quad.pt_a) * 0.5
			var pt2 = (previous_quad.pt_c + this_quad.pt_b) * 0.5

			var mid_point: Vector2 = (pt1 + pt2) * 0.5
			var half_line: Vector2 = (
				(pt2 - mid_point).normalized()
				* needed_length
				* custom_scale
				* 0.5
			)

			if half_line != Vector2.ZERO:
				pt2 = mid_point + half_line
				pt1 = mid_point - half_line

			this_quad.pt_a = pt1
			this_quad.pt_b = pt2
			previous_quad.pt_d = pt1
			previous_quad.pt_c = pt2
		else:
			if _is_outer_direction(previous_quad.direction):
				this_quad.pt_a = previous_quad.pt_c
				this_quad.pt_b = previous_quad.pt_b

			elif _is_inner_direction(previous_quad.direction):
				this_quad.pt_a = previous_quad.pt_d
				this_quad.pt_b = previous_quad.pt_a

			if _is_outer_direction(this_quad.direction):
				previous_quad.pt_d = this_quad.pt_a
				previous_quad.pt_c = this_quad.pt_b

			elif _is_inner_direction(this_quad.direction):
				previous_quad.pt_d = this_quad.pt_d
				previous_quad.pt_c = this_quad.pt_c

func _is_cardinal_direction(d: int) -> bool:
	"""
	Takes a values from the DIRECTION enum
	If the direction is a cardinal direction (Top,Bottom,Left,Right)
		Will return true
	else return false
	"""
	match d:
		DIRECTION.TOP:
			return true
		DIRECTION.LEFT:
			return true
		DIRECTION.RIGHT:
			return true
		DIRECTION.BOTTOM:
			return true
	return false


func _is_corner_direction(d: int) -> bool:
	match d:
		DIRECTION.TOP_LEFT_INNER:
			return true
		DIRECTION.TOP_RIGHT_INNER:
			return true
		DIRECTION.BOTTOM_RIGHT_INNER:
			return true
		DIRECTION.BOTTOM_LEFT_INNER:
			return true
		DIRECTION.TOP_LEFT_OUTER:
			return true
		DIRECTION.TOP_RIGHT_OUTER:
			return true
		DIRECTION.BOTTOM_RIGHT_OUTER:
			return true
		DIRECTION.BOTTOM_LEFT_OUTER:
			return true
	return false


func _is_inner_direction(d: int) -> bool:
	match d:
		DIRECTION.TOP_LEFT_INNER:
			return true
		DIRECTION.TOP_RIGHT_INNER:
			return true
		DIRECTION.BOTTOM_RIGHT_INNER:
			return true
		DIRECTION.BOTTOM_LEFT_INNER:
			return true
	return false


func _is_outer_direction(d: int) -> bool:
	match d:
		DIRECTION.TOP_LEFT_OUTER:
			return true
		DIRECTION.TOP_RIGHT_OUTER:
			return true
		DIRECTION.BOTTOM_RIGHT_OUTER:
			return true
		DIRECTION.BOTTOM_LEFT_OUTER:
			return true
	return false


func _get_direction_three_points(
	point: Vector2, point_next: Vector2, point_prev: Vector2, top_tilt: float, bottom_tilt: float
) -> int:
	var ab = point - point_prev
	var bc = point_next - point
	var dot_prod = ab.dot(bc)
	var determinant = (ab.x*bc.y) - (ab.y*bc.x)
	var angle = atan2(determinant, dot_prod)
	# This angle has a range of 360 degrees
	# Is between 180 and - 180
	var deg = rad2deg(angle)

	var clockwise = are_points_clockwise()
	var dir = 0
	var ab_dir = _get_direction_two_points(point_prev, point, top_tilt, bottom_tilt)
	var bc_dir = _get_direction_two_points(point, point_next, top_tilt, bottom_tilt)
	var corner_range = 15.0
	if _in_range(abs(deg), 90.0 - corner_range, 90.0 + corner_range):
		var ab_normal = ab.tangent().normalized()
		var bc_normal = bc.tangent().normalized()
		var averaged = (ab_normal + bc_normal) / 2.0
		if not clockwise:
			averaged *= -1.0

		var inner = false
		if deg < 0:
			inner = true
		if flip_edges:
			inner = not inner
		dir = _vector_to_corner_dir(averaged, inner)

	else:
		dir = _get_direction_two_points(point, point_next, top_tilt, bottom_tilt)
	#var dirs = [_dir_to_string(ab_dir), _dir_to_string(bc_dir), _dir_to_string(dir)]
	#print("===")
	#print("AB: %s  |  BC: %s" % [str(ab), str(bc)])
	#print(("dot: %s  |  deg: %s  |  dirs: %s"% [str(dot_prod), str(deg), dirs]))
	return dir


func _in_range(v: float, low: float, high: float) -> bool:
	return (v >= low) and (v <= high)


func to_positive_angle(angle: float) -> float:
	angle = fmod(angle, 360)
	if angle < 0:
		angle += 360
	return angle


func _vector_to_corner_dir(vec: Vector2, inner: bool) -> int:
	var deg = rad2deg(vec.angle()) + 90.0
	deg = to_positive_angle(deg)

	if _in_range(deg, 0.0, 90.0):
		if inner:
			return DIRECTION.BOTTOM_LEFT_INNER
		return DIRECTION.TOP_RIGHT_OUTER
	if _in_range(deg, 90.0, 180.0):
		if inner:
			return DIRECTION.TOP_LEFT_INNER
		return DIRECTION.BOTTOM_RIGHT_OUTER # Correct
	if _in_range(deg, 180.0, 270.0):
		if inner:
			return DIRECTION.TOP_RIGHT_INNER
		return DIRECTION.BOTTOM_LEFT_OUTER # Correct
	if _in_range(deg, 270.0, 360.0):
		if inner:
			return DIRECTION.BOTTOM_RIGHT_INNER
		return DIRECTION.TOP_LEFT_OUTER

	return -1


func _get_direction_two_points(point, point_next, top_tilt, bottom_tilt) -> int:
	var v1: Vector2 = point
	var v2: Vector2 = point_next

	if use_global_space:
		v1 = get_global_transform().xform(point)
		v2 = get_global_transform().xform(point_next)

	var clockwise = are_points_clockwise()
	var top_mid = 0.0
	var bottom_mid = PI
	if not clockwise:
		top_mid = PI
		bottom_mid = 0

	var angle = atan2(v2.y - v1.y, v2.x - v1.x)

	#Precedence is given to top
	if abs(top_mid - abs(angle)) <= deg2rad(top_tilt):
		return DIRECTION.TOP

	#And then to bottom
	if abs(bottom_mid - abs(angle)) <= deg2rad(bottom_tilt):
		return DIRECTION.BOTTOM

	if angle > 0:
		if clockwise:
			return DIRECTION.RIGHT
		return DIRECTION.LEFT
	else:
		if clockwise:
			return DIRECTION.LEFT
		return DIRECTION.RIGHT


func _adjust_mesh_quad_segment(quads: Array, quad_indices: Array):
	var total_length: float = 0.0
	for quad_index in quad_indices:
		total_length += quads[quad_index].get_length()

	# Iterate over the quads now until change in direction or texture or looped around
	var mesh_start_index: int = quad_indices[0]
	var st: SurfaceTool = SurfaceTool.new()
	var first_quad = quads[quad_indices[0]]
	# All quads should not differ. Should have same tex and normal_tex
	var tex: Texture = first_quad.tex
	var normal_tex: Texture = first_quad.normal_tex

	var length: float = 0.0
	var mesh_direction: int
	var change_in_length: float = -1.0
	if tex != null and change_in_length == -1.0:
		change_in_length = (
			(round(total_length / tex.get_size().x) * tex.get_size().x)
			/ total_length
		)

	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for quad_index in quad_indices:
		var this_quad: QuadInfo = quads[quad_index % quads.size()]
		var next_quad: QuadInfo = quads[(quad_index + 1) % quads.size()]
		var section_length: float = this_quad.get_length() * change_in_length
		if section_length == 0:
			section_length = tex.get_size().x

		st.add_color(Color.white)

		# A
		if tex != null:
			if not this_quad.flip_texture:
				_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 0))
			else:
				_add_uv_to_surface_tool(
					st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 0)
				)
		st.add_vertex(_to_vector3(this_quad.pt_a))

		# B
		if tex != null:
			if not this_quad.flip_texture:
				_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 1))
			else:
				_add_uv_to_surface_tool(
					st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 1)
				)
		st.add_vertex(_to_vector3(this_quad.pt_b))

		# C
		if tex != null:
			if not this_quad.flip_texture:
				_add_uv_to_surface_tool(
					st, Vector2((length + section_length) / tex.get_size().x, 1)
				)
			else:
				_add_uv_to_surface_tool(
					st,
					Vector2(
						(
							(total_length * change_in_length - (section_length + length))
							/ tex.get_size().x
						),
						1
					)
				)
		st.add_vertex(_to_vector3(this_quad.pt_c))

		# A
		if tex != null:
			if not this_quad.flip_texture:
				_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 0))
			else:
				_add_uv_to_surface_tool(
					st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 0)
				)
		st.add_vertex(_to_vector3(this_quad.pt_a))

		# C
		if tex != null:
			if not this_quad.flip_texture:
				_add_uv_to_surface_tool(
					st, Vector2((length + section_length) / tex.get_size().x, 1)
				)
			else:
				_add_uv_to_surface_tool(
					st,
					Vector2(
						(
							(total_length * change_in_length - (length + section_length))
							/ tex.get_size().x
						),
						1
					)
				)
		st.add_vertex(_to_vector3(this_quad.pt_c))

		# D
		if tex != null:
			if not this_quad.flip_texture:
				_add_uv_to_surface_tool(
					st, Vector2((length + section_length) / tex.get_size().x, 0)
				)
			else:
				_add_uv_to_surface_tool(
					st,
					Vector2(
						(
							(total_length * change_in_length - (length + section_length))
							/ tex.get_size().x
						),
						0
					)
				)
		st.add_vertex(_to_vector3(this_quad.pt_d))
		length += section_length

	st.index()
	st.generate_normals()
	#st.generate_tangents()
	_add_mesh(st.commit(), tex, normal_tex, mesh_direction)


func _adjust_mesh_quads(quads: Array):
	"""
	The purpose of this function is to adjust mesh quads so they look good
	Afterward, they are added to the mesh
	Not intended for collision quads
	"""
	if quads.size() < 1:
		return

	var quad_range
	var quad_range_len = 0
	var global_index = 0
	if not closed_shape:
		quad_range = range(1, quads.size())
		quad_range_len = quads.size() - 1
		global_index = 1
	else:
		quad_range = range(quads.size())
		quad_range_len = quads.size()

	# Weld quads if weld_edges is on
	if shape_material.weld_edges:
		_weld_quads(quads)

	var quad_segments = []

	# Get initial start index
	var initial_start_index = 0
	if closed_shape:
		for i in quad_range:
			initial_start_index = i
			var prev_quad_index = (i - 1) % quads.size()
			var this_quad: QuadInfo = quads[i]
			var prev_quad: QuadInfo = quads[prev_quad_index]
			if (
				(i + 1 == quads.size() and not closed_shape)
				or this_quad.different_render(prev_quad)
			):
				break

	var start_index: int = initial_start_index
	for j in quad_range:
		var new_segment = []
		for i in range(quads.size()):
			var length_index = (start_index + i) % quads.size()
			var length_index_next: int = (start_index + i + 1) % quads.size()
			new_segment.push_back(length_index)

			var this_quad: QuadInfo = quads[length_index]
			var next_quad: QuadInfo = quads[length_index_next]
			# Break if change detected
			if (
				(length_index + 1 == quads.size() and not closed_shape)
				or this_quad.different_render(next_quad)
			):
				break
		quad_segments.push_back(new_segment)
		start_index += new_segment.size()
		j += new_segment.size()
		if (
			(start_index == quads.size() and not closed_shape)
			or ((start_index) % quads.size() == initial_start_index and closed_shape)
		):
			break
	for segment in quad_segments:
		_adjust_mesh_quad_segment(quads, segment)


func get_vertices() -> Array:
	var verts = []
	for i in range(0, curve.get_point_count(), 1):
		verts.push_back(curve.get_point_position(i))
	return verts


func get_distance_as_ratio_from_tessellated_point(points, tess_points, tess_point_index) -> float:
	"""
	Returns a float between 0.0 and 1.0
	0.0 means that this tessellated point is at the same position as the vertex
	0.5 means that this tessellated point is half way between this vertex and the next
	0.999 means that this tessellated point is basically at the next vertex
	1.0 isn't going to happen; If a tess point is at the same position as a vert, it gets a ratio of 0.0
	"""
	if tess_point_index == 0:
		return 0.0

	var vertex_idx = -1
	# The total tessellated points betwen two verts
	var tess_point_count = 0
	# The index of the passed tess_point_index relative to the starting vert
	var tess_index_count = 0
	for i in range(0, tess_points.size(), 1):
		var tp = tess_points[i]
		var p = points[vertex_idx + 1]
		tess_point_count += 1
		if i < tess_point_index:
			tess_index_count += 1
		if tp == p:
			if i < tess_point_index:
				vertex_idx += 1
				tess_point_count = 0
				tess_index_count = 0
			else:
				break

	return float(tess_index_count) / float(tess_point_count)


func get_vertex_idx_from_tessellated_point(points, tess_points, tess_point_index) -> int:
	if tess_point_index == 0:
		return 0

	#print("============")
	#print("points: %s  |  tess_p: %s  |  tess_p_i: %s" % [str(points.size()), str(tess_points.size()), str(tess_point_index)])
	var vertex_idx = -1
	for i in range(0, tess_point_index + 1, 1):
		var tp = tess_points[i]
		var p = points[vertex_idx + 1]
		if tp == p:
			#print("i: %s  |  p: %s  |  tp: %s" % [str(i), str(p), str(tp)])
			vertex_idx += 1
	return vertex_idx


func get_tessellated_points() -> PoolVector2Array:
	# Point 0 will be the same on both the curve points and the vertecies
	# Point size - 1 will be the same on both the curve points and the vertecies
	if not _has_minimum_point_count():
		return PoolVector2Array()
	var points = curve.tessellate(tessellation_stages)
	points[0] = curve.get_point_position(0)
	points[points.size() - 1] = curve.get_point_position(curve.get_point_count() - 1)
	return points


func _get_next_point_index(idx: int, points: Array, closed: bool) -> int:
	var new_idx = idx
	if closed_shape:
		new_idx = (idx + 1) % points.size()
	else:
		new_idx = int(min(idx + 1, points.size() - 1))

	if points[idx] == points[new_idx] and closed:
		new_idx = _get_next_point_index(new_idx, points, closed)
	return new_idx


func _get_previous_point_index(idx: int, points: Array, closed: bool) -> int:
	var new_idx = idx
	if closed_shape:
		new_idx = idx - 1
		if new_idx < 0:
			new_idx += points.size()
	else:
		new_idx = int(max(idx - 1, 0))

	if points[idx] == points[new_idx] and closed:
		new_idx = _get_previous_point_index(new_idx, points, closed)
	return new_idx


func _build_corner_quad(
	pt_next: Vector2,
	pt: Vector2,
	pt_prev: Vector2,
	pt_width: float,
	pt_prev_width: float,
	direction: int,
	custom_scale: float,
	custom_offset: float,
	custom_extends: float
) -> QuadInfo:
	var texture = null
	var texture_normal = null
	match direction:
		DIRECTION.TOP_LEFT_INNER:
			texture = shape_material.top_left_inner_texture
			texture_normal = shape_material.top_left_inner_texture_normal
		DIRECTION.TOP_RIGHT_INNER:
			texture = shape_material.top_right_inner_texture
			texture_normal = shape_material.top_right_inner_texture_normal
		DIRECTION.BOTTOM_RIGHT_INNER:
			texture = shape_material.bottom_right_inner_texture
			texture_normal = shape_material.bottom_right_inner_texture_normal
		DIRECTION.BOTTOM_LEFT_INNER:
			texture = shape_material.bottom_left_inner_texture
			texture_normal = shape_material.bottom_left_inner_texture_normal
		DIRECTION.TOP_LEFT_OUTER:
			texture = shape_material.top_left_outer_texture
			texture_normal = shape_material.top_left_outer_texture_normal
		DIRECTION.TOP_RIGHT_OUTER:
			texture = shape_material.top_right_outer_texture
			texture_normal = shape_material.top_right_outer_texture_normal
		DIRECTION.BOTTOM_RIGHT_OUTER:
			texture = shape_material.bottom_right_outer_texture
			texture_normal = shape_material.bottom_right_outer_texture_normal
		DIRECTION.BOTTOM_LEFT_OUTER:
			texture = shape_material.bottom_left_outer_texture
			texture_normal = shape_material.bottom_left_outer_texture_normal

	var new_quad = QuadInfo.new()
	if texture == null:
		return new_quad

	var tex_size = texture.get_size()
	var extents = tex_size / 2.0
	var delta_12 = pt - pt_prev
	var delta_23 = pt_next - pt
	var normal_23 = Vector2(delta_23.y, -delta_23.x).normalized()
	var normal_12 = Vector2(delta_12.y, -delta_12.x).normalized()
	var width = (pt_prev_width + pt_width) / 2.0
	var center = pt + (delta_12.normalized() * extents)

	var offset_12 = (normal_12 * custom_scale * pt_width * extents)
	var offset_23 = (normal_23 * custom_scale * pt_prev_width * extents)
	var custom_offset_13 = ((normal_12 + normal_23) * custom_offset * extents)
	if flip_edges:
		offset_12 *= -1
		offset_23 *= -1
		custom_offset_13 *= -1

	var pt_d = (
		pt
		+ (offset_23)
		+ (offset_12)
		+ custom_offset_13
	)
	var pt_a = (
		pt
		- (offset_23)
		+ (offset_12)
		+ custom_offset_13
		#+ offset_12
	)
	#var pt_c = pt + (center + offset_23) - (center + offset_12) + custom_offset_13
	var pt_c = (
		pt
		+ (offset_23)
		- (offset_12)
		+ custom_offset_13
	)
	var pt_b = (
		pt
		- (offset_23)
		- (offset_12)
		+ custom_offset_13
	)

	#if custom_offset != 1.0 and custom_offset != 0.0:
	#print(("n1:%s  |  n2:%s  | d1:%s  | d2:%s  |  o1:%s  |  o2:%s"% [normal_12, normal_23, delta_12, delta_23, offset_12, offset_23]))
	new_quad.pt_a = pt_a
	new_quad.pt_b = pt_b
	new_quad.pt_c = pt_c
	new_quad.pt_d = pt_d

	new_quad.direction = direction
	new_quad.tex = texture
	new_quad.normal_tex = texture_normal

	return new_quad


func _build_quads(custom_scale: float = 1.0, custom_offset: float = 0, custom_extends: float = 0.0) -> Array:
	"""
	This function will generate an array of quads and return them
	"""
	# The remainder of the code build up the edge quads
	var quads: Array = []
	var tex: Texture = null
	var tex_normal: Texture = null
	var tex_size: Vector2
	var tex_index: int = 0

	var tess_points = get_tessellated_points()
	var tess_count = tess_points.size()

	var points = get_vertices()

	var top_tilt = shape_material.top_texture_tilt
	var bottom_tilt = shape_material.bottom_texture_tilt

	var is_clockwise: bool = are_points_clockwise()
	var corner_quad_indicies = []

	for tess_index in tess_count - 1:
		var tess_index_next = _get_next_point_index(tess_index, tess_points, closed_shape)
		var tess_index_prev = _get_previous_point_index(tess_index, tess_points, closed_shape)
		var tess_pt = tess_points[tess_index]
		var tess_pt_next = tess_points[tess_index_next]
		var tess_pt_prev = tess_points[tess_index_prev]

		var pt_index = get_vertex_idx_from_tessellated_point(points, tess_points, tess_index)
		var pt_index_next = get_vertex_idx_from_tessellated_point(
			points, tess_points, tess_index_next
		)
		var pt_index_prev = get_vertex_idx_from_tessellated_point(
			points, tess_points, tess_index_prev
		)

		var cardinal_direction = DIRECTION.TOP
		var corner_direction = null
		var is_cardinal_direction = true

		if closed_shape:
			cardinal_direction = _get_direction_two_points(
				tess_pt, tess_pt_next, top_tilt, bottom_tilt
			)
			corner_direction = _get_direction_three_points(
				tess_pt, tess_pt_next, tess_pt_prev, top_tilt, bottom_tilt
			)
			is_cardinal_direction = _is_cardinal_direction(corner_direction)

		tex = null
		tex_normal = null
		if shape_material != null:
			var material_textures_diffuse = null
			var material_textures_normal = null
			match cardinal_direction:
				DIRECTION.TOP:
					material_textures_diffuse = shape_material.top_texture
					material_textures_normal = shape_material.top_texture_normal
				DIRECTION.BOTTOM:
					material_textures_diffuse = shape_material.bottom_texture
					material_textures_normal = shape_material.bottom_texture_normal
				DIRECTION.LEFT:
					material_textures_diffuse = shape_material.left_texture
					material_textures_normal = shape_material.left_texture_normal
				DIRECTION.RIGHT:
					material_textures_diffuse = shape_material.right_texture
					material_textures_normal = shape_material.right_texture_normal
			if material_textures_diffuse != null:
				if not material_textures_diffuse.empty():
					tex_index = (
						abs(vertex_properties.get_texture_idx(pt_index))
						% material_textures_diffuse.size()
					)
					if material_textures_diffuse.size() > tex_index:
						tex = material_textures_diffuse[tex_index]
					if material_textures_normal != null:
						if material_textures_normal.size() > tex_index:
							tex_normal = material_textures_normal[tex_index]
		if tex != null:
			tex_size = tex.get_size()

		# Get Perpendicular Vector
		var delta = tess_pt_next - tess_pt
		var delta_normal = delta.normalized()
		var vtx_normal = Vector2(delta.y, -delta.x).normalized()
		# TODO
		# This causes weird rendering if the texture isn't a square
		# IE, if taller than wide, left/right edges look skinny, whereas top/bottom looks normal
		# if wider than tall, top/bottom edges look skinny, whereas left/right looks normal
		var vtx:Vector2 = vtx_normal * (tex_size * 0.5)

		var scale_in: float = 1
		var scale_out: float = 1

		var width = vertex_properties.get_width(pt_index)
		if width != 0.0:
			scale_in = width

		if not are_points_clockwise():
			vtx *= -1

		if flip_edges:  # allow developer to override
			vtx *= -1

		var clr: Color = Color.white
		match cardinal_direction:
			DIRECTION.TOP:
				clr = Color.green
			DIRECTION.LEFT:
				clr = Color.yellow
			DIRECTION.RIGHT:
				clr = Color.red
			DIRECTION.BOTTOM:
				clr = Color.blue

		var offset = Vector2.ZERO
		if tex != null and custom_offset != 0.0:
			offset = vtx
			offset *= custom_offset

		if not closed_shape:
			if tex != null:
				if tess_index == 0:
					tess_pt -= (
						(tess_pt_next - tess_pt).normalized()
						* tex.get_size()
						* custom_extends
					)
				if tess_index == tess_count - 2 and tex != null:
					tess_pt_next -= (
						(tess_pt - tess_pt_next).normalized()
						* tex.get_size()
						* custom_extends
					)

		var ratio = get_distance_as_ratio_from_tessellated_point(points, tess_points, tess_index)
		var w1 = vertex_properties.get_width(pt_index)
		var w2 = vertex_properties.get_width(pt_index_next)
		var w = lerp(w1, w2, ratio)
		#print("(id1: %s, id2: %s) 1: %s |R: %8f |2: %s = %s" % [str(pt_index), str(pt_index_next), str(w1), ratio, str(w2), str(w)])

		var new_quad = QuadInfo.new()
		var final_offset_scale_in = (vtx * scale_in) * custom_scale
		var final_offset_scale_out = (vtx * scale_out) * custom_scale
		#print("VTX: %s  |  S_in: %s  |  CS: %s" % [str(vtx), str(scale_in), str(custom_scale)])
		var pt_a = tess_pt + final_offset_scale_in + offset
		var pt_b = tess_pt - final_offset_scale_in + offset
		var pt_c = tess_pt_next - final_offset_scale_out + offset
		var pt_d = tess_pt_next + final_offset_scale_out + offset
		new_quad.pt_a = pt_a
		new_quad.pt_b = pt_b
		new_quad.pt_c = pt_c
		new_quad.pt_d = pt_d
		new_quad.color = clr
		new_quad.direction = cardinal_direction
		new_quad.tex = tex
		new_quad.normal_tex = tex_normal
		new_quad.flip_texture = vertex_properties.get_flip(pt_index)
		new_quad.width_factor = w

		if not is_cardinal_direction and shape_material.use_corners:
			var prev_width = vertex_properties.get_width(pt_index_prev)
			var new_quad2 = _build_corner_quad(
				tess_pt_next,
				tess_pt,
				tess_pt_prev,
				width,
				prev_width,
				corner_direction,
				custom_scale,
				custom_offset,
				custom_extends
			)
			if new_quad2.tex != null:
				var previous_quad = null
				if quads.size() > 0:
					previous_quad = quads[quads.size() - 1]
				new_quad2.color = Color.purple
				new_quad2.flip_texture = vertex_properties.get_flip(pt_index)
				new_quad2.width_factor = w
				quads.push_back(new_quad2)

				corner_quad_indicies.push_back(quads.size() - 1)

				var quad2_size = new_quad2.tex.get_size()
				var quad2_offset = (quad2_size / 2.0) * delta_normal
				new_quad.pt_a += quad2_offset
				new_quad.pt_b += quad2_offset
				#new_quad.tex = new_quad2.tex
				if previous_quad != null:
					var rotated = Vector2(0, 0)
					if are_points_clockwise():
						rotated = Vector2(-quad2_offset.y, quad2_offset.x)
					else:
						rotated = Vector2(-quad2_offset.y, quad2_offset.x)
					if _is_inner_direction(corner_direction):
						rotated *= -1
					previous_quad.pt_c += rotated
					previous_quad.pt_d += rotated

		quads.push_back(new_quad)

	for corner_quad_index in corner_quad_indicies:
		pass

	return quads


func bake_collision():
	if collision_polygon_node == null or not is_inside_tree():
		return

	if has_node(collision_polygon_node):
		var col_polygon = get_node(collision_polygon_node)
		var points: PoolVector2Array = PoolVector2Array()
		var collision_quads = Array()

		var collision_width = 1.0
		var collision_offset = 0.0
		var collision_extends = 1.0

		if shape_material != null:
			collision_width = shape_material.collision_width
			collision_offset = shape_material.collision_offset + shape_material.render_offset
			collision_extends = shape_material.collision_extends

		if closed_shape:
			var old_interval = curve.bake_interval
			col_polygon.transform = transform
			col_polygon.scale = Vector2.ONE

			curve.bake_interval = old_interval

			#var curve_points = get_tessellated_points()
			#for i in curve_points:
			#points.push_back(
			#col_polygon.get_global_transform().xform_inv(get_global_transform().xform(i))
			#)
			collision_quads = _build_quads(collision_width, collision_offset, collision_extends)
			for quad in collision_quads:
				if _is_cardinal_direction(quad.direction):
					points.push_back(
						col_polygon.get_global_transform().xform_inv(
							get_global_transform().xform(quad.pt_a)
						)
					)
				elif _is_inner_direction(quad.direction):
					points.push_back(
						col_polygon.get_global_transform().xform_inv(
							get_global_transform().xform(quad.pt_d)
						)
					)
				elif _is_outer_direction(quad.direction):
					points.push_back(
						col_polygon.get_global_transform().xform_inv(
							get_global_transform().xform(quad.pt_a)
						)
					)
					points.push_back(
						col_polygon.get_global_transform().xform_inv(
							get_global_transform().xform(quad.pt_d)
						)
					)
			curve.bake_interval = collision_bake_interval
		else:
			collision_quads = _build_quads(collision_width, collision_offset, collision_extends)
			_weld_quads(collision_quads, collision_width)

			if not collision_quads.empty():
				# PT A
				for quad in collision_quads:
					points.push_back(
						col_polygon.get_global_transform().xform_inv(
							get_global_transform().xform(quad.pt_a)
						)
					)

				# PT D
				points.push_back(
					col_polygon.get_global_transform().xform_inv(
						get_global_transform().xform(
							collision_quads[collision_quads.size() - 1].pt_d
						)
					)
				)

				# PT C
				for quad_index in collision_quads.size():
					var quad = collision_quads[collision_quads.size() - 1 - quad_index]
					points.push_back(
						col_polygon.get_global_transform().xform_inv(
							get_global_transform().xform(quad.pt_c)
						)
					)

				# PT B
				points.push_back(
					col_polygon.get_global_transform().xform_inv(
						get_global_transform().xform(collision_quads[0].pt_b)
					)
				)

		col_polygon.polygon = points


func bake_mesh(force: bool = false):
	if not _dirty and not force:
		return
	# Clear Meshes
	for mesh in meshes:
		if mesh.meshes != null:
			mesh.meshes.clear()
	meshes.resize(0)

	# Cant make a mesh without enough points
	var points = get_tessellated_points()
	var point_count = points.size()
	if (closed_shape and point_count < 3) or (not closed_shape and point_count < 2):
		return

	var is_clockwise: bool = are_points_clockwise()
	_quads = Array()

	# Produce Fill Mesh
	var fill_points:PoolVector2Array = PoolVector2Array()
	fill_points.resize(point_count)
	for i in point_count:
		fill_points[i] = points[i]

	var fill_tris: PoolIntArray = Geometry.triangulate_polygon(fill_points)
	var st: SurfaceTool

	if closed_shape and shape_material.fill_texture != null:
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		for i in range(0, fill_tris.size() - 1, 3):
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i]]))
			st.add_vertex(Vector3(points[fill_tris[i]].x, points[fill_tris[i]].y, 0))
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 1]]))
			st.add_vertex(Vector3(points[fill_tris[i + 1]].x, points[fill_tris[i + 1]].y, 0))
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv(points[fill_tris[i + 2]]))
			st.add_vertex(Vector3(points[fill_tris[i + 2]].x, points[fill_tris[i + 2]].y, 0))
		st.index()
		st.generate_normals()
		st.generate_tangents()
		_add_mesh(
			st.commit(),
			shape_material.fill_texture,
			shape_material.fill_texture_normal,
			DIRECTION.FILL
		)

	if closed_shape and not draw_edges:
		return

	# Build Edge Quads
	_quads = _build_quads(1.0, shape_material.render_offset)
	_adjust_mesh_quads(_quads)


#########
# CURVE #
#########
func invert_point_order():
	var verts = get_vertices()

	# Store inverted verts and properties
	var inverted_properties = []
	var inverted = []
	for i in range(0, verts.size(), 1):
		var vert = verts[i]
		var prop = vertex_properties.properties[i]
		inverted.push_front(vert)
		inverted_properties.push_front(prop)

	# Clear Verts, add Inverted Verts
	curve.clear_points()
	_quads = []
	meshes = []
	add_points_to_curve(inverted, -1, false)

	# Set Inverted Properties
	for i in range(0, inverted_properties.size(), 1):
		var prop = inverted_properties[i]
		vertex_properties.properties[inverted_properties.size() - i] = prop

	# Update and set as dirty
	set_as_dirty()

	if Engine.editor_hint:
		property_list_changed_notify()

func clear_points():
	curve.clear_points()
	vertex_properties = RMS2D_VertexPropertiesArray.new(0)
	_quads = []
	meshes = []

func add_points_to_curve(verts:Array, starting_index: int = -1, update:bool = true):
	for i in range(0, verts.size(), 1):
		var v = verts[i]
		if starting_index != -1:
			curve.add_point(v, Vector2.ZERO, Vector2.ZERO, starting_index + i)
			vertex_properties.add_point(starting_index + i)
		else:
			curve.add_point(v, Vector2.ZERO, Vector2.ZERO, starting_index)
			vertex_properties.add_point(starting_index)

	if update:
		_add_point_update()

func add_point_to_curve(position:Vector2, index:int = -1, update:bool = true):
	curve.add_point(position, Vector2.ZERO, Vector2.ZERO, index)
	vertex_properties.add_point(index)

	if update:
		_add_point_update()

func _add_point_update():
	set_as_dirty()
	emit_signal("points_modified")

	if Engine.editor_hint:
		property_list_changed_notify()

func _is_curve_index_in_range(i: int) -> bool:
	if curve.get_point_count() > i and i >= 0:
		return true
	return false


func _is_array_index_in_range(a: Array, i: int) -> bool:
	if a.size() > i and i >= 0:
		return true
	return false


func set_point_position(at_position: int, position: Vector2):
	if curve != null:
		if _is_curve_index_in_range(at_position):
			curve.set_point_position(at_position, position)
			set_as_dirty()
			emit_signal("points_modified")


func remove_point(idx: int):
	curve.remove_point(idx)
	if vertex_properties.remove_point(idx):
		set_as_dirty()
		emit_signal("points_modified")

		if Engine.editor_hint:
			property_list_changed_notify()


func resize_points(size: int):
	if size < 0:
		size = 0

	curve.resize(size)
	if vertex_properties.resize(size):
		set_as_dirty()

		if Engine.editor_hint:
			property_list_changed_notify()


########
# MISC #
########
func set_as_dirty():
	_dirty = true


func _handle_material_change():
	set_as_dirty()


func _convert_local_space_to_uv(point: Vector2, custom_size: Vector2 = Vector2(0, 0)):
	var pt: Vector2 = point
	var tex_size = Vector2(0, 0)
	if custom_size != Vector2(0, 0):
		tex_size = custom_size
	else:
		tex_size = shape_material.fill_texture.get_size()

	var size: Vector2 = tex_size  #* Vector2(1.0 / scale.x, 1.0 / scale.y)
	var rslt: Vector2 = Vector2(pt.x / size.x, pt.y / size.y)
	return rslt


func _to_vector3(vector: Vector2):
	return Vector3(vector.x, vector.y, 0)
