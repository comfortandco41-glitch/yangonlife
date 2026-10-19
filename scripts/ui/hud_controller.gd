extends CanvasLayer
## HUD Controller — displays money, time, needs, interaction prompts,
## real-time GPS Minimap radar, and mobile virtual keypad controls.

const CharacterData = preload("res://scripts/systems/character_data.gd")

@onready var day_label: Label = %DayLabel if has_node("%DayLabel") else find_child("DayLabel", true, false)
@onready var time_label: Label = %TimeLabel if has_node("%TimeLabel") else find_child("TimeLabel", true, false)
@onready var money_label: Label = %MoneyLabel if has_node("%MoneyLabel") else find_child("MoneyLabel", true, false)
@onready var hunger_bar: ProgressBar = %HungerBar if has_node("%HungerBar") else find_child("HungerBar", true, false)
@onready var energy_bar: ProgressBar = %EnergyBar if has_node("%EnergyBar") else find_child("EnergyBar", true, false)
@onready var hygiene_bar: ProgressBar = %HygieneBar if has_node("%HygieneBar") else find_child("HygieneBar", true, false)
@onready var stress_bar: ProgressBar = %StressBar if has_node("%StressBar") else find_child("StressBar", true, false)
@onready var interaction_prompt: Label = %InteractionPrompt if has_node("%InteractionPrompt") else find_child("InteractionPrompt", true, false)

@onready var minimap_radar: Control = find_child("MinimapRadar", true, false)
@onready var district_label: Label = find_child("DistrictLabel", true, false)
@onready var gps_coords_label: Label = find_child("GPSCoordsLabel", true, false)
@onready var btn_zoom_map: Button = find_child("BtnZoomMap", true, false)
@onready var mobile_keypad: Control = find_child("MobileKeypad", true, false)
@onready var btn_toggle_touch: Button = find_child("BtnToggleTouch", true, false)

var _player_ref: Node3D = null

func _ready() -> void:
	# Connect to EconomyManager
	if has_node("/root/EconomyManager"):
		var em: Node = get_node("/root/EconomyManager")
		if em.has_signal("money_changed"):
			em.money_changed.connect(_on_money_changed)
		if em.has_method("get_balance"):
			update_money(em.get_balance())
		elif "balance" in em:
			update_money(em.balance)

	# Connect to NeedsManager
	if has_node("/root/NeedsManager"):
		var nm: Node = get_node("/root/NeedsManager")
		if nm.has_signal("need_changed"):
			nm.need_changed.connect(_on_need_changed)
		if "hunger" in nm:
			_update_need("hunger", nm.hunger)
		if "energy" in nm:
			_update_need("energy", nm.energy)
		if "hygiene" in nm:
			_update_need("hygiene", nm.hygiene)
		if "stress" in nm:
			_update_need("stress", nm.stress)

	# Connect to TimeManager
	if has_node("/root/TimeManager"):
		var tm: Node = get_node("/root/TimeManager")
		if tm.has_signal("time_tick"):
			tm.time_tick.connect(_on_time_tick)
		if tm.has_signal("day_changed"):
			tm.day_changed.connect(_on_day_changed)
		_refresh_time_display()

	# Connect to InteractionManager
	if has_node("/root/InteractionManager"):
		var im: Node = get_node("/root/InteractionManager")
		if im.has_signal("interactable_entered"):
			im.interactable_entered.connect(_on_interactable_entered)
		if im.has_signal("interactable_exited"):
			im.interactable_exited.connect(_on_interactable_exited)

	# Initial prompt state
	if interaction_prompt:
		interaction_prompt.text = ""
		interaction_prompt.visible = false

	# Setup initial citizen portrait
	var avatar_rect := get_node_or_null("MarginContainer/TopSection/AvatarCard/PlayerAvatar") as TextureRect
	if avatar_rect:
		var portrait: AtlasTexture = CharacterData.get_character_portrait(1)
		if portrait:
			avatar_rect.texture = portrait

	# Setup Minimap callbacks
	if minimap_radar and minimap_radar.has_signal("district_changed"):
		minimap_radar.district_changed.connect(_on_district_changed)

	if btn_zoom_map and minimap_radar and minimap_radar.has_method("toggle_zoom"):
		btn_zoom_map.pressed.connect(func():
			var r = minimap_radar.toggle_zoom()
			btn_zoom_map.text = "🔍 %.0fm" % r
		)

	# Setup Mobile touch controls toggle
	if btn_toggle_touch and mobile_keypad:
		btn_toggle_touch.pressed.connect(func():
			if mobile_keypad.has_method("toggle_keypad"):
				mobile_keypad.toggle_keypad()
		)

func _process(_delta: float) -> void:
	if not is_instance_valid(_player_ref):
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			_player_ref = p_nodes[0] as Node3D

	if is_instance_valid(_player_ref) and gps_coords_label:
		var pos := _player_ref.global_position
		gps_coords_label.text = "GPS: X: %+.0fm  Z: %+.0fm" % [pos.x, pos.z]

func _on_district_changed(district: String) -> void:
	if district_label:
		district_label.text = "📍 " + district

## Updates the player portrait icon with a cropped 32x32 face
func set_player_avatar(character_index: int) -> void:
	var avatar_rect := get_node_or_null("MarginContainer/TopSection/AvatarCard/PlayerAvatar") as TextureRect
	if avatar_rect:
		var portrait: AtlasTexture = CharacterData.get_character_portrait(character_index)
		if portrait:
			avatar_rect.texture = portrait

func _on_money_changed(new_balance: int) -> void:
	update_money(new_balance)

func update_money(amount: int) -> void:
	if not money_label:
		return
	money_label.text = _format_money(amount)

func _format_money(amount: int) -> String:
	var is_negative: bool = amount < 0
	var abs_amount: int = abs(amount)
	var s: String = str(abs_amount)
	var formatted: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = s[i] + formatted
		count += 1
	if is_negative:
		return "-K " + formatted
	return "K " + formatted

func _on_need_changed(need_name: String, value: float) -> void:
	_update_need(need_name, value)

func _update_need(need_name: String, value: float) -> void:
	match need_name:
		"hunger":
			if hunger_bar:
				hunger_bar.value = clampf(value, 0.0, 100.0)
		"energy":
			if energy_bar:
				energy_bar.value = clampf(value, 0.0, 100.0)
		"hygiene":
			if hygiene_bar:
				hygiene_bar.value = clampf(value, 0.0, 100.0)
		"stress":
			if stress_bar:
				# Stress bar shows inverted: lower stress = fuller bar (100 - stress)
				stress_bar.value = clampf(100.0 - value, 0.0, 100.0)

func _on_time_tick(_hour: Variant = null, _minute: Variant = null) -> void:
	_refresh_time_display()

func _on_day_changed(day: int) -> void:
	update_day(day)

func _refresh_time_display() -> void:
	if not has_node("/root/TimeManager"):
		return
	var tm: Node = get_node("/root/TimeManager")
	if tm.has_method("get_time_string"):
		update_time(tm.get_time_string())
	elif "game_hour" in tm and "game_minute" in tm:
		update_time("%02d:%02d" % [tm.game_hour, tm.game_minute])

	var current_day: int = 1
	if "game_day" in tm:
		current_day = tm.game_day
	elif "day" in tm:
		current_day = tm.day
	update_day(current_day)

func update_time(time_str: String) -> void:
	if time_label:
		time_label.text = time_str

func update_day(day_num: int) -> void:
	if day_label:
		day_label.text = "Day %d" % day_num

func _on_interactable_entered(arg1: Variant = null, arg2: Variant = null) -> void:
	var prompt_str: String = "Interact"
	if arg2 is String and arg2 != "":
		prompt_str = arg2
	elif arg1 is String and arg1 != "":
		prompt_str = arg1
	elif arg1 != null and "interaction_prompt" in arg1 and str(arg1.interaction_prompt) != "":
		prompt_str = str(arg1.interaction_prompt)

	show_interaction_prompt(prompt_str)

func _on_interactable_exited() -> void:
	hide_interaction_prompt()

func show_interaction_prompt(prompt: String) -> void:
	if interaction_prompt:
		interaction_prompt.text = "[E] " + prompt
		interaction_prompt.visible = true

func hide_interaction_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.text = ""
		interaction_prompt.visible = false
