extends RefCounted
class_name DiagnosticList_Settings


const BASE_SETTING_PATH = "addons/diagnostic_list/"
const SETTING_AUTO_REFRESH = BASE_SETTING_PATH + "auto_refresh"


static func set_auto_refresh(on: bool) -> void:
    _set_setting(SETTING_AUTO_REFRESH, on)


static func get_auto_refresh() -> bool:
    return ProjectSettings.get_setting(SETTING_AUTO_REFRESH, true) as bool


static func _set_setting(name: String, value: Variant) -> void:
    ProjectSettings.set_setting(name, value)
    ProjectSettings.set_as_internal(name, true)
    ProjectSettings.save()
