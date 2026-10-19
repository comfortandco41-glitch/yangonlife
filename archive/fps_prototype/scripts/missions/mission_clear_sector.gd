class_name MissionClearSector
extends Node3D

@export var ai_soldier_scene: PackedScene = preload("res://scenes/characters/ai_soldier.tscn")

@onready var player: PlayerController = $Player
@onready var hud: HUDController = $HUD
@onready var enemies_container: Node3D = $Enemies

var total_enemies: int = 3
var remaining_enemies: int = 3
var is_mission_active: bool = true

func _enter_tree() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if not player and has_node("Player"):
		player = get_node("Player") as PlayerController
	if not hud and has_node("HUD"):
		hud = get_node("HUD") as HUDController
	if not enemies_container and has_node("Enemies"):
		enemies_container = get_node("Enemies") as Node3D

func _ready() -> void:
	_ensure_nodes()

	# Add player to group so AI perception can find it
	if player:
		player.add_to_group("players")
		player.player_health_changed.connect(_on_player_health_changed)
		if hud:
			player.player_ammo_changed.connect(hud.update_ammo)
		player.player_died.connect(_on_player_died)

	# Initialize HUD display
	if hud and player:
		hud.set_faction("PDF")
		if player.health_component:
			hud.update_health(player.health_component.current_health, player.health_component.max_health)
		if player.weapon_manager:
			hud.update_ammo(player.weapon_manager.current_ammo, player.weapon_manager.reserve_ammo)

	# Spawn Enemy Patrols
	_spawn_enemies()

func _spawn_enemies() -> void:
	if not enemies_container:
		return

	var spawn_points = [
		Vector3(18.0, 0.2, -2.0), # East sandbag position
		Vector3(4.0, 0.2, 2.5),   # Mid-street bus flank
		Vector3(14.0, 0.3, 8.5)   # North sidewalk alley
	]

	total_enemies = spawn_points.size()
	remaining_enemies = total_enemies
	if hud:
		hud.update_objective(remaining_enemies, total_enemies)

	for spawn_pos in spawn_points:
		var enemy = ai_soldier_scene.instantiate() as AISoldier
		enemies_container.add_child(enemy)
		enemy.global_position = spawn_pos
		enemy.soldier_died.connect(_on_enemy_died)

func _on_player_health_changed(current: float, max_h: float) -> void:
	if hud:
		hud.update_health(current, max_h)
		if current < max_h:
			hud.trigger_damage_flash()

func _on_enemy_died(_soldier: AISoldier) -> void:
	remaining_enemies = max(0, remaining_enemies - 1)
	if hud:
		hud.update_objective(remaining_enemies, total_enemies)

	if remaining_enemies == 0 and is_mission_active:
		is_mission_active = false
		if hud:
			hud.show_victory()

func _on_player_died() -> void:
	if is_mission_active:
		is_mission_active = false
		if hud:
			hud.show_defeat()
