class_name WeaponManager
extends Node3D

signal ammo_changed(current_ammo: int, reserve_ammo: int)
signal weapon_fired
signal reload_started
signal reload_finished

@export var weapon_name: String = "MA-1 Vanguard"
@export var damage: float = 25.0
@export var fire_rate: float = 0.11 # ~550 RPM
@export var mag_capacity: int = 30
@export var current_ammo: int = 30
@export var reserve_ammo: int = 90
@export var reload_time: float = 1.8
@export var weapon_range: float = 120.0
@export var team_id: int = 2 # Default PDF for player

@export var camera: Camera3D
@export var muzzle_point: Node3D
@export var muzzle_light: OmniLight3D
@export var audio_player: AudioStreamPlayer3D

var tracer_scene: PackedScene = preload("res://scenes/weapons/bullet_tracer.tscn")

var can_fire: bool = true
var is_reloading: bool = false
var time_since_last_shot: float = 0.0

# Procedural recoil variables
var recoil_pitch: float = 0.0
var target_recoil_pitch: float = 0.0
var weapon_kickback: float = 0.0

func _ready() -> void:
	current_ammo = mag_capacity
	ammo_changed.emit(current_ammo, reserve_ammo)
	if muzzle_light:
		muzzle_light.visible = false

func _process(delta: float) -> void:
	time_since_last_shot += delta

	# Smoothly recover recoil
	recoil_pitch = lerp(recoil_pitch, 0.0, 14.0 * delta)
	weapon_kickback = lerp(weapon_kickback, 0.0, 16.0 * delta)

	# Apply kickback to weapon model transform if present
	if muzzle_point and muzzle_point.get_parent():
		muzzle_point.get_parent().position.z = weapon_kickback

func can_shoot() -> bool:
	return can_fire and not is_reloading and current_ammo > 0 and time_since_last_shot >= fire_rate

func shoot() -> bool:
	if is_reloading:
		return false

	if current_ammo <= 0:
		start_reload()
		return false

	if time_since_last_shot < fire_rate:
		return false

	time_since_last_shot = 0.0
	current_ammo -= 1
	ammo_changed.emit(current_ammo, reserve_ammo)
	weapon_fired.emit()

	# Recoil impulse
	recoil_pitch += randf_range(0.02, 0.035)
	weapon_kickback = 0.08

	# Flash muzzle
	_trigger_muzzle_flash()

	# Perform Raycast Hit Detection
	_perform_raycast()

	return true

func _trigger_muzzle_flash() -> void:
	if muzzle_light:
		muzzle_light.visible = true
		var timer = get_tree().create_timer(0.04)
		timer.timeout.connect(func(): if muzzle_light: muzzle_light.visible = false)

func _perform_raycast() -> void:
	if not camera:
		return

	var space_state = camera.get_world_3d().direct_space_state
	var screen_center = get_viewport().get_visible_rect().size / 2.0
	var ray_origin = camera.project_ray_origin(screen_center)
	var ray_dir = camera.project_ray_normal(screen_center)
	var ray_end = ray_origin + ray_dir * weapon_range

	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	# Layer 1 (World) + Layer 3 (Hitboxes: 4) = 5
	query.collision_mask = 1 | 4
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	var hit_pos = ray_end

	if result:
		hit_pos = result.position
		var collider = result.collider
		var normal = result.normal

		# If collider is HitboxComponent or parent contains HitboxComponent
		if collider is HitboxComponent:
			collider.receive_damage(damage, team_id, hit_pos, normal)
		elif collider.has_node("HitboxComponent"):
			var hitbox = collider.get_node("HitboxComponent") as HitboxComponent
			hitbox.receive_damage(damage, team_id, hit_pos, normal)
		elif collider.has_method("take_damage"):
			collider.take_damage(damage, team_id)

	# Spawn visual tracer from muzzle to hit position
	_spawn_tracer(hit_pos)

func _spawn_tracer(target_position: Vector3) -> void:
	if not tracer_scene:
		return

	var tracer = tracer_scene.instantiate() as BulletTracer
	var start_pos = muzzle_point.global_position if muzzle_point else global_position
	get_tree().root.add_child(tracer)
	tracer.initialize(start_pos, target_position)

func start_reload() -> void:
	if is_reloading or current_ammo >= mag_capacity or reserve_ammo <= 0:
		return

	is_reloading = true
	reload_started.emit()

	var timer = get_tree().create_timer(reload_time)
	timer.timeout.connect(_finish_reload)

func _finish_reload() -> void:
	if not is_reloading:
		return

	var needed = mag_capacity - current_ammo
	var reload_amount = min(needed, reserve_ammo)
	current_ammo += reload_amount
	reserve_ammo -= reload_amount
	is_reloading = false

	ammo_changed.emit(current_ammo, reserve_ammo)
	reload_finished.emit()
