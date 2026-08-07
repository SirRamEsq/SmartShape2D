extends RefCounted
class_name DiagnosticList_LSPClient

## Triggered when connected to the LS.
signal on_connected

## Triggered when LSP has been initialized
signal on_initialized

## Triggered when new diagnostics for a file arrived.
signal on_publish_diagnostics(diagnostics: DiagnosticList_Diagnostic.Pack)

## Triggered when the LSP server returns an unexpected JSON-RPC error
signal on_jsonrpc_error(error: Dictionary)


const TICK_INTERVAL_SECONDS_MIN: float = 0.05
const TICK_INTERVAL_SECONDS_MAX: float = 30.0

# Godot LS expects a leading "/" in URIs.
# On Windows, where absolute paths start with C:, it must be added manually.
var URI_PREFIX := "file:///" if OS.get_name() == "Windows" else "file://"

var _jsonrpc := JSONRPC.new()
var _client := StreamPeerTCP.new()
var _id: int = 0
var _timer: Timer

## Absolute project path reported by LS.
## Will be initialized when the LSP connection is initialized ( _initialize()) and changed by
## changeWorkspace events.
var _ls_project_path: String = ""

## Absolute path of the loaded project.
var _project_path: String = ProjectSettings.globalize_path("res://").simplify_path()


func _init(root: Node) -> void:
    # NOTE: Since this is a RefCounted, it does not have access to the tree, hence plugin.gd passes
    # the plugin root node.
    _timer = Timer.new()
    _timer.wait_time = TICK_INTERVAL_SECONDS_MIN
    _timer.autostart = false
    _timer.one_shot = false
    _timer.timeout.connect(_on_tick)
    root.add_child(_timer)


func disconnect_lsp() -> void:
    DiagnosticList_Utils.log_debug("Disconnecting from LSP")
    _timer.stop()
    _client.disconnect_from_host()


## Connect to the LSP server using host and port specified in the editor config.
func connect_lsp() -> bool:
    var settings := EditorInterface.get_editor_settings()
    var port: int = settings.get("network/language_server/remote_port")
    var host: String = settings.get("network/language_server/remote_host")
    return connect_lsp_at(host, port)


## Connect to the LSP server at the given host and port.
func connect_lsp_at(host: String, port: int) -> bool:
    DiagnosticList_Utils.log_debug("Connecting to LSP at %s:%d" % [ host, port ])
    var err := _client.connect_to_host(host, port)

    if err != OK:
        DiagnosticList_Utils.log_error("Failed to connect to LSP server: %s" % err)
        return false

    # Enable processing
    _id = 0
    _timer.start()
    _reset_tick_interval()

    return true


func is_lsp_connected() -> bool:
    return _client.get_status() == StreamPeerTCP.STATUS_CONNECTED


## Sends a didOpen/didClose notification request, which results in publishDiagnostics reply being sent.
## Expects "res_path" to be proper res:// uri.
func update_diagnostics(res_path: String, content: String) -> void:
    var uri := _res_path_to_lsp_uri(res_path)

    _send_notification("textDocument/didOpen", {
        "textDocument": {
            "uri": uri,
            "text": content,
            "languageId": "gdscript",  # Unused by Godot LSP
            "version": 0,  # Unused by Godot LSP
        }
    })

    # Technically, the Godot LS does nothing on didClose, but send it anyway in case it changes in the future.
    _send_notification("textDocument/didClose", {
        "textDocument": {
            "uri": uri
        }
    })


## Returns whether the root directory reported by the LS is the same as the project root.
## If there is a mismatch, the LSP client is very likely connected to a different Godot instance
## with a different project opened.
func lsp_root_matches_project_root() -> bool:
    return _ls_project_path == _project_path


func _reset_tick_interval() -> void:
    _timer.start(TICK_INTERVAL_SECONDS_MIN)


func _update_tick_interval() -> void:
    # Double the tick interval to gradiually reduce computation time when not in use.
    _timer.wait_time = minf(_timer.wait_time * 2, TICK_INTERVAL_SECONDS_MAX)


func _on_tick() -> void:
    if not _update_status():
        disconnect_lsp()
        return

    _update_tick_interval()

    while _client.get_available_bytes():
        DiagnosticList_Utils.log_debug("Bytes available: %d" % _client.get_available_bytes())
        var json := _read_data()

        if json:
            DiagnosticList_Utils.log_debug("Received message:\n%s" % json)

        _handle_response(json)
        _reset_tick_interval()  # Reset timer interval whenever data arrived as there will likely be more data coming


## Updates the current socket status and returns true when the main loop should continue.
func _update_status() -> bool:
    var last_status := _client.get_status()

    _client.poll()

    var status := _client.get_status()

    match status:
        StreamPeerTCP.STATUS_NONE:
            return false
        StreamPeerTCP.STATUS_ERROR:
            DiagnosticList_Utils.log_error("StreamPeerTCP error")
            return false
        StreamPeerTCP.STATUS_CONNECTING:
            pass
        StreamPeerTCP.STATUS_CONNECTED:
            # First time connected -> run initialization
            if last_status != status:
                DiagnosticList_Utils.log_debug("Connected to LSP")
                on_connected.emit()
                _initialize()

    return true


func _read_data() -> Dictionary:
    # NOTE:
    # At the moment, Godot only ever transmits headers with a single Content-Length field and
    # likewise expects headers with only one field (see gdscript_language_protocol.cpp, line 61).
    # Hence, the following also assumes there is only the Content-Length field in the header.
    # If Godot ever starts sending additional fields, this will break.

    var header := _read_header().strip_edges()
    var content_length := int(header.substr(len("Content-Length")))
    var content := _read_content(content_length)
    var json: Dictionary = JSON.parse_string(content)

    if not json:
        DiagnosticList_Utils.log_error("Failed to parse JSON: %s" % content)
        return {}

    return json


func _read_content(length: int) -> String:
    var data := _client.get_data(length)

    if data[0] != OK:
        DiagnosticList_Utils.log_error("Failed to read content: %s" % error_string(data[0]))
        return ""
    else:
        var buf: PackedByteArray = data[1]
        return buf.get_string_from_utf8()


func _read_header() -> String:
    DiagnosticList_Utils.log_debug("reading header")

    var buf := PackedByteArray()
    var char_r := "\r".unicode_at(0)
    var char_n := "\n".unicode_at(0)

    while true:
        var data := _client.get_data(1)

        if data[0] != OK:
            DiagnosticList_Utils.log_error("Failed to read header: %s" % error_string(data[0]))
            return ""
        else:
            buf.push_back(data[1][0])

        var bufsize := buf.size()

        if bufsize >= 4 \
                and buf[bufsize - 1] == char_n \
                and buf[bufsize - 2] == char_r \
                and buf[bufsize - 3] == char_n \
                and buf[bufsize - 4] == char_r:
            return buf.get_string_from_ascii()

    # This should never happen but the GDScript compiler complains "not all code paths return a value"
    return ""


func _handle_response(json: Dictionary) -> void:
    var method: String = json.get("method", "")

    match method:
        # Diagnostics received
        "textDocument/publishDiagnostics":
            on_publish_diagnostics.emit(_parse_diagnostics(json["params"]))
            return

        # Project path
        "gdscript_client/changeWorkspace":
            _ls_project_path = str(json["params"]["path"]).simplify_path()
            DiagnosticList_Utils.log_debug("Change Workspace: %s" % _ls_project_path)
            return

    # Initialization response
    if json.get("id") == 0:
        DiagnosticList_Utils.log_debug("LSP initialized")
        _send_notification("initialized", {})
        on_initialized.emit()
        return

    # JSON-RPC error
    if json.has("error"):
        var error: Dictionary = json["error"]
        DiagnosticList_Utils.log_error("JSON-RPC Error: %s" % error)
        DiagnosticList_Utils.log_error("This is likely a bug in the plugin. Consider submitting a bug report on GitHub.")
        on_jsonrpc_error.emit(error)


## Parses the diagnostic information according to the LSP specification.
## https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#publishDiagnosticsParams
func _parse_diagnostics(params: Dictionary) -> DiagnosticList_Diagnostic.Pack:
    var result := DiagnosticList_Diagnostic.Pack.new()
    result.res_uri = StringName(_lsp_uri_to_res_path(str(params["uri"])))

    var diagnostics: Array[Dictionary] = []
    diagnostics.assign(params["diagnostics"])

    for diag in diagnostics:
        var range_start: Dictionary = diag["range"]["start"]
        var entry := DiagnosticList_Diagnostic.new()
        entry.res_uri = result.res_uri
        entry.message = diag["message"]
        entry.severity = (int(diag["severity"]) - 1) as DiagnosticList_Diagnostic.Severity  # One-based in LSP, hence convert to the zero-based enum value
        entry.line_start = int(range_start["line"])
        entry.column_start = int(range_start["character"])
        result.diagnostics.append(entry)

    return result


func _send_request(method: String, params: Dictionary) -> int:
    _send(_jsonrpc.make_request(method, params, _id))
    _id += 1
    return _id - 1


func _send_notification(method: String, params: Dictionary) -> void:
    _send(_jsonrpc.make_notification(method, params))


func _send(json: Dictionary) -> void:
    var content := JSON.stringify(json, "", false)
    var content_bytes := content.to_utf8_buffer()
    var header := "Content-Length: %s\r\n\r\n" % len(content_bytes)
    var header_bytes := header.to_ascii_buffer()
    DiagnosticList_Utils.log_debug("Sending message (length: %s): %s" % [ len(content_bytes), content ])
    var err := _client.put_data(header_bytes + content_bytes)

    if err != OK:
        DiagnosticList_Utils.log_error("Failed to send: %s" % error_string(err))

    _reset_tick_interval()  # Reset the timer interval because we are expecting a response


func _initialize() -> void:
    # Comply with LSP, try to initialize root directory to the current project root.
    # Godot will likely ignore it and send a changeWorkspace event anyway.
    _ls_project_path = _project_path

    _send_request("initialize", {
        "processId": null,
        "rootPath": _ls_project_path,
        "rootUri": _res_path_to_lsp_uri("res://"),
        "capabilities": {
            "textDocument": {
                "publishDiagnostics": {},
            },
        },
    })


func _res_path_to_lsp_uri(res_path: String) -> String:
    # NOTE: No need to manually call uri_encode() as JSONRPC seems to do that automatically
    # TODO: Consider using the builtin parsing functionality of JSONRPC instead of doing it manually
    return URI_PREFIX + ProjectSettings.globalize_path(res_path).simplify_path()


func _lsp_uri_to_res_path(lsp_uri: String) -> String:
    return ProjectSettings.localize_path(lsp_uri.trim_prefix(URI_PREFIX).uri_decode())
