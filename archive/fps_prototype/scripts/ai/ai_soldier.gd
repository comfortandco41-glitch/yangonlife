class_name AISoldier
extends CharacterBody3D

signal soldier_died(soldier: AISoldier)

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DEAD
}

@export var team_id: int = 1 # 1 = MILITARY
@export var walk_speed: float = 3.0
@export var chase_speed: float = 4.8
@export var detection_range: float = 32.0
@export var attack_range: float = 20.0
@export var fov_degrees: float = 90.0
@export var burst_count: int = 3
@export var burst_interval: float = 0.15
@export var attack_cooldown: float = 1.2
@export var damage_per_shot: float = 14.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var visual_root: Node3D = $VisualRoot
@onready var muzzle_point: Node3D = $VisualRoot/WeaponMesh/Muzzle
@onready var muzzle_light: OmniLight3D = $VisualRoot/WeaponMesh/MuzzleLight

var tracer_scene: PackedScene = preload("res://scenes/weapons/bullet_tracer.tscn")

var current_state: State = State.IDLE
var target_player: CharacterBody3D = null
var gravity: float = 15.0

# Timers
var state_timer: float = 0.0
var attack_timer: float = 0.0
var is_firing_burst: bool = false
var shots_fired_in_burst: int = 0
var burst_timer: float = 0.0

# Patrol points
var spawn_position: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO

func _enter_tree() -> void:
	_ensure_references()

func _ensure_references() -> void:
	if not health_component and has_node("HealthComponent"):
		health_component = get_node("HealthComponent") as HealthComponent
	if not hitbox_component and has_node("HitboxComponent"):
		hitbox_component = get_node("HitboxComponent") as HitboxComponent
	if not visual_root and has_node("VisualRoot"):
		visual_root = get_node("VisualRoot") as Node3D
	if visual_root and not muzzle_point and visual_root.has_node("WeaponMesh/Muzzle"):
		muzzle_point = visual_root.get_node("WeaponMesh/Muzzle") as Node3D
	if visual_root and not muzzle_light and visual_root.has_node("WeaponMesh/MuzzleLight"):
		muzzle_light = visual_root.get_node("WeaponMesh/MuzzleLight") as OmniLight3D

func _ready() -> void:
	_ensure_references()
	spawn_position = global_position
	patrol_target = spawn_position

	if health_component:
		health_component.team_id = team_id
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)

	if hitbox_component:
		hitbox_component.team_id = team_id
		hitbox_component.health_component = health_component

	if muzzle_light:
		muzzle_light.visible = false

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	state_timer += delta
	attack_timer += delta

	# Look for target player if none or lost
	_update_perception(delta)

	# FSM Execution
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)

	move_and_slide()

func _update_perception(_delta: float) -> void:
	if not target_player:
		var players = get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			var candidate = players[0] as CharacterBody3D
			if candidate and candidate.has_node("HealthComponent") and not candidate.get_node("HealthComponent").is_dead:
				target_player = candidate

	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= detection_range:
			if _has_line_of_sight_to(target_player):
				if dist <= attack_range:
					current_state = State.ATTACK
				else:
					current_state = State.CHASE
				return

	if current_state == State.CHASE or current_state == State.ATTACK:
		if not target_player or not _has_line_of_sight_to(target_player):
			current_state = State.IDLE
			state_timer = 0.0

func _has_line_of_sight_to(target: CharacterBody3D) -> bool:
	var eye_pos = global_position + Vector3(0, 1.5, 0)
	var target_eye = target.global_position + Vector3(0, 1.4, 0)

	var dir_to_target = (target_eye - eye_pos).normalized()
	var forward = -visual_root.global_transform.basis.z if visual_root else Vector3.FORWARD

	if current_state == State.IDLE or current_state == State.PATROL:
		var angle = rad_to_deg(forward.angle_to(dir_to_target))
		if angle > (fov_degrees * 0.5):
			return false

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(eye_pos, target_eye)
	query.collision_mask = 1 | 2
	var result = space_state.intersect_ray(query)

	if result:
		if result.collider == target or (result.collider.is_inside_tree() and target.is_ancestor_of(result.collider)):
			return true
		return false

	return true

func _process_idle(_delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 0.2)
	velocity.z = lerp(velocity.z, 0.0, 0.2)

	if state_timer >= 3.0:
		state_timer = 0.0
		patrol_target = spawn_position + Vector3(randf_range(-8.0, 8.0), 0, randf_range(-8.0, 8.0))
		current_state = State.PATROL

func _process_patrol(_delta: float) -> void:
	var to_patrol = patrol_target - global_position
	to_patrol.y = 0

	if to_patrol.length() < 1.0 or state_timer >= 6.0:
		current_state = State.IDLE
		state_timer = 0.0
		return

	var move_dir = to_patrol.normalized()
	velocity.x = move_dir.x * walk_speed
	velocity.z = move_dir.z * walk_speed

	_look_towards(global_position + move_dir)

func _process_chase(_delta: float) -> void:
	if not target_player:
		current_state = State.IDLE
		return

	var to_player = target_player.global_position - global_position
	to_player.y = 0

	var move_dir = to_player.normalized()
	velocity.x = move_dir.x * chase_speed
	velocity.z = move_dir.z * chase_speed

	_look_towards(target_player.global_position)

func _process_attack(delta: float) -> void:
	if not target_player:
		current_state = State.IDLE
		return

	velocity.x = lerp(velocity.x, 0.0, 0.2)
	velocity.z = lerp(velocity.z, 0.0, 0.2)

	_look_towards(target_player.global_position)

	if is_firing_burst:
		burst_timer += delta
		if burst_timer >= burst_interval:
			burst_timer = 0.0
			_fire_single_shot()
			shots_fired_in_burst += 1
			if shots_fired_in_burst >= burst_count:
				is_firing_burst = false
				attack_timer = 0.0
	else:
		if attack_timer >= attack_cooldown:
			is_firing_burst = true
			shots_fired_in_burst = 0
			burst_timer = 0.0

func _fire_single_shot() -> void:
	if not target_player:
		return

	if muzzle_light:
		muzzle_light.visible = true
		var t = get_tree().create_timer(0.04)
		t.timeout.connect(func(): if muzzle_light: muzzle_light.visible = false)

	var start_pos = muzzle_point.global_position if muzzle_point else global_position + Vector3(0, 1.4, 0)
	var target_pos = target_player.global_position + Vector3(0, 1.3, 0)
	var spread = Vector3(randf_range(-0.4, 0.4), randf_range(-0.3, 0.3), randf_range(-0.4, 0.4))
	var aim_target = target_pos + spread

	var space_state = get_world_3d().direct_space_state
	var dir = (aim_target - start_pos).normalized()
	var ray_end = start_pos + dir * 60.0

	var query = PhysicsRayQueryParameters3D.create(start_pos, ray_end)
	query.collision_mask = 1 | 4
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)

	var hit_pos = ray_end
	if result:
		hit_pos = result.position
		var collider = result.collider
		if collider is HitboxComponent:
			collider.receive_damage(damage_per_shot, team_id, hit_pos, result.normal)
		elif collider.has_node("HitboxComponent"):
			var hitbox = collider.get_node("HitboxComponent") as HitboxComponent
			hitbox.receive_damage(damage_per_shot, team_id, hit_pos, result.normal)
		elif collider.has_method("take_damage"):
			collider.take_damage(damage_per_shot, team_id)

	if tracer_scene:
		var tracer = tracer_scene.instantiate() as BulletTracer
		get_tree().root.add_child(tracer)
		tracer.initialize(start_pos, hit_pos)

func _look_towards(target_pos: Vector3) -> void:
	if not visual_root:
		return
	var look_target = target_pos
	look_target.y = global_position.y
	if global_position.distance_squared_to(look_target) > 0.01:
		visual_root.look_at(look_target, Vector3.UP)
		visual_root.rotate_y(PI)

func _on_damaged(_amount: float, _source_team: int) -> void:
	if current_state == State.DEAD:
		return
	if current_state == State.IDLE or current_state == State.PATROL:
		if visual_root:
			visual_root.rotate_y(PI)
		current_state = State.CHASE
		state_timer = 0.0

func _on_died(_killer_team: int) -> void:
	current_state = State.DEAD
	velocity = Vector3.ZERO
	if has_node("CollisionShape3D"):
		get_node("CollisionShape3D").set_deferred("disabled", true)
	if hitbox_component and hitbox_component.has_node("HitboxShape"):
		hitbox_component.get_node("HitboxShape").set_deferred("disabled", true)

	if visual_root:
		var tween = create_tween()
		tween.tween_property(visual_root, "rotation:x", deg_to_rad(-85), 0.35)
		tween.parallel().tween_property(visual_root, "position:y", 0.15, 0.35)

	soldier_died.emit(self)
