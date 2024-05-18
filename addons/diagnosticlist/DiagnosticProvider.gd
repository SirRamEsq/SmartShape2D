extends RefCounted
class_name DiagnosticList_DiagnosticProvider

const IGNORE_FILES: Array[String] = [
    ".gdignore",
    ".diagnostic_ignore",
]

## Triggered when new diagnostics for a file arrived.
signal on_publish_diagnostics(diagnostics: DiagnosticList_Diagnostic.Pack)

## Triggered when all outstanding diagnostics have been received.
signal on_diagnostics_finished

## Triggered when sources have changed and a diagnostic update is available.
signal on_diagnostics_available

## Triggered at the same time as on_publish_diagnostics but provides status information
signal on_update_progress(num_remaining: int, num_all: int)


class FileCache extends RefCounted:
    var content: String = ""
    var last_modified: int = -1


var _diagnostics: Array[DiagnosticList_Diagnostic] = []
var _client: DiagnosticList_LSPClient
var _script_paths: Array[String] = []
var _counts: Array[int] = [ 0, 0, 0, 0 ]
var _num_outstanding: int = 0
var _dirty: bool = true
var _refresh_time: int = 0
var _file_cache := {}  # Dict[String, FileCache]
var _additional_ignore_dirs: Array[String] = []


func _init(client: DiagnosticList_LSPClient) -> void:
    _client = client
    _client.on_publish_diagnostics.connect(_on_publish_diagnostics)
    _client.on_jsonrpc_error.connect(_on_jsonrpc_error)

    if Engine.is_editor_hint():
        var fs := EditorInterface.get_resource_filesystem()

        # Triggered when saving, removing and moving files.
        # Also triggers whenever the user is typing or saving in an external editor using LSP.
        fs.script_classes_updated.connect(_on_script_classes_updated)

        # Triggered when the Godot window receives focus and when moving or deleting files
        fs.sources_changed.connect(_on_sources_changed)


func is_updating() -> bool:
    return _num_outstanding > 0


func set_additional_ignore_dirs(dirs: Array[String]) -> void:
    _additional_ignore_dirs = dirs


## Refresh diagnostics for all scripts.
## Returns true on success or false when there are no updates available or when another update is
## still in progress.
func refresh_diagnostics(force: bool = false) -> bool:
    # NOTE: We always have to do a full update, because a change in one file can cause errors in
    # other files, e.g. renaming an identifier.

    # Still waiting for results from the last call
    if _num_outstanding > 0:
        _dirty = false  # Dirty will be reset anyway after update has been finished
        return false

    # Nothing changed -> Nothing to do
    if not force and not _dirty:
        return false

    var files_modified := refresh_file_list()

    # No files have actually been modified -> Nothing to do
    if not force and not files_modified:
        _dirty = false
        return false

    _diagnostics.clear()
    _counts = [ 0, 0, 0, 0 ]
    _num_outstanding = len(_script_paths)
    _refresh_time = Time.get_ticks_usec()

    if _num_outstanding > 0:
        for file in _script_paths:
            _client.update_diagnostics(file, _file_cache[file].content)
    else:
        call_deferred("_finish_update")

    # NOTE: Do not reset _dirty here, because it will be resetted anyway in _finish_update() after
    # all diagnostics have been received.
    return true


## Rescan the project for script files
## Returns true when there have been changes, otherwise false.
func refresh_file_list() -> bool:
    var ignore_dirs: Array[String] = []
    ignore_dirs.assign(_additional_ignore_dirs.duplicate())

    if ProjectSettings.get("debug/gdscript/warnings/exclude_addons"):
        ignore_dirs.push_back("res://addons" )

    _script_paths = _gather_scripts("res://", ignore_dirs)

    var modified: bool = false

    # Update cache
    for path in _script_paths:
        var cache: FileCache = _file_cache.get(path)
        var last_modified: int = FileAccess.get_modified_time(path)

        if not cache:
            cache = FileCache.new()
            _file_cache[path] = cache
            # The next condition will also inevitably be true

        if cache.last_modified != last_modified:
            cache.last_modified = last_modified
            cache.content = FileAccess.get_file_as_string(path)
            modified = true

    # One or more files were deleted
    if _file_cache.size() > _script_paths.size():
        modified = true

        # TODO: Could be more efficient, but happens not so often
        for path: String in _file_cache.keys():
            if not _script_paths.has(path):
                _file_cache.erase(path)

    return modified


## Get the amount of diagnostics of a given severity.
func get_diagnostic_count(severity: DiagnosticList_Diagnostic.Severity) -> int:
    return _counts[severity]


## Returns all diagnostics of the project
func get_diagnostics() -> Array[DiagnosticList_Diagnostic]:
    return _diagnostics.duplicate()


## Returns the amount of microseconds between requesting the last diagnostic update and the last
## diagnostic being delivered.
func get_refresh_time_usec() -> int:
    return _refresh_time


func are_diagnostics_available() -> bool:
    return _dirty


func get_lsp_client() -> DiagnosticList_LSPClient:
    return _client


func _finish_update() -> void:
    # NOTE: When parsing scripts using LSP, the script_classes_updated signal will be fired multiple
    # times by the engine without any actual changes.
    # Hence, to prevent false positive dirty flags, reset _dirty back to false when the diagnsotic
    # update is finished.
    # FIXME: It might happen that the user makes a change while diagnostics are still refreshing,
    # In this case, the dirty flag would still be resetted, even though it shouldn't.
    # This is essentially a tradeoff between efficiency and accuracy.
    # As I find this exact scenario unlikely to occur regularily, I prefer the more efficient
    # implementation of updating less often.
    _dirty = false

    _refresh_time = Time.get_ticks_usec() - _refresh_time
    on_diagnostics_finished.emit()


func _mark_dirty() -> void:
    if not _dirty:
        # If an update is currently in progress, don't do anything. _dirty will be reset anyway in
        # _finish_update().
        if _num_outstanding > 0:
            return

        _dirty = true
        on_diagnostics_available.emit()


func _on_sources_changed(_exist: bool) -> void:
    _mark_dirty()


func _on_script_classes_updated() -> void:
    # NOTE: When using an external editor over LSP, the engine will constantly emit the
    # script_classes_updated signal whenever the user is typing.
    # In those cases it is useless to perform an update, as nothing actually changed.
    # We also cannot safely determine when the user has saved a file except by comparing file
    # modification timestamps.
    #
    # However, whenever the Godot window receives focus, a sources_changed signal is fired.
    #
    # Hence, to prevent unnecessary amounts of updates, check whether the Godot window has focus and
    # if it doesn't, ignore the signal, as the user is likely typing in an external editor.
    #
    # When using the internal editor, script_classes_updated will only be fired upon saving.
    # Hence, when the signal arrives and the Godot window has focus, an update should be performed.
    if EditorInterface.get_base_control().get_window().has_focus():
        _mark_dirty()


func _on_publish_diagnostics(diagnostics: DiagnosticList_Diagnostic.Pack) -> void:
    # Ignore unexpected diagnostic updates
    if _num_outstanding == 0:
        _client.log_error("Received diagnostics without having them requested before")
        return

    _diagnostics.append_array(diagnostics.diagnostics)

    # Increase new diagnostic counts
    for diag in diagnostics.diagnostics:
        _counts[diag.severity] += 1

    on_publish_diagnostics.emit(diagnostics)

    _update_outstanding_counter()


func _on_jsonrpc_error(_error: Dictionary) -> void:
    # In case of error, it is likely something failed for a specific file.
    # To prevent the plugin from effectively freezing by waiting forever for results that will never
    # arrive, just update the counter as if diagnostics arrived.
    if _num_outstanding > 0:
        _update_outstanding_counter()


func _update_outstanding_counter() -> void:
    _num_outstanding -= 1
    on_update_progress.emit(_num_outstanding, len(_script_paths))

    if _num_outstanding == 0:
        _finish_update()


# TODO: Consider making ignore_dirs a set if there will ever be more than one entry
func _gather_scripts(searchpath: String, ignore_dirs: Array[String]) -> Array[String]:
    var root := DirAccess.open(searchpath)

    if not root:
        push_error("Failed to open directory: ", searchpath)

    var paths: Array[String] = []

    for ignore_file in IGNORE_FILES:
        if root.file_exists(ignore_file):
            return paths

    root.include_navigational = false
    root.list_dir_begin()

    var fname := root.get_next()

    var root_path := root.get_current_dir()

    while not fname.is_empty():
        var path := root_path.path_join(fname)

        if root.current_is_dir():
            if not ignore_dirs.has(path):
                paths.append_array(_gather_scripts(path, ignore_dirs))
        elif fname.ends_with(".gd"):
            paths.append(path)

        fname = root.get_next()

    root.list_dir_end()

    return paths
