@tool
extends Control
class_name DiagnosticList_Panel

class DiagnosticSeveritySettings extends RefCounted:
    var text: String
    var icon: Texture2D
    var color: Color

    func _init(text_: String, icon_id: StringName, color_id: StringName) -> void:
        self.text = text_
        self.icon = EditorInterface.get_editor_theme().get_icon(icon_id, &"EditorIcons")
        self.color = EditorInterface.get_editor_theme().get_color(color_id, &"Editor")


@onready var _btn_refresh_errors: Button = %"btn_refresh_errors"
@onready var _error_list_tree: Tree = %"error_tree_list"
@onready var _cb_auto_refresh: CheckBox = %"cb_auto_refresh"
@onready var _cb_group_by_file: CheckBox = %"cb_group_by_file"
@onready var _label_refresh_time: Label = %"label_refresh_time"
@onready var _multiple_instances_alert: AcceptDialog = %"multiple_instances_alert"

# This array will be filled according to each severity type to allow direct indexing
@onready var _filter_buttons: Array[Button] = [
    %"btn_filter_errors",
    %"btn_filter_warnings",
    %"btn_filter_infos",
    %"btn_filter_hints",
]

# This array will be filled according to each severity type to allow direct indexing
@onready var _severity_settings: Array[DiagnosticSeveritySettings] = [
    DiagnosticSeveritySettings.new("Error", &"StatusError", &"error_color"),
    DiagnosticSeveritySettings.new("Warning", &"StatusWarning", &"warning_color"),
    DiagnosticSeveritySettings.new("Info", &"Popup", &"font_color"),
    DiagnosticSeveritySettings.new("Hint", &"Info", &"font_color"),
]

@onready var _script_icon: Texture2D = get_theme_icon(&"Script", &"EditorIcons")

var _provider: DiagnosticList_DiagnosticProvider


## Alternative to _ready(). This will be called by plugin.gd to ensure the code in here only runs
## when this script is loaded as part of the plugin and not while editing the scene.
func _plugin_ready() -> void:
    for i in len(_filter_buttons):
        var btn: Button = _filter_buttons[i]
        var severity := _severity_settings[i]
        btn.icon = severity.icon

    # These kinds of severities do not exist yet in Godot LSP, so hide them for now.
    _filter_buttons[DiagnosticList_Diagnostic.Severity.Info].hide()
    _filter_buttons[DiagnosticList_Diagnostic.Severity.Hint].hide()

    _cb_auto_refresh.button_pressed = DiagnosticList_Settings.get_auto_refresh()

    _error_list_tree.columns = 3
    _error_list_tree.set_column_title(0, "Message")
    _error_list_tree.set_column_title(1, "File")
    _error_list_tree.set_column_title(2, "Line")
    _error_list_tree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
    _error_list_tree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
    _error_list_tree.set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_LEFT)

    var line_column_size := _error_list_tree.get_theme_font("font").get_string_size(
        "Line 0000", HORIZONTAL_ALIGNMENT_LEFT, -1, _error_list_tree.get_theme_font_size("font_size"))

    _error_list_tree.set_column_custom_minimum_width(0, 0)
    _error_list_tree.set_column_custom_minimum_width(1, 0)
    _error_list_tree.set_column_custom_minimum_width(2, int(line_column_size.x))

    _error_list_tree.set_column_expand(0, true)
    _error_list_tree.set_column_expand(1, true)
    _error_list_tree.set_column_expand(2, false)
    _error_list_tree.set_column_clip_content(0, true)
    _error_list_tree.set_column_clip_content(1, true)
    _error_list_tree.set_column_clip_content(2, false)
    _error_list_tree.set_column_expand_ratio(0, 4)

    _multiple_instances_alert.add_button("More Information", true, "https://github.com/mphe/godot-diagnostic-list#does-not-work-correctly-with-multiple-godot-instances")
    _multiple_instances_alert.custom_action.connect(func(action: StringName) -> void: OS.shell_open(action))
    _multiple_instances_alert.visible = false


## Called by plugin.gd when the LSPClient is ready
func start(provider: DiagnosticList_DiagnosticProvider) -> void:
    _provider = provider

    # Now that it is safe to do stuff, connect all the signals
    _provider.on_diagnostics_finished.connect(_on_diagnostics_finished)
    _provider.on_update_progress.connect(_on_update_progress)

    _btn_refresh_errors.pressed.connect(_on_force_refresh)
    _cb_group_by_file.toggled.connect(_on_group_by_file_toggled)
    _cb_auto_refresh.toggled.connect(_on_auto_refresh_toggled)
    _error_list_tree.item_activated.connect(_on_item_activated)

    for btn in _filter_buttons:
        btn.toggled.connect(_on_filter_toggled)

    # Start checking
    _set_status_string("", false)
    _start_stop_auto_refresh()

    # If connected to a LS of a different Godot instance, show a warning
    if provider.get_lsp_client().get_project_path() != ProjectSettings.globalize_path("res://").simplify_path():
        _multiple_instances_alert.popup_centered()


func refresh() -> void:
    # NOTE: This list is sorted by file name as LSP publishes diagnostics per file
    # This is important as the group-by-file implementation relies on it.
    var diagnostics := _provider.get_diagnostics()
    var group_by_file := _cb_group_by_file.button_pressed

    if not group_by_file:
        diagnostics.sort_custom(_sort_by_severity)

    # Show refresh time
    _set_status_string("Up-to-date", true)

    # Clear tree
    _error_list_tree.clear()
    _error_list_tree.create_item()

    # Create diagnostics
    var last_uri: StringName
    var parent: TreeItem = null

    for diag in diagnostics:
        if not _filter_buttons[diag.severity].button_pressed:
            continue

        # If grouping by file, create header entries if necessary
        if group_by_file and diag.res_uri != last_uri:
            last_uri = diag.res_uri
            parent = _error_list_tree.create_item()
            parent.set_text(0, diag.res_uri)
            parent.set_icon(0, _script_icon)
            parent.set_metadata(0, diag)

        _create_entry(diag, parent)

    # Update diagnostic counts
    for i in len(_filter_buttons):
        _filter_buttons[i].text = str(_provider.get_diagnostic_count(i))


func _set_status_string(text: String, with_last_time: bool) -> void:
    if with_last_time:
        _label_refresh_time.text = "%s\n%.2f s" % [ text, _provider.get_refresh_time_usec() / 1000000.0 ]
    else:
        _label_refresh_time.text = text


func _sort_by_severity(a: DiagnosticList_Diagnostic, b: DiagnosticList_Diagnostic) -> bool:
    if a.severity == b.severity:
        return a.res_uri < b.res_uri
    return a.severity < b.severity


func _create_entry(diag: DiagnosticList_Diagnostic, parent: TreeItem) -> void:
    var entry: TreeItem = _error_list_tree.create_item(parent)
    var severity_setting := _severity_settings[diag.severity]
    # entry.set_custom_color(0, theme.color)
    entry.set_text(0, diag.message)
    entry.set_icon(0, severity_setting.icon)
    entry.set_text(1, diag.get_filename())
    entry.set_tooltip_text(1, diag.res_uri)
    # entry.set_text(2, "Line " + str(diag.line_start))
    entry.set_text(2, str(diag.line_start + 1))
    entry.set_metadata(0, diag)  # Meta data is used in _on_item_activated to open the respective script


func _update_diagnostics(force: bool) -> void:
    if _provider.is_updating() or _provider.refresh_diagnostics(force):
        _set_status_string("Updating...", false)
    else:
        _set_status_string("Up-to-date", true)


func _start_stop_auto_refresh() -> void:
    if _cb_auto_refresh.button_pressed:
        visibility_changed.connect(_on_auto_update)
        _provider.on_diagnostics_available.connect(_on_auto_update)
        _on_auto_update()  # Also trigger an update immediately
    else:
        visibility_changed.disconnect(_on_auto_update)
        _provider.on_diagnostics_available.disconnect(_on_auto_update)


func _on_item_activated() -> void:
    var selected: TreeItem = _error_list_tree.get_selected()
    var diagnostic: DiagnosticList_Diagnostic = selected.get_metadata(0)

    # NOTE: Lines and columns are zero-based in LSP, but Godot expects one-based values
    EditorInterface.edit_script(load(str(diagnostic.res_uri)), diagnostic.line_start + 1, diagnostic.column_start + 1)

    if not EditorInterface.get_editor_settings().get("text_editor/external/use_external_editor"):
        EditorInterface.set_main_screen_editor("Script")


func _on_force_refresh() -> void:
    _update_diagnostics(true)


func _on_auto_refresh_toggled(toggled_on: bool) -> void:
    DiagnosticList_Settings.set_auto_refresh(toggled_on)
    _start_stop_auto_refresh()


func _on_auto_update() -> void:
    if is_visible_in_tree():
        _update_diagnostics(false)


func _on_update_progress(num_remaining: int, num_all: int) -> void:
    _set_status_string("Updating...\n(%d/%d)" % [ num_all - num_remaining, num_all ], false)


func _on_diagnostics_finished() -> void:
    refresh()

func _on_filter_toggled(_toggled_on: bool) -> void:
    refresh()

func _on_group_by_file_toggled(_toggled_on: bool) -> void:
    refresh()
