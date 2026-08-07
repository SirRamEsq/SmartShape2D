@tool
extends EditorPlugin

const panel_scene = preload("res://addons/diagnosticlist/Panel.tscn")

var _dock: DiagnosticList_Panel
var _client: DiagnosticList_LSPClient
var _provider: DiagnosticList_DiagnosticProvider


func _enter_tree() -> void:
    # Wait a moment until the LSP server started
    await get_tree().create_timer(1.0).timeout

    _client = DiagnosticList_LSPClient.new(self)
    _client.on_initialized.connect(_on_lsp_initialized)
    _client.connect_lsp()

    _dock = panel_scene.instantiate()
    _dock.ready.connect(func() -> void: _dock._plugin_ready())
    add_control_to_bottom_panel(_dock, "Diagnostics")

    DiagnosticList_Utils.log_debug("Plugin loaded")


func _exit_tree() -> void:
    remove_control_from_bottom_panel(_dock)
    _dock.free()
    _client.disconnect_lsp()
    DiagnosticList_Utils.log_debug("Plugin unloaded")


func _on_lsp_initialized() -> void:
    _provider = DiagnosticList_DiagnosticProvider.new(_client)
    _dock.start(_provider)
