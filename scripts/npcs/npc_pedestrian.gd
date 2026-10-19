class_name NPCPedestrian
extends CharacterBody3D

const CharacterData = preload("res://scripts/systems/character_data.gd")

## Schedule-driven pedestrian NPC with distance-based LOD for Yangon Life.
##
## Implements three-tier LOD (Full, Simplified, Offscreen),
## schedule evaluation based on game hours, Burmese/English contextual dialogue,
## and collision setup for physics layer 2 (Characters).

const LOD_FULL: int = 0
const LOD_SIMPLIFIED: int = 1
const LOD_OFFSCREEN: int = 2

@export var npc_name: String = "U Kyaw"
@export var archetype: String = "office_worker" # "monk", "office_worker", "student", "street_vendor", "shopper"
@export var walk_speed: float = 2.0
@export var schedule_stops: Array[Vector3] = []

var current_stop_index: int = 0
var current_lod: int = 0
var is_interacting: bool = false
var target_destination: Vector3 = Vector3.ZERO
var has_destination: bool = false

var _lod_check_timer: float = 0.0
var _interaction_timer: float = 0.0
var _collision_shape: CollisionShape3D = null

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("pedestrians")

	# Find primary collision shape for LOD toggling
	_collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D

	# Initialize schedule destination
	if not schedule_stops.is_empty():
		current_stop_index = clampi(current_stop_index, 0, schedule_stops.size() - 1)
		set_target_destination(schedule_stops[current_stop_index])

	# Listen to TimeManager for schedule updates
	if has_node("/root/TimeManager"):
		var tm: Node = get_node("/root/TimeManager")
		if tm.has_signal("hour_changed"):
			tm.hour_changed.connect(evaluate_schedule)
		if tm.get("game_hour") != null:
			evaluate_schedule(int(tm.get("game_hour")))

	# Connect child InteractableZone if present
	var interactable_zone := _find_interactable_zone()
	if interactable_zone != null and interactable_zone.has_signal("interacted"):
		interactable_zone.interacted.connect(_on_interacted)

	# Set default LOD
	_set_lod(LOD_FULL)

	# Configure archetype pixel-art sprite
	_setup_archetype_sprite()

var _anim_timer: float = 0.0
var _facing_row: int = 0

func _setup_archetype_sprite() -> void:
	var sprite := get_node_or_null("CharacterSprite") as Sprite3D
	if not sprite:
		return
	var char_idx: int = 2
	match archetype:
		"monk":
			char_idx = 26
		"office_worker":
			char_idx = 2
		"street_vendor":
			char_idx = 8
		"student":
			char_idx = 14
		"shopper":
			char_idx = 5
		_:
			char_idx = 6
	var path: String = CharacterData.get_sprite_sheet_path(char_idx)
	var tex: Texture2D = load(path) as Texture2D
	if tex:
		sprite.texture = tex

func _process(delta: float) -> void:
	# Interaction cooldown timer
	if is_interacting:
		_interaction_timer -= delta
		if _interaction_timer <= 0.0:
			is_interacting = false

	# Periodic LOD updates relative to player
	_lod_check_timer += delta
	if _lod_check_timer >= 0.25:
		_lod_check_timer = 0.0
		var player_node := _get_player_node()
		if player_node != null:
			update_lod(player_node.global_position)

func _physics_process(delta: float) -> void:
	if is_interacting:
		velocity = Vector3.ZERO
		return

	if not has_destination:
		return

	var diff: Vector3 = target_destination - global_position
	diff.y = 0.0
	var dist: float = diff.length()

	# Destination arrival check
	if dist < 0.6:
		if schedule_stops.size() > 1:
			current_stop_index = (current_stop_index + 1) % schedule_stops.size()
			target_destination = schedule_stops[current_stop_index]
		else:
			has_destination = false
			velocity.x = 0.0
			velocity.z = 0.0
		return

	var move_dir: Vector3 = diff.normalized()

	match current_lod:
		LOD_FULL:
			velocity.x = move_dir.x * walk_speed
			velocity.z = move_dir.z * walk_speed
			if not is_on_floor():
				velocity.y -= 9.8 * delta
			else:
				velocity.y = 0.0

			var target_rot_y: float = atan2(-move_dir.x, -move_dir.z)
			rotation.y = lerp_angle(rotation.y, target_rot_y, minf(10.0 * delta, 1.0))
			move_and_slide()

			# Animate pixel-art sprite walk cycle
			var sprite := get_node_or_null("CharacterSprite") as Sprite3D
			if sprite:
				if absf(move_dir.z) >= absf(move_dir.x):
					_facing_row = 0 if move_dir.z > 0.0 else 3
				else:
					_facing_row = 2 if move_dir.x > 0.0 else 1
				_anim_timer += delta * 6.5
				var walk_step: int = int(_anim_timer) % 4
				var frame_offset: int = 1 if (walk_step == 1 or walk_step == 3) else (0 if walk_step == 0 else 2)
				sprite.frame = _facing_row * 3 + frame_offset

		LOD_SIMPLIFIED:
			var step: Vector3 = move_dir * walk_speed * delta
			if step.length() > dist:
				global_position = Vector3(target_destination.x, global_position.y, target_destination.z)
			else:
				global_position += step
			rotation.y = atan2(-move_dir.x, -move_dir.z)

		LOD_OFFSCREEN:
			var step: Vector3 = move_dir * walk_speed * delta
			if step.length() > dist:
				global_position = Vector3(target_destination.x, global_position.y, target_destination.z)
			else:
				global_position += step

## Sets target destination waypoint in world space
func set_target_destination(target: Vector3) -> void:
	target_destination = target
	has_destination = true

## Updates distance-based Level of Detail relative to player position
func update_lod(player_position: Vector3) -> void:
	var dist: float = global_position.distance_to(player_position)
	if dist < 25.0:
		_set_lod(LOD_FULL)
	elif dist <= 60.0:
		_set_lod(LOD_SIMPLIFIED)
	else:
		_set_lod(LOD_OFFSCREEN)

func _set_lod(new_lod: int) -> void:
	current_lod = new_lod
	match current_lod:
		LOD_FULL:
			visible = true
			collision_layer = 2 # Characters
			collision_mask = 5  # World (1) | Vehicles (4)
			if _collision_shape != null:
				_collision_shape.disabled = false
		LOD_SIMPLIFIED:
			visible = true
			collision_layer = 0
			collision_mask = 0
			if _collision_shape != null:
				_collision_shape.disabled = true
		LOD_OFFSCREEN:
			visible = false
			collision_layer = 0
			collision_mask = 0
			if _collision_shape != null:
				_collision_shape.disabled = true

## Updates schedule targets based on the current 24-hour game time
func evaluate_schedule(game_hour: int) -> void:
	if schedule_stops.is_empty():
		return
	var stop_count: int = schedule_stops.size()
	var stop_index: int = int(float(game_hour % 24) / 24.0 * stop_count) % stop_count
	current_stop_index = stop_index
	set_target_destination(schedule_stops[current_stop_index])

## Handles dialogue interaction with player and returns contextual Burmese/English line
func talk_to_player() -> String:
	is_interacting = true
	_interaction_timer = 4.0

	var dialogue: String = ""
	match archetype:
		"monk":
			dialogue = "Mingalarba, may you have peace of mind. (မင်္ဂလာပါ၊ စိတ်ချမ်းသာ ကိုယ်ကျန်းမာ ရှိပါစေ။)"
		"office_worker":
			dialogue = "Mingalarba! Hot day today. Heading to Sule for my office shift."
		"student":
			dialogue = "Mingalarba! Studying for exams near Yangon University. Hope to grab milk tea later."
		"street_vendor":
			dialogue = "Mingalarba! Fresh Mohinga and hot Shan noodles, only 3,000 Kyat!"
		"shopper":
			dialogue = "Mingalarba! Bogyoke Market has so many great fabrics and fresh fruits today."
		_:
			dialogue = "Mingalarba! Beautiful day in downtown Yangon."

	return dialogue

## Support direct interact() call from InteractionManager
func interact() -> void:
	var msg: String = talk_to_player()
	print("[%s (%s)] %s" % [npc_name, archetype, msg])

func _on_interacted() -> void:
	interact()

func _find_interactable_zone() -> Area3D:
	for child in get_children():
		if child is Area3D:
			if child is InteractableZone or child.get_script() != null:
				return child as Area3D
			for sub_child in child.get_children():
				if sub_child is Area3D:
					return sub_child as Area3D
	return null

func _get_player_node() -> Node3D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0] is Node3D:
		return players[0] as Node3D
	return null
