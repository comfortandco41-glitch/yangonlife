extends Node
## Save Manager — JSON-based persistent save and load system
##
## Collects and distributes game state across Economy, Needs, Time, Career, and Player systems.

signal game_saved
signal game_loaded

const SAVE_PATH: String = "user://yangon_life_save.json"
const SAVE_VERSION: int = 1

## Checks if a save file currently exists
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Deletes the current save file if it exists
func delete_save() -> void:
	if not has_save():
		print_rich("[color=yellow][SaveManager] No save file exists to delete.[/color]")
		return
	var err: Error = DirAccess.remove_absolute(SAVE_PATH)
	if err == OK:
		print_rich("[color=green][SaveManager] Save file deleted successfully.[/color]")
	else:
		print_rich("[color=red][SaveManager] Failed to delete save file: %s (Error %d)[/color]" % [SAVE_PATH, err])

## Collects data from all subsystem managers and writes JSON save file
func save_game() -> bool:
	var economy_node := get_node_or_null("/root/EconomyManager")
	var needs_node := get_node_or_null("/root/NeedsManager")
	var time_node := get_node_or_null("/root/TimeManager")
	var career_node := get_node_or_null("/root/CareerManager")

	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"economy": economy_node.get_save_data() if economy_node and economy_node.has_method("get_save_data") else {},
		"needs": needs_node.get_save_data() if needs_node and needs_node.has_method("get_save_data") else {},
		"time": time_node.get_save_data() if time_node and time_node.has_method("get_save_data") else {},
		"career": career_node.get_save_data() if career_node and career_node.has_method("get_save_data") else {},
		"player": _collect_player_data()
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		var err := FileAccess.get_open_error()
		print_rich("[color=red][SaveManager] Failed to open save file for writing: %s (Error: %s)[/color]" % [SAVE_PATH, error_string(err)])
		return false

	var json_string := JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	print_rich("[color=green][SaveManager] Game saved successfully to %s[/color]" % SAVE_PATH)
	game_saved.emit()
	return true

## Reads JSON save file and distributes state to subsystem managers
func load_game() -> bool:
	if not has_save():
		print_rich("[color=yellow][SaveManager] Cannot load game: No save file found at %s[/color]" % SAVE_PATH)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		var err := FileAccess.get_open_error()
		print_rich("[color=red][SaveManager] Failed to open save file for reading: %s (Error: %s)[/color]" % [SAVE_PATH, error_string(err)])
		return false

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_err := json.parse(json_text)
	if parse_err != OK:
		print_rich("[color=red][SaveManager] JSON Parse Error at line %d: %s[/color]" % [json.get_error_line(), json.get_error_message()])
		return false

	var parsed_data: Variant = json.data
	if not (parsed_data is Dictionary):
		print_rich("[color=red][SaveManager] Save data format invalid: Root element is not a JSON object.[/color]")
		return false

	var data: Dictionary = parsed_data
	var version: int = int(data.get("version", 1))
	var timestamp: String = str(data.get("timestamp", "unknown"))
	print_rich("[color=cyan][SaveManager] Loading save version %d (Created: %s)[/color]" % [version, timestamp])

	var economy_node := get_node_or_null("/root/EconomyManager")
	if economy_node and economy_node.has_method("load_save_data") and data.has("economy") and data["economy"] is Dictionary:
		economy_node.load_save_data(data["economy"])

	var needs_node := get_node_or_null("/root/NeedsManager")
	if needs_node and needs_node.has_method("load_save_data") and data.has("needs") and data["needs"] is Dictionary:
		needs_node.load_save_data(data["needs"])

	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_method("load_save_data") and data.has("time") and data["time"] is Dictionary:
		time_node.load_save_data(data["time"])

	var career_node := get_node_or_null("/root/CareerManager")
	if career_node and career_node.has_method("load_save_data") and data.has("career") and data["career"] is Dictionary:
		career_node.load_save_data(data["career"])

	if data.has("player") and data["player"] is Dictionary:
		_distribute_player_data(data["player"])

	print_rich("[color=green][SaveManager] Game loaded successfully.[/color]")
	game_loaded.emit()
	return true

func _collect_player_data() -> Dictionary:
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var player := player_nodes[0]
		if player.has_method("get_save_data"):
			var res: Variant = player.call("get_save_data")
			if res is Dictionary:
				return res
		elif player is Node3D:
			var pos: Vector3 = (player as Node3D).global_position
			return {"position": [pos.x, pos.y, pos.z]}
	return {"position": [0.0, 0.0, 0.0]}

func _distribute_player_data(player_data: Dictionary) -> void:
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var player := player_nodes[0]
		if player.has_method("load_save_data"):
			player.call("load_save_data", player_data)
		elif player is Node3D and player_data.has("position"):
			var pos_array: Variant = player_data["position"]
			if pos_array is Array and pos_array.size() >= 3:
				(player as Node3D).global_position = Vector3(
					float(pos_array[0]),
					float(pos_array[1]),
					float(pos_array[2])
				)
