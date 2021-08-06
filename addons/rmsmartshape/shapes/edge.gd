tool
extends Reference
class_name SS2D_Edge

"""
An SS2D_Edge represents an edge that will be rendered
It contains
- A list of quads that should be rendered
- A Godot :Material that dictates how the edge should be rendered
"""

# What to encode in the color data (for use by shaders)
# COLORS will encode a diffuse value to offset the quads color by (currently only ever white)
# NORMALS will encode normal data in the colors to be unpacked by a shader later
enum COLOR_ENCODING {COLOR, NORMALS}

var quads: Array = []
var first_point_key: int = -1
var last_point_key: int = -1
var z_index: int = 0
var z_as_relative: bool = false
# If final point is connected to first point
var wrap_around: bool = false
var material: Material = null

static func different_render(q1: SS2D_Quad, q2: SS2D_Quad) -> bool:
	"""
	Will return true if the 2 quads must be drawn in two calls
	"""
	if q1.matches_quad(q2):
		return false
	return true

static func get_consecutive_quads_for_mesh(_quads: Array) -> Array:
	if _quads.empty():
		return []

	var quad_ranges = []
	var quad_range = []
	quad_range.push_back(_quads[0])
	for i in range(1, _quads.size(), 1):
		var quad_prev = _quads[i - 1]
		var quad = _quads[i]
		if different_render(quad, quad_prev):
			quad_ranges.push_back(quad_range)
			quad_range = [quad]
		else:
			quad_range.push_back(quad)

	quad_ranges.push_back(quad_range)
	return quad_ranges

"""
Will generate normals for a given quad
will interpolate with previous and next quads
"""
static func generate_normals_for_quad_interpolated(qp, q, qn):
	# Interpolation and normalization
	#First, consider everything to be a non corner
	var tg_a = (q.tg_a + qp.tg_d)
	var bn_a = (q.bn_a + qp.bn_d)

	var tg_b = (q.tg_b + qp.tg_c)
	var bn_b = (q.bn_b + qp.bn_c)

	var tg_c = (q.tg_c + qn.tg_b)
	var bn_c = (q.bn_c + qn.bn_b)

	var tg_d = (q.tg_d + qn.tg_a)
	var bn_d = (q.bn_d + qn.bn_a)

	#then, fix values for corner cases (and edge ends)
	if q.corner == q.CORNER.NONE:
		if qp.corner == q.CORNER.NONE:
			#check validity
			if (not q.pt_a.is_equal_approx(qp.pt_d)) or (not q.pt_b.is_equal_approx(qp.pt_c)):
				tg_a = q.tg_a
				tg_b = q.tg_b
				bn_a = q.bn_a
				bn_b = q.bn_b
		elif qp.corner == q.CORNER.INNER:
			tg_a = (-qp.bn_d)
			bn_a = (-qp.tg_d)
			tg_b = (q.tg_b - qp.bn_a)
			bn_b = (q.bn_b - qp.tg_a)
			#check validity
			if (not q.pt_a.is_equal_approx(qp.pt_d)) or (not q.pt_b.is_equal_approx(qp.pt_a)):
				tg_a = q.tg_a
				tg_b = q.tg_b
				bn_a = q.bn_a
				bn_b = q.bn_b
		elif qp.corner == q.CORNER.OUTER:
			tg_a = (q.tg_a + qp.bn_c)
			bn_a = (q.bn_a - qp.tg_c)
			tg_b = (qp.bn_b)
			bn_b = (-qp.tg_b)
			#check validity
			if (not q.pt_a.is_equal_approx(qp.pt_c)) or (not q.pt_b.is_equal_approx(qp.pt_b)):
				tg_a = q.tg_a
				tg_b = q.tg_b
				bn_a = q.bn_a
				bn_b = q.bn_b
		if qn.corner == q.CORNER.NONE:
			#check validity
			if (not q.pt_c.is_equal_approx(qn.pt_b)) or (not q.pt_d.is_equal_approx(qn.pt_a)):
				tg_c = q.tg_c
				tg_d = q.tg_d
				bn_c = q.bn_c
				bn_d = q.bn_d
		elif qn.corner == q.CORNER.INNER:
			tg_d = (-qn.tg_d)
			bn_d = (qn.bn_d)
			tg_c = (q.tg_c - qn.tg_c)
			bn_c = (q.bn_c + qn.bn_c)
			#check validity
			if (not q.pt_c.is_equal_approx(qn.pt_c)) or (not q.pt_d.is_equal_approx(qn.pt_d)):
				tg_c = q.tg_c
				tg_d = q.tg_d
				bn_c = q.bn_c
				bn_d = q.bn_d
		elif qn.corner == q.CORNER.OUTER:
			tg_c = (qn.tg_b)
			bn_c = (qn.bn_b)
			#check validity
			if (not q.pt_c.is_equal_approx(qn.pt_b)) or (not q.pt_d.is_equal_approx(qn.pt_a)):
				tg_c = q.tg_c
				tg_d = q.tg_d
				bn_c = q.bn_c
				bn_d = q.bn_d

	elif q.corner == q.CORNER.INNER:
		#common
		tg_d = q.tg_d
		bn_d = q.bn_d
		tg_b = (q.tg_b)
		bn_b = (q.bn_b)
		#previous
		tg_c = (q.tg_c - qp.tg_c)
		bn_c = (q.bn_c + qp.bn_c)
		#next
		tg_a = (q.tg_a - qn.bn_b)
		bn_a = (q.bn_a - qn.tg_b)
		#check validity
		if qp.corner != qp.CORNER.NONE or (not q.pt_c.is_equal_approx(qp.pt_c)) or (not q.pt_d.is_equal_approx(qp.pt_d)):
			tg_c = q.tg_c
			bn_c = q.bn_c
		if qn.corner != qp.CORNER.NONE or (not q.pt_a.is_equal_approx(qn.pt_b)) or (not q.pt_d.is_equal_approx(qn.pt_a)):
			tg_a = q.tg_a
			bn_a = q.bn_a

	elif q.corner == q.CORNER.OUTER:
		tg_d = q.tg_d
		bn_d = q.bn_d
		tg_b = (q.tg_b)
		bn_b = (q.bn_b)
		#previous
		tg_a = (q.tg_a + qp.tg_d)
		bn_a = (q.bn_a + qp.bn_d)
		#qn
		tg_c = (q.tg_c - qn.bn_a)
		bn_c = (q.bn_c + qn.tg_a)
		#check validity
		if qp.corner != qp.CORNER.NONE or (not q.pt_a.is_equal_approx(qp.pt_d)) or (not q.pt_b.is_equal_approx(qp.pt_c)):
			tg_a = q.tg_a
			bn_a = q.bn_a
		if qn.corner != qp.CORNER.NONE or (not q.pt_b.is_equal_approx(qn.pt_b)) or (not q.pt_c.is_equal_approx(qn.pt_a)):
			tg_c = q.tg_c
			bn_c = q.bn_c

	if q.flip_texture:
		bn_a = -bn_a;
		bn_b = -bn_b;
		bn_c = -bn_c;
		bn_d = -bn_d;

	#Normalize the values
	var half_vector = Vector2.ONE * 0.5
	tg_a = tg_a.normalized()*0.5 + half_vector
	tg_b = tg_b.normalized()*0.5 + half_vector
	tg_c = tg_c.normalized()*0.5 + half_vector
	tg_d = tg_d.normalized()*0.5 + half_vector

	bn_a = bn_a.normalized()*0.5 + half_vector
	bn_b = bn_b.normalized()*0.5 + half_vector
	bn_c = bn_c.normalized()*0.5 + half_vector
	bn_d = bn_d.normalized()*0.5 + half_vector

	var normal_pt_a = Color(tg_a.x, tg_a.y, bn_a.x, bn_a.y)
	var normal_pt_b = Color(tg_b.x, tg_b.y, bn_b.x, bn_b.y)
	var normal_pt_c = Color(tg_c.x, tg_c.y, bn_c.x, bn_c.y)
	var normal_pt_d = Color(tg_d.x, tg_d.y, bn_d.x, bn_d.y)

	return [normal_pt_a, normal_pt_b, normal_pt_c, normal_pt_d]


static func generate_array_mesh_from_quad_sequence(_quads: Array, wrap_around: bool, color_encoding:int) -> ArrayMesh:
	"""
	Assumes each quad in the sequence is of the same render type
	same textures, values, etc...
	quads passed in as an argument should have been generated by get_consecutive_quads_for_mesh
	"""
	if _quads.empty():
		return ArrayMesh.new()

	var total_length: float = 0.0
	for q in _quads:
		total_length += q.get_length_average()
	if total_length == 0.0:
		return ArrayMesh.new()

	var first_quad = _quads[0]
	var tex: Texture = first_quad.texture
	# The change in length required to apply to each quad
	# to make the textures begin and end at the start and end of each texture
	var change_in_length: float = -1.0
	if tex != null:
		# How many times the texture is repeated
		var texture_reps = round(total_length / tex.get_size().x)
		# Length required to display all the reps with the texture's full width
		var texture_full_length = texture_reps * tex.get_size().x
		# How much each quad's texture must be offset to make up the difference in full length vs total length
		change_in_length = (texture_full_length / total_length)

	if first_quad.fit_texture == SS2D_Material_Edge.FITMODE.CROP:
		change_in_length = 1.0

	var length_elapsed: float = 0.0
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in _quads:
		q.update_tangents()
	for i in _quads.size():
		var q = _quads[i]
		var section_length: float = q.get_length_average() * change_in_length
		var highest_value: float = max(q.get_height_left(), q.get_height_right())
		# When welding and using different widths, quads can look a little weird
		# This is because they are no longer parallelograms
		# This is a tough problem to solve
		# See http://reedbeta.com/blog/quadrilateral-interpolation-part-1/
		var uv_a = Vector2(0, 0)
		var uv_b = Vector2(0, 1)
		var uv_c = Vector2(1, 1)
		var uv_d = Vector2(1, 0)
		# If we have a valid texture and this quad isn't a corner
		if tex != null and q.corner == q.CORNER.NONE:
			var x_left = (length_elapsed) / tex.get_size().x
			var x_right = (length_elapsed + section_length) / tex.get_size().x
			uv_a.x = x_left
			uv_b.x = x_left
			uv_c.x = x_right
			uv_d.x = x_right
		if q.flip_texture:
			var t = uv_a
			uv_a = uv_b
			uv_b = t
			t = uv_c
			uv_c = uv_d
			uv_d = t

		var color_a = q.color
		var color_b = q.color
		var color_c = q.color
		var color_d = q.color

		if color_encoding == COLOR_ENCODING.NORMALS:
			var next = _quads[wrapi(i + 1, 0, _quads.size())]
			var prev = _quads[wrapi(i - 1, 0, _quads.size())]

			var normals = generate_normals_for_quad_interpolated(next, q, prev)
			color_a = normals[0]
			color_b = normals[1]
			color_c = normals[2]
			color_d = normals[3]

		# A
		_add_uv_to_surface_tool(st, uv_a)
		st.add_color(color_a)
		st.add_vertex(SS2D_Common_Functions.to_vector3(q.pt_a))

		# B
		_add_uv_to_surface_tool(st, uv_b)
		st.add_color(color_b)
		st.add_vertex(SS2D_Common_Functions.to_vector3(q.pt_b))

		# C
		_add_uv_to_surface_tool(st, uv_c)
		st.add_color(color_c)
		st.add_vertex(SS2D_Common_Functions.to_vector3(q.pt_c))

		# A
		_add_uv_to_surface_tool(st, uv_a)
		st.add_color(color_a)
		st.add_vertex(SS2D_Common_Functions.to_vector3(q.pt_a))

		# C
		_add_uv_to_surface_tool(st, uv_c)
		st.add_color(color_c)
		st.add_vertex(SS2D_Common_Functions.to_vector3(q.pt_c))

		# D
		_add_uv_to_surface_tool(st, uv_d)
		st.add_color(color_d)
		st.add_vertex(SS2D_Common_Functions.to_vector3(q.pt_d))

		length_elapsed += section_length

	st.index()
	st.generate_normals()
	return st.commit()

func get_meshes(color_encoding:int) -> Array:
	"""
	Returns an array of SS2D_Mesh
	# Get Arrays of consecutive quads with the same mesh data
	# For each array
	## Generate Mesh Data from the quad
	"""

	var consecutive_quad_arrays = get_consecutive_quads_for_mesh(quads)
	#print("Arrays: %s" % consecutive_quad_arrays.size())
	var meshes = []
	for consecutive_quads in consecutive_quad_arrays:
		if consecutive_quads.empty():
			continue
		var st: SurfaceTool = SurfaceTool.new()
		var array_mesh: ArrayMesh = generate_array_mesh_from_quad_sequence(
			consecutive_quads, wrap_around, color_encoding
		)
		var tex: Texture = consecutive_quads[0].texture
		var tex_normal: Texture = consecutive_quads[0].texture_normal
		var flip = consecutive_quads[0].flip_texture
		var transform = Transform2D()
		var mesh_data = SS2D_Mesh.new(tex, tex_normal, flip, transform, [array_mesh], material)
		mesh_data.z_index = z_index
		mesh_data.z_as_relative = z_as_relative
		meshes.push_back(mesh_data)

	return meshes


static func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)
