@echo OFF
REM Must be called from project root folder
start godot -d -s --path %cd% ./addons/gut/gut_cmdln.gd -gdir=res://gut/unit
