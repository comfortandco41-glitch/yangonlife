class_name HUDController
extends Control

signal restart_requested

@onready var health_label: Label = $Margin/BottomLeft/HBox/HealthLabel
@onready var health_bar: ProgressBar = $Margin/BottomLeft/HealthBar
@onready var ammo_label: Label = $Margin/BottomRight/AmmoLabel
@onready var reload_prompt: Label = $Margin/BottomRight/ReloadPrompt
@onready var objective_label: Label = $Margin/TopCenter/ObjectiveLabel
@onready var faction_label: Label = $Margin/TopLeft/FactionLabel
@onready var damage_flash: ColorRect = $DamageFlash
@onready var victory_panel: Panel = $VictoryPanel
@onready var defeat_panel: Panel = $DefeatPanel
@onready var start_overlay: Panel = $StartOverlay

var flash_tween: Tween

func _ready() -> void:
	if victory_panel:
		victory_panel.visible = false
	if defeat_panel:
		defeat_panel.visible = false
	if reload_prompt:
		reload_prompt.visible = false
	if damage_flash:
		damage_flash.modulate.a = 0.0

	# Browser / Initial Start Overlay
	if start_overlay:
		start_overlay.visible = OS.has_feature("web")

	# Connect restart buttons
	if victory_panel and victory_panel.has_node("VBox/RestartBtn"):
		victory_panel.get_node("VBox/RestartBtn").pressed.connect(_on_restart_pressed)
	if defeat_panel and defeat_panel.has_node("VBox/RestartBtn"):
		defeat_panel.get_node("VBox/RestartBtn").pressed.connect(_on_restart_pressed)
	if start_overlay and start_overlay.has_node("Button"):
		start_overlay.get_node("Button").pressed.connect(_on_start_clicked)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_mission"):
		_on_restart_pressed()

func update_health(current: float, max_h: float) -> void:
	if health_label:
		health_label.text = "HP: %d / %d" % [int(current), int(max_h)]
	if health_bar:
		health_bar.max_value = max_h
		health_bar.value = current

func update_ammo(current: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "AMMO: %d / %d" % [current, reserve]
	if reload_prompt:
		reload_prompt.visible = (current == 0 and reserve > 0)

func update_objective(remaining_enemies: int, total_enemies: int) -> void:
	if objective_label:
		if remaining_enemies > 0:
			objective_label.text = "OBJECTIVE: Clear Downtown Sector (Hostiles: %d / %d)" % [remaining_enemies, total_enemies]
		else:
			objective_label.text = "OBJECTIVE: Sector Cleared! Mission Complete."

func set_faction(team_name: String) -> void:
	if faction_label:
		faction_label.text = "FACTION: %s" % team_name

func trigger_damage_flash() -> void:
	if not damage_flash:
		return
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	damage_flash.modulate.a = 0.45
	flash_tween = create_tween()
	flash_tween.tween_property(damage_flash, "modulate:a", 0.0, 0.4)

func show_victory() -> void:
	if victory_panel:
		victory_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_defeat() -> void:
	if defeat_panel:
		defeat_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed() -> void:
	restart_requested.emit()
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("restart_current_scene"):
		gm.restart_current_scene()
	elif get_tree():
		get_tree().reload_current_scene()

func _on_start_clicked() -> void:
	if start_overlay:
		start_overlay.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
