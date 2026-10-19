class_name StartScreenController
extends CanvasLayer
## StartScreenController — Browser Click-to-Play and pointer capture overlay.
##
## Provides a stylized introductory screen for Yangon Life (ရန်ကုန် ဘဝ),
## satisfying browser autoplay security by unlocking WebAudio and capturing
## the mouse cursor upon user interaction.

signal game_started

@onready var start_button: Button = %StartButton if has_node("%StartButton") else find_child("StartButton", true, false)
@onready var title_label: Label = %TitleLabel if has_node("%TitleLabel") else find_child("TitleLabel", true, false)
@onready var subtitle_label: Label = %SubtitleLabel if has_node("%SubtitleLabel") else find_child("SubtitleLabel", true, false)
@onready var instructions_card: PanelContainer = %InstructionsCard if has_node("%InstructionsCard") else find_child("InstructionsCard", true, false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50 # Render above gameplay and HUD

	if start_button and not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	# Ensure mouse is visible on start screen
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	# Clicking anywhere on the canvas or pressing Enter/Space starts the game if visible
	if visible and event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and (key_event.physical_keycode == KEY_ENTER or key_event.physical_keycode == KEY_KP_ENTER):
			start_game()
			get_viewport().set_input_as_handled()

func _on_start_button_pressed() -> void:
	start_game()

## Unlocks WebAudio, captures pointer, hides overlay, and begins gameplay
func start_game() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_unlock_web_audio()
	hide()
	print_rich("[color=green][StartScreen] Entered Yangon. Mouse captured, WebAudio unlocked.[/color]")
	game_started.emit()

func _unlock_web_audio() -> void:
	# Satisfies browser user gesture requirement for WebAudio AudioContext
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, false)
	var tree := get_tree()
	if tree and tree.root and tree.root.has_node("AudioManager"):
		var am = tree.root.get_node("AudioManager")
		if am.has_method("unlock_audio"):
			am.unlock_audio()
