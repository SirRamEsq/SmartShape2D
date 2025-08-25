extends RefCounted
class_name SS2D_CollisionGen

# NOTE: Use JOIN_MITER for all transformations because it keeps the corners as they are, which is fast and accurate.


## Controls width of generated polygon
@export var collision_size: float = 32

## Controls offset of generated polygon
@export var collision_offset: float = 0.0


## Generates a collision polygon intended for open polygons.
## May return the input point array unmodified or a new array.
func generate_open(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 2:
		return PackedVector2Array()

	var offset := collision_offset - collision_size / 2

	if is_equal_approx(offset, 0):
		return points

	# Geometry2D.offset_polygon() cannot be used to apply collision_offset because it
	# interprets the given points as closed polygon and may also change the start/end points, which
	# leads to various issues and is difficult to resolve.
	points = SS2D_CollisionGen.simple_offset_open_polygon_miter(points, offset)

	return Geometry2D.offset_polyline(points, collision_size / 2, Geometry2D.JOIN_MITER, Geometry2D.END_BUTT).front()


## Generates a collision polygon intended for closed polygons.
## May return the input point array unmodified or a new array.
func generate_filled(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 2:
		return PackedVector2Array()

	if is_equal_approx(collision_offset, 0):
		return points
	return Geometry2D.offset_polygon(points, collision_offset, Geometry2D.JOIN_MITER).front()


## Generates a hollow collision polygon intended for closed shapes.
## Use [method generate_collision_points_fast_open] for open shapes.
func generate_hollow(points: PackedVector2Array) -> PackedVector2Array:
	# 1) Generate an outer and an inner offset using offset_polygon().
	# 2) Reverse one array (in this case `outer`) to go along one array, then transition to the other
	# and return in the opposite direction back to the starting point.
	# 3) offset_polygon() may change start and end points from the original input, so search for the
	# closest point in `inner` to the first `outer` point and use that as transition point.
	#
	#    0__________1               0/6__________5
	#    / ________ \  outer          /\________ \
	#   / /2      3\ \               / /0/6    1\ \
	# 5/ /1  inner 4\ \2     ->    1/ /5        2\ \4
	#  \ \          / /             \ \          / /
	#   \ \0______5/ /               \ \4______3/ /
	#    \__________/                 \__________/
	#    4          3                 2          3

	if points.size() <= 2:
		return PackedVector2Array()

	var outer_offset := collision_offset + collision_size / 2
	var inner_offset := collision_offset - collision_size / 2
	var outer: PackedVector2Array
	var inner: PackedVector2Array = points

	if not is_equal_approx(inner_offset, 0):
		inner = Geometry2D.offset_polygon(points, inner_offset, Geometry2D.JOIN_MITER).front()

	if not is_equal_approx(outer_offset, 0):
		outer = Geometry2D.offset_polygon(points, outer_offset, Geometry2D.JOIN_MITER).front()
	else:
		# Make a copy so we don't modify the input array which may lead to unexpected behavior, e.g.
		# when the input is get_point_array().get_tesselated_points().
		outer = PackedVector2Array(points)

	outer.reverse()

	var closest_idx := 0
	var closest_dist: float = inner[0].distance_squared_to(outer[0])

	for i in range(1, inner.size()):
		var dist := inner[i].distance_squared_to(outer[0])
		if dist < closest_dist:
			closest_dist = dist
			closest_idx = i

	outer.push_back(outer[0])

	if closest_idx == 0:
		outer.append_array(inner)
	else:
		outer.append_array(inner.slice(closest_idx))
		outer.append_array(inner.slice(0, closest_idx))
		outer.push_back(inner[closest_idx])

	return outer


## Legacy method for generating collision polygons.
## Uses the edge generation algorithm for retrieving the shape outlines.
## Much slower than other functions (~0.3ms vs ~0.05ms in the collisions.tscn example).
func generate_legacy(shape: SS2D_Shape) -> PackedVector2Array:
	var points := PackedVector2Array()
	var num_points: int = shape._points.get_point_count()

	if num_points < 2:
		return points

	var is_closed := shape._points.is_shape_closed()
	var csize: float = 1.0 if is_closed else collision_size
	var indices := PackedInt32Array(range(num_points))
	var edge_data := SS2D_IndexMap.new(indices, null)
	var edge: SS2D_Edge = shape._build_edge_with_material(edge_data, collision_offset - 1.0, csize)
	shape._weld_quad_array(edge.quads, false)

	if is_closed:
		var first_quad: SS2D_Quad = edge.quads[0]
		var last_quad: SS2D_Quad = edge.quads.back()
		SS2D_Shape.weld_quads(last_quad, first_quad)

	if not edge.quads.is_empty():
		# Top edge (typically point A unless corner quad)
		for quad in edge.quads:
			if quad.corner == SS2D_Quad.CORNER.NONE:
				points.push_back(quad.pt_a)
			elif quad.corner == SS2D_Quad.CORNER.OUTER:
				points.push_back(quad.pt_d)
			elif quad.corner == SS2D_Quad.CORNER.INNER:
				pass

		if not is_closed:
			# Right Edge (point d, the first or final quad will never be a corner)
			points.push_back(edge.quads[edge.quads.size() - 1].pt_d)

			# Bottom Edge (typically point c)
			for quad_index in edge.quads.size():
				var quad: SS2D_Quad = edge.quads[edge.quads.size() - 1 - quad_index]
				if quad.corner == SS2D_Quad.CORNER.NONE:
					points.push_back(quad.pt_c)
				elif quad.corner == SS2D_Quad.CORNER.OUTER:
					pass
				elif quad.corner == SS2D_Quad.CORNER.INNER:
					points.push_back(quad.pt_b)

			# Left Edge (point b)
			points.push_back(edge.quads[0].pt_b)
	return points


## This is a simple implementation for offseting (inflate/deflate) open polylines but without
## intersection resolution.
## Geometry2D.offset_polygon() always interprets the input as closed polygon, which leads to various
## issues with open shapes, which is the reason why this function exists.
static func simple_offset_open_polygon_miter(points: PackedVector2Array, offset: float) -> PackedVector2Array:
	if points.size() < 2 or is_zero_approx(offset):
		return PackedVector2Array()

	#                   top
	#            P o_____o_____
	#              /     |     \
	#             /      |      \
	#         b2 o       |d      \
	#           /  .     |     .  \
	#          /     .   |   .     \
	#         /        . o .        \
	#        /          /b\          \
	#       /          /   \          \
	#      /      \   /     \          \
	#     / ab_orth\ /       \          \
	#    /          /         \          \
	#   /          /ab       bc\          \
	#  /          /             \          \
	#   .        /               \        .
	#     .     /                 \     .
	#       .  /                   \  .
	#         o                     o
	#         a                     c

	var new_points := PackedVector2Array()
	new_points.resize(points.size() * 2)  # Allocate maximum and reduce later.

	var a := points[0]
	var b := points[1]
	var ab := b - a
	var ab_orth := ab.orthogonal().normalized()
	new_points[0] = points[0] + ab_orth * offset
	var out_i := 1
	const miter_threshold := 0.5

	for i in range(1, points.size() - 1):
		var c := points[i + 1]
		var bc := c - b
		var bc_orth := bc.orthogonal().normalized()
		var dnorm := (ab_orth + bc_orth).normalized()
		var d := dnorm * offset
		var miter_denom := maxf(dnorm.dot(ab_orth), 1e-6)
		var clockwise: bool = (sign(offset) * ab_orth.dot(bc)) < 0

		if clockwise and miter_denom < miter_threshold:
			# Miter length exceeds threshold -> cap it manually or it will create large peaks.
			# The cap will be placed `offset` pixels away from b.
			#
			# 1) We consider the triangle `b2`, `top` and `P`.
			# `b2` and `top` are known as well as their directions towards `P` (`ab`, `d_orth`).
			# `P` is the point where `b2 + t * ab` and `top + u * d_orth` intersect.
			#
			#     b2 + t * ab  =  top + u * d_orth  =  P
			#
			# We get a linear system with two variables `t` and `u` but we only need to know one.
			#
			# 2) Transform equation into matrix form
			#     t * ab - u * d_orth  =  top - b2
			#
			#             A          X  =    B
			#     ⎛ab.x  -d_orth.x⎞ ⎛t⎞ = ⎛rhs.x⎞
			#     ⎝ab.y  -d_orth.y⎠ ⎝u⎠   ⎝rhs.y⎠
			var top := b + d
			var d_orth := dnorm.orthogonal()
			var b2 := b + ab_orth * offset
			var rhs := top - b2

			# 3) Resolve for `u` using Cramer's rule
			#
			#      det A_2        ab.x * rhs.y - ab.y * rhs.x
			# u = --------- = ------------------------------------
			#       det A      ab.x * -d_orth.y + d_orth.x * ab.y
			var det_a2 := ab.x * rhs.y - ab.y * rhs.x
			var det := ab.x * -d_orth.y - -d_orth.x * ab.y
			var u := det_a2 / det

			# 4) Construct corner points
			var cap_half_length := u * d_orth  # = P - top
			new_points[out_i] = top + cap_half_length
			new_points[out_i + 1] = top - cap_half_length
			out_i += 2
		else:
			new_points[out_i] = b + d / miter_denom
			out_i += 1

		ab = bc
		ab_orth = bc_orth
		a = b
		b = c

	new_points[out_i] = points[-1] + (points[-1] - points[-2]).orthogonal().normalized() * offset
	out_i += 1
	new_points.resize(out_i)

	return new_points
