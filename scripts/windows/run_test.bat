REM Must be called from project root folder
REM Godot must be in system path
godot -d -s --path %CD% addons/gut/gut_cmdln.gd -gtest=res://%1 -gmaximize -glog=2
