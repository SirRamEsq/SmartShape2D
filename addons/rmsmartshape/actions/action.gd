class_name SS2D_Action
extends RefCounted

## Base class for all plugin actions.
##
## UndoRedo system will call [method do] and [method undo].

# @virtual
## Returns string to be used as a name in editor History tab.
func get_name() -> String:
	return "UntitledAction"


# @virtual
## Do action here.
func do() -> void:
	pass


# @virtual
## Undo action here.
func undo() -> void:
	pass
