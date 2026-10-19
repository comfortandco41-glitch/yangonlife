class_name PauseMenuController
extends Control
## PauseMenuController — Game pause menu and settings overlay.
##
## Manages game pause state, resume with pointer capture, JSON save/load triggers,
## audio bus master volume attenuation, and player mouse sensitivity tuning.
## Toggled via the 'Escape' key.

signal menu_opened
signal menu_closed

var is_open: bool = false

# UI Node References
@onready var resume_button: Button = %ResumeButton if has_node("%ResumeButton") else find_child("ResumeButton", true, false)
@onready var save_button: Button = %SaveButton if has_node("%SaveButton") else find_child("SaveButton", true, false)
@onready var load_button: Button = %LoadButton if has_node("%LoadButton") else find_child("LoadButton", true, false)
@onready var restart_button: Button = %RestartButton if has_node("%RestartButton") else find_child("RestartButton", true, false)
@onready var volume_slider: HSlider = %VolumeSlider if has_node("%VolumeSlider") else find_child("VolumeSlider", true, false)
@onready var volume_val_label: Label = %VolumeValLabel if has_node("%VolumeValLabel") else find_child("VolumeValLabel", true, false)
@onready var sensitivity_slider: HSlider = %SensitivitySlider if has_node("%SensitivitySlider") else find_child("SensitivitySlider", true, false)
@onready var sensitivity_val_label: Label = %SensitivityValLabel if has_node("%SensitivityValLabel") else find_child("SensitivityValLabel", true, false)
@onready var toast_label: Label = %ToastLabel if has_node("%ToastLabel") else find_child("ToastLabel", true, false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false

	# Connect buttons
	if resume_button and not resume_button.pressed.is_connected(resume_game):
		resume_button.pressed.connect(resume_game)

	if save_button and not save_button.pressed.is_connected(save_game_action):
		save_button.pressed.connect(save_game_action)

	if load_button and not load_button.pressed.is_connected(load_game_action):
		load_button.pressed.connect(load_game_action)

	if restart_button and not restart_button.pressed.is_connected(restart_day_action):
		restart_button.pressed.connect(restart_day_action)

	# Connect sliders
	if volume_slider and not volume_slider.value_changed.is_connected(_on_volume_changed):
		volume_slider.value_changed.connect(_on_volume_changed)

	if sensitivity_slider and not sensitivity_slider.value_changed.is_connected(_on_sensitivity_changed):
		sensitivity_slider.value_changed.connect(_on_sensitivity_changed)

	# Connect to GameManager pause signals if available
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_signal("game_paused"):
			gm.connect("game_paused", _on_external_game_paused)
		if gm.has_signal("game_resumed"):
			gm.connect("game_resumed", _on_external_game_resumed)

	_sync_controls()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_open:
			resume_game()
			get_viewport().set_input_as_handled()
		else:
			# Only open if tree is not already handled by a sub-menu
			open_pause_menu()
			get_viewport().set_input_as_handled()

## Opens the pause menu, halts game simulation, and displays mouse cursor
func open_pause_menu() -> void:
	is_open = true
	visible = true
	get_tree().paused = true

	var gm := get_node_or_null("/root/GameManager")
	if gm and "is_paused" in gm:
		gm.is_paused = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_sync_controls()
	menu_opened.emit()

## Resumes tree, hides menu, and recaptures mouse cursor for 3D camera
func resume_game() -> void:
	is_open = false
	visible = false
	get_tree().paused = false

	var gm := get_node_or_null("/root/GameManager")
	if gm and "is_paused" in gm:
		gm.is_paused = false
		if gm.has_signal("game_resumed"):
			gm.game_resumed.emit()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_closed.emit()

## Toggles pause menu state
func toggle_pause_menu() -> void:
	if is_open:
		resume_game()
	else:
		open_pause_menu()

## Triggers JSON save game
func save_game_action() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	var success: bool = false
	if sm and sm.has_method("save_game"):
		success = sm.call("save_game")

	if success:
		show_toast("Game Saved! (ဂိမ်းသိမ်းဆည်းပြီးပါပြီ)", Color(0.2, 0.9, 0.3))
	else:
		show_toast("Failed to save game!", Color(0.9, 0.3, 0.3))

## Triggers JSON load game
func load_game_action() -> void:
	var sm := get_node_or_null("/root/SaveManager")
	if not sm:
		show_toast("SaveManager not available", Color(0.9, 0.3, 0.3))
		return

	if sm.has_method("has_save") and not sm.call("has_save"):
		show_toast("No save file found!", Color(0.9, 0.6, 0.2))
		return

	var success: bool = false
	if sm.has_method("load_game"):
		success = sm.call("load_game")

	if success:
		show_toast("Game Loaded! (ဂိမ်းပြန်လည်ဖွင့်ပြီးပါပြီ)", Color(0.2, 0.9, 0.3))
		_sync_controls()
	else:
		show_toast("Failed to load save file!", Color(0.9, 0.3, 0.3))

## Restarts the day by reloading current scene
func restart_day_action() -> void:
	get_tree().paused = false
	is_open = false

	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("restart_scene"):
		gm.call("restart_scene")
	else:
		get_tree().reload_current_scene()

func _on_volume_changed(val: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		if val <= 0.001:
			AudioServer.set_bus_mute(master_bus, true)
		else:
			AudioServer.set_bus_mute(master_bus, false)
			AudioServer.set_bus_volume_db(master_bus, linear_to_db(val))

	if volume_val_label:
		volume_val_label.text = "%d%%" % int(val * 100.0)

func _on_sensitivity_changed(val: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if "mouse_sensitivity" in p:
			p.mouse_sensitivity = val

	if sensitivity_val_label:
		sensitivity_val_label.text = "%.4f" % val

func _sync_controls() -> void:
	# Sync volume slider from AudioServer
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0 and volume_slider:
		var is_muted := AudioServer.is_bus_mute(master_bus)
		var current_linear: float = 0.0 if is_muted else db_to_linear(AudioServer.get_bus_volume_db(master_bus))
		volume_slider.value = clampf(current_linear, 0.0, 1.0)
		if volume_val_label:
			volume_val_label.text = "%d%%" % int(volume_slider.value * 100.0)

	# Sync mouse sensitivity slider from player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and sensitivity_slider:
		var p := players[0]
		if "mouse_sensitivity" in p:
			var sens: float = float(p.mouse_sensitivity)
			sensitivity_slider.value = clampf(sens, 0.001, 0.010)
			if sensitivity_val_label:
				sensitivity_val_label.text = "%.4f" % sensitivity_slider.value

func show_toast(msg: String, color: Color = Color(0.2, 0.9, 0.3)) -> void:
	if toast_label:
		toast_label.text = msg
		toast_label.add_theme_color_override("font_color", color)
		toast_label.visible = true
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if toast_label:
				toast_label.visible = false
		)

func _on_external_game_paused() -> void:
	if not is_open:
		is_open = true
		visible = true
		_sync_controls()

func _on_external_game_resumed() -> void:
	if is_open:
		is_open = false
		visible = false
