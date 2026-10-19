class_name StartScreenController
extends CanvasLayer

const CharacterData = preload("res://scripts/systems/character_data.gd")

## StartScreenController — Browser Click-to-Play, Pointer Capture & Character Selection.
##
## Provides a rich introductory screen for Yangon Life (ရန်ကုန် ဘဝ),
## allows players to customize their citizen archetype from 32 retro character sprites,
## and satisfies browser WebAudio initialization requirements.

signal game_started

@onready var start_button: Button = %StartButton if has_node("%StartButton") else find_child("StartButton", true, false)
@onready var title_label: Label = %TitleLabel if has_node("%TitleLabel") else find_child("TitleLabel", true, false)
@onready var subtitle_label: Label = %SubtitleLabel if has_node("%SubtitleLabel") else find_child("SubtitleLabel", true, false)
@onready var instructions_card: PanelContainer = %InstructionsCard if has_node("%InstructionsCard") else find_child("InstructionsCard", true, false)

@onready var btn_prev_char: Button = %BtnPrevChar if has_node("%BtnPrevChar") else find_child("BtnPrevChar", true, false)
@onready var btn_next_char: Button = %BtnNextChar if has_node("%BtnNextChar") else find_child("BtnNextChar", true, false)
@onready var char_preview: TextureRect = %CharPreview if has_node("%CharPreview") else find_child("CharPreview", true, false)
@onready var char_name_edit: LineEdit = %CharNameEdit if has_node("%CharNameEdit") else find_child("CharNameEdit", true, false)
@onready var role_option_button: OptionButton = %RoleOptionButton if has_node("%RoleOptionButton") else find_child("RoleOptionButton", true, false)
@onready var char_desc_label: Label = %CharDescLabel if has_node("%CharDescLabel") else find_child("CharDescLabel", true, false)
@onready var char_bonus_label: Label = %CharBonusLabel if has_node("%CharBonusLabel") else find_child("CharBonusLabel", true, false)

var selected_character_index: int = 1
var selected_character_name: String = "Ko Thet"
var selected_character_role: String = "Novice Citizen"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50 # Render above gameplay and HUD

	if start_button and not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	_setup_character_selection()

	# Ensure mouse is visible on start screen for selection
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _setup_character_selection() -> void:
	if btn_prev_char and not btn_prev_char.pressed.is_connected(_on_prev_char):
		btn_prev_char.pressed.connect(_on_prev_char)
	if btn_next_char and not btn_next_char.pressed.is_connected(_on_next_char):
		btn_next_char.pressed.connect(_on_next_char)

	if char_name_edit and not char_name_edit.text_changed.is_connected(_on_name_changed):
		char_name_edit.text_changed.connect(_on_name_changed)

	if role_option_button:
		role_option_button.clear()
		for i in range(CharacterData.PRESETS.size()):
			var p: Dictionary = CharacterData.PRESETS[i]
			role_option_button.add_item("%s — %s" % [p.get("name", ""), p.get("role", "")], i)
		if not role_option_button.item_selected.is_connected(_on_role_selected):
			role_option_button.item_selected.connect(_on_role_selected)

	_refresh_character_display()

func _on_prev_char() -> void:
	selected_character_index -= 1
	if selected_character_index < 1:
		selected_character_index = CharacterData.TOTAL_CHARACTERS
	_refresh_character_display()

func _on_next_char() -> void:
	selected_character_index += 1
	if selected_character_index > CharacterData.TOTAL_CHARACTERS:
		selected_character_index = 1
	_refresh_character_display()

func _on_name_changed(new_name: String) -> void:
	if not new_name.is_empty():
		selected_character_name = new_name

func _on_role_selected(index: int) -> void:
	if index >= 0 and index < CharacterData.PRESETS.size():
		var p: Dictionary = CharacterData.PRESETS[index]
		selected_character_index = int(p.get("index", 1))
		selected_character_name = String(p.get("name", "Ko Thet"))
		selected_character_role = String(p.get("role", "Novice Citizen"))
		_refresh_character_display()

func _refresh_character_display() -> void:
	var portrait: AtlasTexture = CharacterData.get_character_portrait(selected_character_index)
	if char_preview and portrait:
		char_preview.texture = portrait

	var preset: Dictionary = CharacterData.get_preset_for_index(selected_character_index)
	if char_name_edit and (char_name_edit.text.is_empty() or char_name_edit.text.begins_with("Citizen")):
		char_name_edit.text = preset.get("name", "Ko Thet")
		selected_character_name = char_name_edit.text
	elif char_name_edit and not char_name_edit.has_focus():
		char_name_edit.text = selected_character_name

	selected_character_role = preset.get("role", "Yangon Resident")
	if char_desc_label:
		char_desc_label.text = preset.get("desc", "Exploring life in downtown Yangon.")
	if char_bonus_label:
		char_bonus_label.text = "Perk: %s" % preset.get("bonus", "Standard attributes")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and (key_event.physical_keycode == KEY_ENTER or key_event.physical_keycode == KEY_KP_ENTER):
			start_game()
			get_viewport().set_input_as_handled()

func _on_start_button_pressed() -> void:
	start_game()

## Unlocks WebAudio, applies selected character to player, hides overlay, and begins gameplay
func start_game() -> void:
	# Apply selected character to active Player
	var player_nodes := get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		var player := player_nodes[0]
		if player.has_method("apply_character"):
			if char_name_edit and not char_name_edit.text.is_empty():
				selected_character_name = char_name_edit.text
			player.call("apply_character", selected_character_index, selected_character_name, selected_character_role)

	# In isometric mode, mouse remains comfortably visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_unlock_web_audio()
	hide()
	print_rich("[color=green][StartScreen] Entered Yangon as %s (%s). Isometric controls active, WebAudio unlocked.[/color]" % [selected_character_name, selected_character_role])
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
