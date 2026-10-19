extends Node
# Global Game Manager and Autoload for Yangon Frontline

enum Team {
	NONE = 0,
	MILITARY = 1,
	PDF = 2
}

# Current local player faction preference
var player_faction: int = Team.PDF
var is_game_paused: bool = false

func _ready() -> void:
	_register_input_actions()

func _register_input_actions() -> void:
	# Ensure all required FPS input actions exist with standard defaults
	var key_mappings = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"reload": [KEY_R],
		"restart_mission": [KEY_F5],
		"pause": [KEY_ESCAPE]
	}

	for action_name in key_mappings:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for keycode in key_mappings[action_name]:
			var event = InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action_name, event)

	# Mouse buttons
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var fire_ev = InputEventMouseButton.new()
		fire_ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", fire_ev)

	if not InputMap.has_action("aim_down_sights"):
		InputMap.add_action("aim_down_sights")
		var ads_ev = InputEventMouseButton.new()
		ads_ev.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("aim_down_sights", ads_ev)

func restart_current_scene() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
