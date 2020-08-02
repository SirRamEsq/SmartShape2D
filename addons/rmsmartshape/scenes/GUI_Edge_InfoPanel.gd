tool
extends PanelContainer

export (NodePath) var p_lbl_idx

func set_indicies(a:Array):
	get_node(p_lbl_idx).text = "IDX: [%s, %s]" % [a[0], a[1]]
