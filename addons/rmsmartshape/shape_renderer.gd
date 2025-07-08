extends RefCounted
class_name SS2D_Renderer

var _shape: SS2D_Shape
var _render_parent: RID
var _render_nodes: Array[RID] = []


func _init(shape: SS2D_Shape) -> void:
	_shape = shape
	_render_parent = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_visibility_layer(_render_parent, 0xFFFFFFFF)  # Let all layers pass through
	RenderingServer.canvas_item_set_parent(_render_parent, _shape.get_canvas_item())
	# NOTE: Light mask is not needed for the parent because it renders nothing itself


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for node in _render_nodes:
			RenderingServer.free_rid(node)
		RenderingServer.free_rid(_render_parent)


func _setup_render_nodes(size: int) -> void:
	var delta := size - _render_nodes.size()

	# Fewer children than needed
	if delta > 0:
		for i in delta:
			var item := RenderingServer.canvas_item_create()
			RenderingServer.canvas_item_set_parent(item, _render_parent)
			_render_nodes.push_back(item)

	# More children than needed
	elif delta < 0:
		for i in absi(delta):
			RenderingServer.free_rid(_render_nodes[-1])
			_render_nodes.pop_back()


func _update_canvas_item_properties(item: RID, mesh: SS2D_Mesh) -> void:
	# TODO: These should be included in the edge material
	RenderingServer.canvas_item_set_visibility_layer(item, _shape.visibility_layer)
	RenderingServer.canvas_item_set_light_mask(item, _shape.light_mask)

	RenderingServer.canvas_item_set_material(item, mesh.material.get_rid() if mesh.material else RID())
	RenderingServer.canvas_item_set_z_index(item, mesh.z_index)
	RenderingServer.canvas_item_set_z_as_relative_to_parent(item, mesh.z_as_relative)
	RenderingServer.canvas_item_set_draw_behind_parent(item, mesh.show_behind_parent)

	if mesh.force_no_tiling:
		RenderingServer.canvas_item_set_default_texture_repeat(item, RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_DISABLED)
	else:
		# Force texture repeat because there is no reason to not repeat edges
		# TODO: Support mirrored repeat by adding an edge material property. for repeat method
		RenderingServer.canvas_item_set_default_texture_repeat(item, RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_ENABLED)

	RenderingServer.canvas_item_clear(item)

	if mesh.mesh and mesh.texture:
		RenderingServer.canvas_item_add_mesh(item, mesh.mesh.get_rid(), Transform2D(), Color.WHITE, mesh.texture.get_rid())


func render(meshes: Array[SS2D_Mesh]) -> void:
	_setup_render_nodes(meshes.size())

	for i in meshes.size():
		_update_canvas_item_properties(_render_nodes[i], meshes[i])
