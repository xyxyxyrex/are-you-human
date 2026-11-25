extends Node

const SAVE_VERSION: int = 1
const AUTOSAVE_PATH: String = "user://autosave.json"
const MANUAL_PATH: String = "user://save_0.json"

func save_atomic(path: String, data: Dictionary) -> Error:
	var payload: Dictionary = data.duplicate(true)
	payload["version"] = SAVE_VERSION

	var tmp_path: String = path + ".tmp"
	var f: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	var json_str: String = JSON.stringify(payload, "\t")
	if not f.store_string(json_str):
		f.close()
		return ERR_FILE_CANT_WRITE
	f.close()

	var abs_tmp: String = ProjectSettings.globalize_path(tmp_path)
	var abs_target: String = ProjectSettings.globalize_path(path)
	var abs_bak: String = ProjectSettings.globalize_path(path + ".bak")

	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(abs_bak)
		var bak_err: Error = DirAccess.rename_absolute(abs_target, abs_bak)
		if bak_err != OK:
			return bak_err

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(abs_target)
	return DirAccess.rename_absolute(abs_tmp, abs_target)

func load_save(path: String) -> Dictionary:
	var candidates: Array[String] = [path, path + ".bak"]
	for p: String in candidates:
		if not FileAccess.file_exists(p):
			continue
		var raw: String = FileAccess.get_file_as_string(p)
		if raw.is_empty():
			continue
		var parser := JSON.new()
		var err: Error = parser.parse(raw)
		if err != OK:
			continue
		var parsed: Variant = parser.data
		if parsed is Dictionary:
			var dict: Dictionary = parsed
			if not dict.has("version"):
				continue
			var v: int = int(dict["version"])
			if v > SAVE_VERSION or v < 1:
				continue
			dict["version"] = v
			return dict
	return {}

func clear_save(path: String) -> void:
	for suffix: String in ["", ".bak", ".tmp"]:
		var full: String = path + suffix
		if FileAccess.file_exists(full):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(full))
