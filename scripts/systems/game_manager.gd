extends Node
## Global Game Manager for Yangon Life

signal game_paused
signal game_resumed

var is_paused: bool = false

func _ready() -> void:
	_register_input_actions()

func _register_input_actions() -> void:
	var key_map: Dictionary = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"jump": [KEY_SPACE],
		"interact": [KEY_E],
		"inventory": [KEY_I],
		"map": [KEY_M],
		"phone": [KEY_P],
		"pause": [KEY_ESCAPE],
		"enter_vehicle": [KEY_F],
	}
	for action_name: String in key_map:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		for keycode in key_map[action_name]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action_name, ev)

	# Mouse buttons for camera
	if not InputMap.has_action("camera_rotate"):
		InputMap.add_action("camera_rotate")
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("camera_rotate", ev)

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		game_paused.emit()
	else:
		game_resumed.emit()

func restart_scene() -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().reload_current_scene()
