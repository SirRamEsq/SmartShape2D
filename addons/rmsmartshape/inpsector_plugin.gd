extends EditorInspectorPlugin

var properties = []
var control = null

func can_handle(object):
	#if object is SS2D_NormalRange:
	#	return true
	if object is SS2D_NormalRange:
		#Connect
		var parms = [object]
		if object.changed.is_connected(_changed)==false:
			object.changed.connect(_changed, parms)
		return true
	else:
		#Disconnect
		if control != null:
			control = null
		
		if object.has_signal("changed"):
			if object.changed.is_connected(_changed):
				object.changed.disconnect(_changed)
		pass

	return false

# Called when the node enters the scene tree for the first time.
func _ready():
	print("loaded...")
	pass # Replace with function body.
	
func _changed(object):
	control._value_changed()
	pass

func parse_property(object, type, path, hint, hint_text, usage):
	if path=="edgeRendering":
		control = SS2D_NormalRangeEditorProperty.new()
		add_property_editor(" ", control)
		return true
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
