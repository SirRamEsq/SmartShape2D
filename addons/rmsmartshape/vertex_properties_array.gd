extends Reference
class_name RMS2D_VertexPropertiesArray

var properties:Array = []

#############
# INTERFACE #
#############
"""
Returns true if changed
"""
func remove_point(idx:int)->bool:
	assert(_is_array_index_in_range(properties, idx))
	properties.remove(idx)
	return true

"""
Returns true if changed
"""
func add_point(idx:int)->bool:
	var new_point_idx = -1
	if idx < 0:
		properties.push_back(RMS2D_VertexProperties.new())
		new_point_idx = properties.size() - 1
	else:
		assert(_is_array_index_in_range(properties, idx))
		properties.insert(idx, RMS2D_VertexProperties.new())
		new_point_idx = idx

	var old_idx = new_point_idx - 1
	properties[new_point_idx] = properties[old_idx].duplicate()
	return true

"""
Returns true if changed
"""
func resize(new_size:int):
	var old_size = properties.size()
	var delta = new_size - old_size
	if delta == 0:
		return false
	properties.resize(new_size)
	if delta > 0:
		for i in range(old_size-1, new_size, 1):
			properties[i] = RMS2D_VertexProperties.new()
	return true

"""
Returns true if changed
"""
func set_texture_idx(v:int, idx:int)->bool:
	if not _is_array_index_in_range(properties, idx):
		return false
	properties[idx].texture_idx = v
	return true

"""
Returns true if changed
"""
func set_flip(v:bool, idx:int)->bool:
	if not _is_array_index_in_range(properties, idx):
		return false
	properties[idx].flip = v
	return true

"""
Returns true if changed
"""
func set_width(v:float, idx:int)->bool:
	if not _is_array_index_in_range(properties, idx):
		return false
	properties[idx].width = v
	return true


#########
# GODOT #
#########
"""
Accepts either int or another instance of this class as a constructor argument
"""
func _init(arg):
	if typeof(arg) == TYPE_INT:
		__init_size(arg)
	#elif arg is RMS2D_VertexPropertiesArray:
	#	__init_class(arg)
	else:
		assert(false)

func __init_size(_size):
	for i in range(0, _size, 1):
		properties.push_back(RMS2D_VertexProperties.new())

func __init_class(other):
	for p in other.properties:
		properties.push_back(p.duplicate())

###########
# GETTERS #
###########
func get_texture_idx(idx:int)->int:
	if not _is_array_index_in_range(properties, idx):
		return -1
	return properties[idx].texture_idx

func get_flip(idx:int)->bool:
	if not _is_array_index_in_range(properties, idx):
		return false
	return properties[idx].flip

func get_width(idx:int)->float:
	if not _is_array_index_in_range(properties, idx):
		return 1.0
	return properties[idx].width


###########
# PRIVATE #
###########
func _is_array_index_in_range(a:Array, i:int)->bool:
	if a.size() > i and i >= 0:
		return true
	return false
