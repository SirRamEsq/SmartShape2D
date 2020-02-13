tool
extends Node2D
class_name RMSmartShape2D, "shape.png"

enum DIRECTION {
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
	FILL
}

signal on_dirty_update()

# Used to organize all requested meshes to be rendered by their texture
class MeshInfo:
	var texture:Texture=null
	var normal_texture:Texture=null
	var meshes:Array
	var direction:int

# Used to describe the welded quads that form the edge data
class QuadInfo:
	var control_point_index:int
	var direction:int
	var pt_a:Vector2
	var pt_b:Vector2
	var pt_c:Vector2
	var pt_d:Vector2
	var color:Color
	var tex:Texture
	var normal_tex:Texture
	var flip_texture:bool = false
	var calculated:bool = false
	var width_factor:float = 1.0

	func get_length():
		return (pt_d.distance_to(pt_a) + pt_c.distance_to(pt_b)) * 0.5

export (bool) var editor_debug = null setget _set_editor_debug
export (Curve2D) var curve:Curve2D = null setget _set_curve
export (bool) var closed_shape = false setget _set_close_shape
export (bool) var auto_update_collider = false setget _set_auto_update_collider
export (int, 1, 8) var tessellation_stages = 5 setget _set_tessellation_stages
export (bool) var use_global_space = false setget _set_use_global_space
export (NodePath) var collision_polygon_node
export (int, 1, 512) var collision_bake_interval = 20
export (bool) var draw_edges:bool = false setget _set_has_edge
export (bool) var mirror_angle:bool = true
export (bool) var flip_edges:bool = false setget _set_flip_edge
export (Array, int) var texture_indices=null setget _set_texture_indices
export (Array, bool) var texture_flip_indices=null setget _set_texture_flip_indices
export (Array, float, 0, 10) var width_indices=null setget _set_width_indices
export (Resource) var shape_material = preload("RMSmartShapeMaterial.gd").new() setget _set_material

# This will set true if it is time to rebake mesh, should prevent unnecessary
# mesh creation unless a change to a property deems it necessary
var _dirty:bool = true 	# might be able to remove and replace by using change in point_change_index

# For rendering fill and edges
var meshes:Array = Array()
var quads:Array
var point_change_index:int = 0

# Reduce clockwise check if points don't change
var is_clockwise:bool = false setget , are_points_clockwise
var _clockwise_point_change_index:int = -1


# Signals
signal points_modified

#########
# GODOT #
#########
func _init():
	if texture_indices == null:
		texture_indices = []
	if texture_flip_indices == null:
		texture_flip_indices = []
	if width_indices == null:
		width_indices = []
func _ready():
	if curve==null:
		curve = Curve2D.new()

func _process(delta):
	if not is_inside_tree():
		return
	_on_dirty_update()

func _enter_tree():
	pass

func _exit_tree():
	if shape_material != null:
		if ClassDB.class_has_signal("RMSmartShapeMaterial","changed"):
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
	var point_count = get_point_count()
	if closed_shape and get_point_position(0) != get_point_position(point_count - 1):
		add_point_to_curve(get_point_position(0))
		bake_mesh()
	elif not closed_shape and get_point_position(0) == get_point_position(point_count-1) and point_count > 2:
		remove_point(point_count-1)
		bake_mesh()

func _draw():
	if not is_inside_tree():
		return

	# Draw fill
	for mesh in meshes:
		if mesh != null and mesh.meshes.size() != 0 and mesh.texture != null and \
			mesh.direction == DIRECTION.FILL:
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# Draw Left and Right
	for mesh in meshes:
		if mesh != null and mesh.meshes.size() != 0 and mesh.texture != null and \
			(mesh.direction == DIRECTION.LEFT or mesh.direction == DIRECTION.RIGHT):
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# Draw Bottom
	for mesh in meshes:
		if mesh != null and mesh.meshes.size() != 0 and mesh.texture != null and \
			mesh.direction == DIRECTION.BOTTOM:
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# and Finally, Draw Top
	for mesh in meshes:
		if mesh != null and mesh.meshes.size() != 0 and mesh.texture != null and \
			mesh.direction == DIRECTION.TOP:
			for m in mesh.meshes:
				draw_mesh(m, mesh.texture, mesh.normal_texture)

	# Draw edge quads for debug purposes (ONLY IN EDITOR)
	if Engine.editor_hint and editor_debug:
		for q in quads:
			var t:QuadInfo = q
			draw_line(t.pt_a, t.pt_b, t.color)
			draw_line(t.pt_b, t.pt_c, t.color)
			draw_line(t.pt_c, t.pt_d, t.color)
			draw_line(t.pt_d, t.pt_a, t.color)

#####################
# SETTERS / GETTERS #
#####################
func _set_texture_indices(value:Array):
	texture_indices = value.duplicate()
	set_as_dirty()

func _set_texture_flip_indices(value:Array):
	texture_flip_indices = value.duplicate()
	set_as_dirty()

func _set_width_indices(value:Array):
	width_indices = value.duplicate()
	set_as_dirty()

func _set_tessellation_stages(value:int):
	tessellation_stages = value
	set_as_dirty()

func _set_material(value:RMSmartShapeMaterial):
	if shape_material != null and shape_material.is_connected("changed", self, "_handle_material_change"):
		shape_material.disconnect("changed", self, "_handle_material_change")

	shape_material = value
	if (shape_material != null):
		shape_material.connect("changed", self, "_handle_material_change")
	set_as_dirty()

func _set_close_shape(value):
	if curve.get_point_count() < 3:
		return
	closed_shape = value

	var first_point = curve.get_point_position(0)
	var final_point = curve.get_point_position(curve.get_point_count()-1)
	if closed_shape:
		# If not already closed, add a point to close the shape
		if first_point != final_point:
			add_point_to_curve(curve.get_point_position(0))
	else:
		# Remove final point if it matches the first
		if first_point == final_point:
			remove_point(curve.get_point_count()-1)

	set_as_dirty()

	if Engine.editor_hint:
		property_list_changed_notify()

func _set_auto_update_collider(value:bool):
	auto_update_collider = value
	if auto_update_collider:
		bake_collision()

func _set_curve(value:Curve2D):
	curve = value

	texture_indices.resize(curve.get_point_count())
	texture_flip_indices.resize(curve.get_point_count())
	width_indices.resize(curve.get_point_count())

	set_as_dirty()
	emit_signal("points_modified")

	if Engine.editor_hint:
		property_list_changed_notify()



######################
# SET/GET FOR ARRAYS #
######################
func set_point_width(width:float, at_position:int):
	if _is_array_index_in_range(width_indices, at_position):
		width_indices[at_position] = width

	point_change_index += 1
	set_as_dirty()
	emit_signal("points_modified")

	if Engine.editor_hint:
		property_list_changed_notify()

func get_point_width(at_position:int)->float:
	if _is_array_index_in_range(width_indices, at_position):
		return width_indices[at_position]
	return 0.0

func is_closed_shape()->bool:
	return closed_shape

func set_point_texture_index(index:int, at_position:int):
	if _is_array_index_in_range(texture_indices, at_position):
		texture_indices[at_position] = index

	point_change_index += 1
	set_as_dirty()
	emit_signal("points_modified")

	if Engine.editor_hint:
		property_list_changed_notify()

func get_point_texture_index(at_position:int):
	if _is_array_index_in_range(texture_indices, at_position):
		return texture_indices[at_position]
	return -1

func get_point_texture_flip(at_position:int)->bool:
	if _is_array_index_in_range(texture_flip_indices, at_position):
		return texture_flip_indices[at_position]
	return false

func set_point_texture_flip(flip:bool, at_position:int):
	if _is_array_index_in_range(texture_flip_indices, at_position):
		texture_flip_indices[at_position] = flip
		point_change_index += 1
		set_as_dirty()
		emit_signal("points_modified")
	if Engine.editor_hint:
		property_list_changed_notify()

######################
######################
######################

func set_point_in(idx:int, p:Vector2):
	if curve != null:
		curve.set_point_in(idx, p)
		set_as_dirty()
		emit_signal("points_modified")

func set_point_out(idx:int, p:Vector2):
	if curve != null:
		curve.set_point_out(idx, p)
		set_as_dirty()
		emit_signal("points_modified")

func get_point_in(idx:int)->Vector2:
	if curve != null:
		return curve.get_point_in(idx)
	return Vector2(0,0)

func get_point_out(idx:int)->Vector2:
	if curve != null:
		return curve.get_point_out(idx)
	return Vector2(0,0)

func get_closest_point(to_point:Vector2):
	if curve != null:
		return curve.get_closest_point(to_point)
	return null

func get_closest_offset(to_point:Vector2):
	if curve != null:
		return curve.get_closest_offset(to_point)
	return null

func _set_editor_debug(value:bool):
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

func get_point_position(at_position:int):
	if curve != null:
		if at_position < curve.get_point_count() and at_position >= 0:
			return curve.get_point_position(at_position)
	return null


############
# GEOMETRY #
############
func _add_mesh(mesh:ArrayMesh, texture:Texture, normal_texture:Texture, direction:int):
	var found:bool = false

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

func _add_uv_to_surface_tool(surface_tool:SurfaceTool, uv:Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)

func are_points_clockwise()->bool:
	if _clockwise_point_change_index == point_change_index:
		return is_clockwise

	var sum = 0.0
	var point_count = curve.get_point_count()
	for i in point_count:
		var pt = curve.get_point_position(i)
		var pt2 = curve.get_point_position((i+1) % point_count)
		sum += pt.cross(pt2)

	is_clockwise = sum > 0.0
	_clockwise_point_change_index = point_change_index
	return is_clockwise

func _weld_quads(quads:Array, custom_scale:float = 1.0):
	var _range
	if not closed_shape:
		_range = range(1,quads.size())
	else:
		_range = range(quads.size())

	for index in _range:
		# Skip the first and last vert if the shape isn't closed
		if (not closed_shape and (index == 0 or index == quads.size())):
			continue

		var previous_quad:QuadInfo = quads[(index-1) % quads.size()]
		var this_quad:QuadInfo = quads[index % quads.size()]

		var needed_length:float = 0.0
		if previous_quad.tex != null and this_quad.tex != null:
			needed_length = (previous_quad.tex.get_size().y +\
											 (this_quad.tex.get_size().y * this_quad.width_factor)) * 0.5

		var pt1 = (previous_quad.pt_d + this_quad.pt_a) * 0.5
		var pt2 = (previous_quad.pt_c + this_quad.pt_b) * 0.5

		var mid_point:Vector2 = (pt1 + pt2) * 0.5
		var half_line:Vector2 = (pt2 - mid_point).normalized() * needed_length * custom_scale * 0.5

		if half_line != Vector2.ZERO:
			pt2 = mid_point + half_line
			pt1 = mid_point - half_line

		this_quad.pt_a = pt1
		this_quad.pt_b = pt2
		previous_quad.pt_d = pt1
		previous_quad.pt_c = pt2

func _get_direction(point_1, point_2, top_tilt, bottom_tilt)->int:
	var v1:Vector2 = point_1
	var v2:Vector2 = point_2

	if use_global_space == true:
		v1 = get_global_transform().xform(point_1)
		v2 = get_global_transform().xform(point_2)

	var top_mid = 0.0
	var bottom_mid = PI

	var clockwise = are_points_clockwise()

	if clockwise == false:
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
		if clockwise == true:
			return DIRECTION.RIGHT
		else:
			return DIRECTION.LEFT
	else:
		if clockwise == true:
			return DIRECTION.LEFT
		else:
			return DIRECTION.RIGHT

func _fix_quads():
	# TODO: Why is this needed?
	# quads.resize(quads.size() - 1)

	var _range
	if closed_shape == false:
		_range = range(1,quads.size())
	else:
		_range = range(quads.size())

	# Weld quads if weld_edges is on
	if shape_material.weld_edges == true:
		_weld_quads(quads)

	var global_index = 0
	while(quads.size()>0):
		# Find start of sprite in control point list (change in direction is the key here)
		var index:int = global_index
		while quads.size()>0:
			var previous_quad:QuadInfo = quads[fmod(index - 1, quads.size())]
			var this_quad:QuadInfo = quads[fmod(index, quads.size())]

			if (index == 0 and closed_shape == false) or previous_quad.calculated == true or previous_quad.direction != this_quad.direction:
				break

			index = fmod(index - 1, quads.size())
			if index == 0:
				break

		# Calculate total length of the sprite run (change in direction, or change in texture is the key here)
		var length_index:int = index
		var total_length:float = 0.0
		var change_in_length:float = -1.0
		while quads.size()>0:
			var this_quad:QuadInfo = quads[fmod(length_index, quads.size())]
			var next_quad:QuadInfo = quads[fmod(length_index + 1, quads.size())]

			total_length += this_quad.get_length()

			if (length_index + 1 == quads.size() and closed_shape == false) or next_quad.direction != this_quad.direction or next_quad.tex != this_quad.tex or next_quad.flip_texture != this_quad.flip_texture:
				break

			length_index = fmod(length_index + 1, quads.size())
			if length_index == index:
				break

		# Iterate over the quads now until change in direction or texture or looped around
		var mesh_index:int = index
		var st:SurfaceTool = SurfaceTool.new()
		var tex:Texture = null
		var normal_tex:Texture = null
		var length:float = 0.0
		var mesh_direction:int

		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		while true:
			var quad_index:int = fmod(index, quads.size())
			var this_quad:QuadInfo = quads[fmod(quad_index, quads.size())]
			var next_quad:QuadInfo = quads[fmod(quad_index + 1, quads.size())]
			var section_length:float = this_quad.get_length()

			if tex == null:
				tex = quads[quad_index].tex
			if normal_tex == null:
				normal_tex = quads[quad_index].normal_tex

			if tex != null and change_in_length == -1.0:
				change_in_length = (round( total_length / tex.get_size().x ) * tex.get_size().x) / total_length
				#total_length += change_in_length

			# Adjust length
			#if change_in_length != 0.0 and total_length != 0.0:
				#section_length += (section_length / total_length) * change_in_length
			section_length = section_length * change_in_length
			if section_length == 0:
				section_length = tex.get_size().x

			this_quad.calculated = true

			st.add_color( Color.white )

			# A
			if tex != null:
				if this_quad.flip_texture == false:
					_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 0) )
				else:
					_add_uv_to_surface_tool(st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 0) )
			st.add_vertex( _to_vector3( this_quad.pt_a ) )

			# B
			if tex != null:
				if this_quad.flip_texture == false:
					_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 1) )
				else:
					_add_uv_to_surface_tool(st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 1) )
			st.add_vertex( _to_vector3( this_quad.pt_b ) )

			# C
			if tex != null:
				if this_quad.flip_texture == false:
					_add_uv_to_surface_tool(st, Vector2((length + section_length) / tex.get_size().x, 1) )
				else:
					_add_uv_to_surface_tool(st, Vector2((total_length * change_in_length - (section_length + length)) / tex.get_size().x, 1) )
			st.add_vertex( _to_vector3( this_quad.pt_c ) )

			# A
			if tex != null:
				if this_quad.flip_texture == false:
					_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 0) )
				else:
					_add_uv_to_surface_tool(st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 0) )
			st.add_vertex( _to_vector3( this_quad.pt_a ) )

			# C
			if tex != null:
				if this_quad.flip_texture == false:
					_add_uv_to_surface_tool(st, Vector2((length + section_length) / tex.get_size().x, 1) )
				else:
					_add_uv_to_surface_tool(st, Vector2((total_length * change_in_length - (length + section_length)) / tex.get_size().x, 1) )
			st.add_vertex( _to_vector3( this_quad.pt_c ) )

			# D
			if tex != null:
				if this_quad.flip_texture == false:
					_add_uv_to_surface_tool(st, Vector2((length + section_length) / tex.get_size().x, 0) )
				else:
					_add_uv_to_surface_tool(st, Vector2((total_length * change_in_length - (length + section_length)) / tex.get_size().x, 0) )
			st.add_vertex( _to_vector3( this_quad.pt_d ) )

			if (quad_index + 1 == quads.size() and closed_shape == false) or this_quad.tex != next_quad.tex or this_quad.direction != next_quad.direction or next_quad.flip_texture != this_quad.flip_texture or fmod(index + 1,quads.size()) == mesh_index:
				mesh_direction = this_quad.direction
				break

			length += section_length
			index += 1
		st.index()
		st.generate_normals()
		#st.generate_tangents()
		_add_mesh(st.commit(), tex, normal_tex, mesh_direction)

		global_index = fmod(index + 1, quads.size())

		if quads.size()>0:
			if quads[global_index].calculated or (global_index == 0 and not closed_shape):
				break
		else:
				break

func get_vertices()->Array:
	var verts = []
	for i in range(0, curve.get_point_count(), 1):
		verts.push_back(curve.get_point_position(i))
	return verts

func get_vertex_idx_from_tessellated_point(points, tess_points, tess_point_index)->int:
	var vertex_idx = -1
	var tess_idx = 0
	for i in range(0, tess_point_index, 1):
		var tess_point = tess_points[i]
		if tess_point == points[vertex_idx]:
			vertex_idx += 1
	return vertex_idx

func get_tessellated_points()->PoolVector2Array:
	# Point 0 will be the same on both the curve points and the vertecies
	# Point size - 1 will be the same on both the curve points and the vertecies
	var points = curve.tessellate(tessellation_stages)
	points[0] = curve.get_point_position(0)
	points[points.size()-1] = curve.get_point_position(curve.get_point_count()-1)
	return points

func _build_quads(quads:Array, custom_scale:float = 1.0, custom_offset:float = 0, custom_extends:float = 0.0):
	# The remainder of the code build up the edge quads
	var tex:Texture = null
	var tex_normal:Texture = null
	var tex_size:Vector2
	var tex_index:int = 0
	var points = get_tessellated_points()
	var curve_count = points.size()

	var top_tilt = shape_material.top_texture_tilt
	var bottom_tilt = shape_material.bottom_texture_tilt

	var is_clockwise:bool = are_points_clockwise()

	for curve_index in curve_count-1:
		var pt_index = fmod(curve_index, points.size())
		var pt2_index = fmod(curve_index + 1, points.size())
		#var property_index = get_vertex_idx_from_tessellated_point(curve.get_baked_points(), points, curve_index)
		var property_index = get_vertex_idx_from_tessellated_point(get_vertices(), points, curve_index)

		var pt = points[pt_index]
		var pt2 = points[pt2_index]

		var direction = DIRECTION.TOP
		if closed_shape:
			direction = _get_direction(pt, pt2, top_tilt, bottom_tilt)

		tex = null
		tex_normal = null
		if shape_material != null:
			var material_textures_diffuse = null
			var material_textures_normal = null
			match(direction):
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
					tex_index = abs(fmod(texture_indices[property_index], material_textures_diffuse.size()))
					if material_textures_diffuse.size() > tex_index:
						tex = material_textures_diffuse[tex_index]
					if material_textures_normal != null:
						if material_textures_normal.size() > tex_index:
							tex_normal = material_textures_normal[tex_index]

		if tex != null:
			tex_size = tex.get_size()

		var vtx:Vector2 = (pt2 - pt)
		vtx = Vector2(vtx.y, -vtx.x).normalized() * tex_size * 0.5

		var scale_in:float = 1
		var scale_out:float = 1

		if width_indices[property_index] != 0.0:
			scale_in = width_indices[property_index]
		#if width_indices[pt2_index] != 0.0:
			#scale_out = width_indices[pt2_index]

		if not are_points_clockwise():
			vtx *= -1

		if flip_edges:  # allow developer to override
			vtx *= -1

		var clr:Color = Color.white
		var vert_adj:Vector2 = vtx
		match(direction):
			DIRECTION.TOP:
				clr = Color.green
				vert_adj *= shape_material.top_offset
			DIRECTION.LEFT:
				clr = Color.yellow
				vert_adj *= shape_material.left_offset
			DIRECTION.RIGHT:
				clr = Color.red
				vert_adj *= shape_material.right_offset
			DIRECTION.BOTTOM:
				clr = Color.blue
				vert_adj *= shape_material.bottom_offset

		var offset = Vector2.ZERO
		if tex != null and custom_offset != 0.0:
			offset = vtx
			offset *= custom_offset

		if not closed_shape:
			if tex != null:
				if curve_index == 0:
					pt -= (pt2 - pt).normalized() * tex.get_size() * custom_extends
				if curve_index == curve_count - 2 and tex != null:
					pt2 -= (pt - pt2).normalized() * tex.get_size() * custom_extends

		var new_quad = QuadInfo.new()
		new_quad.pt_a = (pt + vtx * scale_in * custom_scale + vert_adj + offset)
		new_quad.pt_b = (pt - vtx * scale_in * custom_scale + vert_adj + offset)
		new_quad.pt_c = (pt2 - vtx * scale_out * custom_scale + vert_adj + offset)
		new_quad.pt_d = (pt2 + vtx * scale_out * custom_scale + vert_adj + offset)
		new_quad.color = clr
		new_quad.direction = direction
		new_quad.tex = tex
		new_quad.normal_tex = tex_normal
		new_quad.flip_texture = texture_flip_indices[property_index]
		new_quad.width_factor = width_indices[property_index]
		quads.push_back(new_quad)

func bake_collision():
	if collision_polygon_node == null or not is_inside_tree():
		return

	if has_node(collision_polygon_node):
		var col_polygon = get_node(collision_polygon_node)
		var points:PoolVector2Array = PoolVector2Array()
		if closed_shape == true:
			var old_interval = curve.bake_interval
			col_polygon.transform = transform
			col_polygon.scale = Vector2.ONE
			curve.bake_interval = collision_bake_interval

			curve.bake_interval = old_interval

			var curve_points = get_tessellated_points()
			for i in curve_points:
				points.push_back( col_polygon.get_global_transform().xform_inv( get_global_transform().xform(i) ))
		else:
			var collision_quads = Array()
			var collision_width = 1.0
			var collision_offset = 0.0
			var collision_extends = 1.0

			if shape_material != null:
				collision_width = shape_material.collision_width
				collision_offset = shape_material.collision_offset
				collision_extends = shape_material.collision_extends

			_build_quads(collision_quads, collision_width, collision_offset, collision_extends)
			_weld_quads(collision_quads, collision_width)

			for quad in collision_quads:
				points.push_back( col_polygon.get_global_transform().xform_inv( get_global_transform().xform(quad.pt_a)) )

			if not collision_quads.empty():
				points.push_back( col_polygon.get_global_transform().xform_inv( get_global_transform().xform(collision_quads[collision_quads.size()-1].pt_d)) )
				for quad_index in collision_quads.size():
					var quad = collision_quads[collision_quads.size() - 1 - quad_index]
					points.push_back( col_polygon.get_global_transform().xform_inv( get_global_transform().xform(quad.pt_c)) )
				points.push_back( col_polygon.get_global_transform().xform_inv( get_global_transform().xform(collision_quads[0].pt_b)) )

		col_polygon.polygon = points

func bake_mesh(force:bool = false):
	if not _dirty and not force:
		return
	# Clear Meshes
	for mesh in meshes:
		if mesh.meshes!=null:
			mesh.meshes.clear()
	meshes.resize(0)

	# Cant make a mesh without enough points
	var points = get_tessellated_points()
	var point_count = points.size()#curve.get_point_count()
	if (closed_shape and point_count < 3) or (not closed_shape and point_count < 2):
		return

	var fill_points:PoolVector2Array
	var is_clockwise:bool = are_points_clockwise()
	quads = Array()

	# Produce Fill Mesh
	if fill_points == null:
		fill_points = PoolVector2Array()

	fill_points.resize(point_count)
	for i in point_count:
		fill_points[i] = points[i]#curve.get_point_position(i)
	#fill_points = curve.get_baked_points()

	var fill_tris:PoolIntArray = Geometry.triangulate_polygon(fill_points)
	var st:SurfaceTool

	if closed_shape == true and shape_material.fill_texture != null:
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		for i in range(0, fill_tris.size() - 1, 3):
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv( points[fill_tris[i]] ) )
			st.add_vertex( Vector3( points[fill_tris[i]].x, points[fill_tris[i]].y, 0) )
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv( points[fill_tris[i+1]] ) )
			st.add_vertex( Vector3( points[fill_tris[i+1]].x, points[fill_tris[i+1]].y, 0) )
			st.add_color(Color.white)
			_add_uv_to_surface_tool(st, _convert_local_space_to_uv( points[fill_tris[i+2]] ) )
			st.add_vertex( Vector3( points[fill_tris[i+2]].x, points[fill_tris[i+2]].y, 0) )
		st.index()
		st.generate_normals()
		st.generate_tangents()
		_add_mesh(st.commit(), shape_material.fill_texture, shape_material.fill_texture_normal, DIRECTION.FILL)

	if closed_shape and not draw_edges:
		return

	# Build Edge Quads
	_build_quads(quads)

	_fix_quads()

#########
# CURVE #
#########
func add_point_to_curve(position:Vector2, at_position:int=-1):
	curve.add_point(position, Vector2.ZERO, Vector2.ZERO, at_position)
	# position '-1' appends to the list
	if at_position < 0:
		texture_indices.push_back(0)
		texture_flip_indices.push_back(false)
		width_indices.push_back(1.0)
	else:
		texture_indices.insert(at_position, texture_indices[at_position - 1])
		texture_flip_indices.insert(at_position, texture_flip_indices[at_position - 1])
		width_indices.insert(at_position, width_indices[at_position - 1])

	# If we're able to close the shape now
	if closed_shape and curve.get_point_count() == 3:
		fix_close_shape()
	set_as_dirty()
	emit_signal("points_modified")

	if Engine.editor_hint:
		property_list_changed_notify()

func _is_curve_index_in_range(i:int)->bool:
	if curve.get_point_count() > i and i >= 0:
		return true
	return false

func _is_array_index_in_range(a:Array, i:int)->bool:
	if a.size() > i and i >= 0:
		return true
	return false

func set_point_position(at_position:int, position:Vector2):
	if curve != null:
		if _is_curve_index_in_range(at_position):
			curve.set_point_position(at_position, position)
			point_change_index += 1
			set_as_dirty()
			emit_signal("points_modified")

func remove_point(at_position:int):
	curve.remove_point(at_position)
	if _is_array_index_in_range(width_indices, at_position):
		width_indices.remove(at_position)
	if _is_array_index_in_range(texture_indices, at_position):
		texture_indices.remove(at_position)
	if _is_array_index_in_range(texture_flip_indices, at_position):
		texture_flip_indices.remove(at_position)

	point_change_index += 1
	set_as_dirty()
	emit_signal("points_modified")

	if Engine.editor_hint:
		property_list_changed_notify()

func resize_points(size:int):
	if size < 0:
		size = 0

	curve.resize(size)
	width_indices.resize(size)
	texture_indices.resize(size)
	texture_flip_indices.reszie(size)

	point_change_index += 1
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

func _convert_local_space_to_uv(point:Vector2, custom_size:Vector2=Vector2(0,0)):
	var pt:Vector2 = point
	var tex_size = Vector2(0,0)
	if custom_size != Vector2(0,0):
		tex_size = custom_size
	else:
		tex_size = shape_material.fill_texture.get_size()

	var size:Vector2 = tex_size #* Vector2(1.0 / scale.x, 1.0 / scale.y)
	var rslt:Vector2 = Vector2(pt.x / size.x, pt.y / size.y)
	return rslt

func _to_vector3(vector:Vector2):
	return Vector3(vector.x, vector.y, 0)

