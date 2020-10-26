REM Must be called from project root folder
REM Godot must be in system path
godot -d -s --path %CD% addons/gut/gut_cmdln.gd -gdir=res://gut -gmaximize
