class_name StartScreenController
extends CanvasLayer

const CharacterData = preload("res://scripts/systems/character_data.gd")

## StartScreenController — 3D Ball Avatar Customizer, Photo Upload & Game Launcher.
##
## Allows players to customize their 3D ball citizen with custom colors,
## upload their own photo/texture to wrap around the ball, customize their citizen name,
## and unlocks WebAudio upon entering the expansive city of Yangon.

signal game_started

@onready var start_button: Button = %StartButton if has_node("%StartButton") else find_child("StartButton", true, false)
@onready var title_label: Label = %TitleLabel if has_node("%TitleLabel") else find_child("TitleLabel", true, false)
@onready var subtitle_label: Label = %SubtitleLabel if has_node("%SubtitleLabel") else find_child("SubtitleLabel", true, false)
@onready var instructions_card: PanelContainer = %InstructionsCard if has_node("%InstructionsCard") else find_child("InstructionsCard", true, false)

@onready var btn_prev_char: Button = find_child("BtnPrevChar", true, false)
@onready var btn_next_char: Button = find_child("BtnNextChar", true, false)
@onready var char_preview: TextureRect = find_child("CharPreview", true, false)
@onready var char_name_edit: LineEdit = find_child("CharNameEdit", true, false)
@onready var role_option_button: OptionButton = find_child("RoleOptionButton", true, false)
@onready var char_desc_label: Label = find_child("CharDescLabel", true, false)
@onready var char_bonus_label: Label = find_child("CharBonusLabel", true, false)

@onready var ball_preview: TextureRect = find_child("BallPreview", true, false)
@onready var color_picker_btn: ColorPickerButton = find_child("ColorPickerBtn", true, false)
@onready var btn_upload_photo: Button = find_child("BtnUploadPhoto", true, false)
@onready var file_dialog: FileDialog = find_child("PhotoFileDialog", true, false)

var selected_character_index: int = 1
var selected_character_name: String = "Ko Thet"
var selected_character_role: String = "Novice Citizen"
var selected_ball_color: Color = Color(0.98, 0.72, 0.15)
var selected_photo_path: String = ""

const PRESET_COLORS: Array[Dictionary] = [
	{"name": "Gold (ရွှေ)", "color": Color(0.98, 0.72, 0.15)},
	{"name": "Ruby (ပတ္တမြား)", "color": Color(0.88, 0.12, 0.25)},
	{"name": "Jade (ကျောက်စိမ်း)", "color": Color(0.12, 0.68, 0.35)},
	{"name": "Royal Blue (အပြာ)", "color": Color(0.18, 0.45, 0.88)},
	{"name": "Sunset (လိမ္မော်)", "color": Color(1.0, 0.42, 0.15)},
	{"name": "Amethyst (ခရမ်း)", "color": Color(0.62, 0.25, 0.75)},
	{"name": "Pearl (ပုလဲဖြူ)", "color": Color(0.96, 0.96, 0.96)},
	{"name": "Onyx (နက်မှောင်)", "color": Color(0.18, 0.18, 0.20)}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50 # Render above gameplay and HUD

	if start_button and not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)

	_setup_ball_customizer()
	_setup_character_selection()

	# Keep mouse cursor comfortably visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _setup_ball_customizer() -> void:
	# Connect color swatch buttons
	for i in range(PRESET_COLORS.size()):
		var btn := find_child("ColorSwatch%d" % i, true, false) as Button
		if btn:
			var col: Color = PRESET_COLORS[i]["color"]
			btn.pressed.connect(func():
				set_ball_color(col)
			)

	if color_picker_btn:
		color_picker_btn.color = selected_ball_color
		color_picker_btn.color_changed.connect(set_ball_color)

	if btn_upload_photo:
		btn_upload_photo.pressed.connect(_on_upload_photo_pressed)

	if file_dialog:
		file_dialog.file_selected.connect(_on_photo_file_selected)

	# Check if custom photo already exists on disk
	if FileAccess.file_exists("user://ball_custom_photo.png"):
		_load_custom_photo("user://ball_custom_photo.png")
	else:
		_refresh_ball_preview()

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

func set_ball_color(col: Color) -> void:
	selected_ball_color = col
	if color_picker_btn:
		color_picker_btn.color = col
	_refresh_ball_preview()

func _on_upload_photo_pressed() -> void:
	if file_dialog:
		file_dialog.popup_centered(Vector2i(600, 400))

func _on_photo_file_selected(path: String) -> void:
	_load_custom_photo(path)

func _load_custom_photo(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var img := Image.load_from_file(path)
	if img:
		# Save copy to user cache
		if path != "user://ball_custom_photo.png":
			img.save_png("user://ball_custom_photo.png")
		selected_photo_path = "user://ball_custom_photo.png"
		var tex := ImageTexture.create_from_image(img)
		if ball_preview:
			ball_preview.texture = tex
		if char_preview:
			char_preview.texture = tex

func _refresh_ball_preview() -> void:
	if not selected_photo_path.is_empty():
		return
	# Generate a smooth radial gradient texture for the ball preview
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(32, 32)
	for y in range(64):
		for x in range(64):
			var dist := (Vector2(x, y) - center).length()
			if dist <= 30.0:
				var light_factor := 1.0 - (dist / 30.0) * 0.5
				var c := Color(
					selected_ball_color.r * light_factor,
					selected_ball_color.g * light_factor,
					selected_ball_color.b * light_factor,
					1.0
				)
				img.set_pixel(x, y, c)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex := ImageTexture.create_from_image(img)
	if ball_preview:
		ball_preview.texture = tex
	if char_preview:
		char_preview.texture = tex

func _on_prev_char() -> void:
	selected_character_index -= 1
	if selected_character_index < 1:
		selected_character_index = PRESET_COLORS.size()
	set_ball_color(PRESET_COLORS[selected_character_index - 1]["color"])
	_refresh_character_display()

func _on_next_char() -> void:
	selected_character_index += 1
	if selected_character_index > PRESET_COLORS.size():
		selected_character_index = 1
	set_ball_color(PRESET_COLORS[selected_character_index - 1]["color"])
	_refresh_character_display()

func _on_name_changed(new_name: String) -> void:
	if not new_name.is_empty():
		selected_character_name = new_name

func _on_role_selected(index: int) -> void:
	if index >= 0 and index < CharacterData.PRESETS.size():
		var p: Dictionary = CharacterData.PRESETS[index]
		selected_character_name = String(p.get("name", "Ko Thet"))
		selected_character_role = String(p.get("role", "Novice Citizen"))
		if index < PRESET_COLORS.size():
			set_ball_color(PRESET_COLORS[index]["color"])
		_refresh_character_display()

func _refresh_character_display() -> void:
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

## Applies customization to player, unlocks WebAudio, and enters Yangon
func start_game() -> void:
	var player_nodes := get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		var player := player_nodes[0]
		if char_name_edit and not char_name_edit.text.is_empty():
			selected_character_name = char_name_edit.text

		if player.has_method("set_ball_color"):
			player.call("set_ball_color", selected_ball_color)
		if player.has_method("set_ball_photo_path") and not selected_photo_path.is_empty():
			player.call("set_ball_photo_path", selected_photo_path)
		if player.has_method("set_player_name"):
			player.call("set_player_name", selected_character_name, selected_character_role)
		if player.has_method("apply_character"):
			player.call("apply_character", selected_character_index, selected_character_name, selected_character_role)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_unlock_web_audio()
	hide()
	print_rich("[color=green][StartScreen] Entered Yangon as %s (%s). 3D Ball avatar active, WebAudio unlocked.[/color]" % [selected_character_name, selected_character_role])
	game_started.emit()

func _unlock_web_audio() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, false)
	var tree := get_tree()
	if tree and tree.root and tree.root.has_node("AudioManager"):
		var am = tree.root.get_node("AudioManager")
		if am.has_method("unlock_audio"):
			am.unlock_audio()
