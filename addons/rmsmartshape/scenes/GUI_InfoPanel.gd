tool
extends PanelContainer

export (NodePath) var p_lbl_idx
export (NodePath) var p_lbl_tex
export (NodePath) var p_lbl_width
export (NodePath) var p_lbl_flip

func set_idx(i:int):
	get_node(p_lbl_idx).text = "IDX: %s" % i

func set_texture_idx(i:int):
	get_node(p_lbl_tex).text = "Texture: %s" % i

func set_width(f:float):
	get_node(p_lbl_width).text = "Width: %s" % f

func set_flip(b:bool):
	get_node(p_lbl_flip).text = "Flip: %s" % b
