class_name ThirdPersonController
extends CharacterBody3D

const CharacterData = preload("res://scripts/systems/character_data.gd")

## Isometric & Third-Person Player Controller for Yangon Life (ရန်ကုန် ဘဝ).
##
## Features:
## - Professional isometric camera with overhead angle, smooth target tracking,
##   mouse wheel zoom, and Q/E 45° rotation.
## - 4-direction animated pixel-art character sprite (SuperRetroWorld 32x32 walk cycles).
## - Screen-relative 8-directional movement with stamina-based sprinting.
## - Character selection & persistence across save/load.
## - Contextual interaction trigger and audio integration.

const MOVE_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.5
const JUMP_VELOCITY: float = 4.5
const PITCH_ISOMETRIC: float = deg_to_rad(-45.0)

@export var move_speed: float = MOVE_SPEED
@export var sprint_speed: float = SPRINT_SPEED
@export var jump_velocity: float = JUMP_VELOCITY
@export var character_index: int = 1
@export var character_name: String = "Ko Thet"
@export var character_role: String = "Novice Citizen"

@onready var camera_yaw: Node3D = $CameraYaw
@onready var spring_arm: SpringArm3D = $CameraYaw/SpringArm3D
@onready var camera: Camera3D = $CameraYaw/SpringArm3D/Camera3D
@onready var character_sprite: Sprite3D = get_node_or_null("CharacterSprite") as Sprite3D
@onready var player_mesh: MeshInstance3D = get_node_or_null("PlayerMesh") as MeshInstance3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _footstep_distance: float = 0.0
var _anim_timer: float = 0.0
var _facing_row: int = 0 # 0: Down (South), 1: Left (West), 2: Right (East), 3: Up (North)
var _is_rmb_dragging: bool = false
var _target_yaw: float = deg_to_rad(45.0)
var _target_zoom: float = 16.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("player")

	# Hide fallback 3D capsule mesh in favor of animated pixel sprite
	if player_mesh:
		player_mesh.visible = false

	# Setup isometric camera defaults
	if camera_yaw and spring_arm and camera:
		camera_yaw.rotation.y = _target_yaw
		spring_arm.rotation.x = PITCH_ISOMETRIC
		spring_arm.spring_length = _target_zoom
		spring_arm.margin = 0.2
		camera.fov = 50.0

	# Keep mouse cursor visible for isometric interaction & HUD navigation
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		if gm.has_signal("game_paused"):
			gm.connect("game_paused", _on_game_paused)
		if gm.has_signal("game_resumed"):
			gm.connect("game_resumed", _on_game_resumed)

	# Safety check: if player is spawned within the Sule Pagoda solid collision zone (origin radius 8m),
	# snap safely to DowntownYangon/SpawnPoint or default (0, 1, 14)
	if global_position.distance_to(Vector3(0.0, 1.0, 0.0)) < 8.0:
		var spawn_point: Node3D = get_node_or_null("../DowntownYangon/SpawnPoint") as Node3D
		if spawn_point:
			global_position = spawn_point.global_position
		else:
			global_position = Vector3(0.0, 1.0, 14.0)

	# Load saved or default character appearance
	apply_character(character_index, character_name, character_role)

func _unhandled_input(event: InputEvent) -> void:
	# Pause handling: call GameManager.toggle_pause()
	if event.is_action_pressed("pause"):
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("toggle_pause"):
			gm.call("toggle_pause")
		return

	if _is_paused():
		return

	# Contextual Interaction: call InteractionManager.trigger_interaction()
	if event.is_action_pressed("interact"):
		var im: Node = get_node_or_null("/root/InteractionManager")
		if im and im.has_method("trigger_interaction"):
			im.call("trigger_interaction")
		return

	# Isometric Camera Zoom via Mouse Wheel
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_target_zoom = clampf(_target_zoom - 2.0, 8.0, 26.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_target_zoom = clampf(_target_zoom + 2.0, 8.0, 26.0)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_rmb_dragging = mb.pressed

	# Camera Angle Rotation with Q / R (or Right-Mouse Drag)
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_Q:
			_target_yaw -= deg_to_rad(45.0)
		elif key_event.keycode == KEY_R:
			_target_yaw += deg_to_rad(45.0)

	if event is InputEventMouseMotion and _is_rmb_dragging:
		var mm := event as InputEventMouseMotion
		_target_yaw -= mm.relative.x * 0.006

func _physics_process(delta: float) -> void:
	if _is_paused():
		return

	# Smooth camera zoom and rotation interpolation
	if spring_arm:
		spring_arm.spring_length = lerpf(spring_arm.spring_length, _target_zoom, minf(10.0 * delta, 1.0))
	if camera_yaw:
		camera_yaw.rotation.y = lerp_angle(camera_yaw.rotation.y, _target_yaw, minf(10.0 * delta, 1.0))

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Determine sprint speed (allowed only if NeedsManager.can_sprint())
	var can_sprint: bool = false
	var nm: Node = get_node_or_null("/root/NeedsManager")
	if nm and nm.has_method("can_sprint"):
		can_sprint = nm.call("can_sprint")
	var is_sprinting: bool = Input.is_action_pressed("sprint") and can_sprint
	var current_speed: float = sprint_speed if is_sprinting else move_speed

	# Screen-relative isometric movement:
	# W: moves Forward on screen (away from camera)
	# S: moves Backward on screen (towards camera)
	# A: moves Left on screen
	# D: moves Right on screen
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var move_vec := Vector3.ZERO

	if input_dir != Vector2.ZERO:
		var cam_forward: Vector3 = -camera_yaw.global_transform.basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		var cam_right: Vector3 = camera_yaw.global_transform.basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()

		move_vec = (cam_right * input_dir.x + cam_forward * (-input_dir.y)).normalized()

	if move_vec != Vector3.ZERO:
		velocity.x = move_vec.x * current_speed
		velocity.z = move_vec.z * current_speed

		# Update footstep audio
		if is_on_floor():
			_footstep_distance += current_speed * delta
			if _footstep_distance >= 2.0:
				_footstep_distance = 0.0
				var am: Node = get_node_or_null("/root/AudioManager")
				if am and am.has_method("play_footstep"):
					am.call("play_footstep")

		# Determine sprite facing direction relative to screen inputs
		if absf(input_dir.y) >= absf(input_dir.x):
			_facing_row = 0 if input_dir.y > 0.0 else 3 # Down vs Up
		else:
			_facing_row = 2 if input_dir.x > 0.0 else 1 # Right vs Left

		# Animate 3-frame walk cycle [0, 1, 2, 1]
		_anim_timer += delta * (10.0 if is_sprinting else 7.0)
		var step: int = int(_anim_timer) % 4
		var frame_col: int = 1 if (step == 1 or step == 3) else (0 if step == 0 else 2)
		if character_sprite:
			character_sprite.frame = _facing_row * 3 + frame_col
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)
		_footstep_distance = 0.0
		_anim_timer = 0.0
		# Idle: stand at neutral frame in current facing row
		if character_sprite:
			character_sprite.frame = _facing_row * 3 + 1

	move_and_slide()

## Applies a selected character appearance, name, and role
func apply_character(index: int, cname: String = "", crole: String = "") -> void:
	character_index = clampi(index, 1, CharacterData.TOTAL_CHARACTERS)
	if not cname.is_empty():
		character_name = cname
	if not crole.is_empty():
		character_role = crole

	if character_sprite:
		var path: String = CharacterData.get_sprite_sheet_path(character_index)
		var tex: Texture2D = load(path) as Texture2D
		if tex:
			character_sprite.texture = tex
			character_sprite.frame = _facing_row * 3 + 1

	_update_ui_avatars()

## Synchronizes HUD and Phone Menu profile avatars
func _update_ui_avatars() -> void:
	var portrait: AtlasTexture = CharacterData.get_character_portrait(character_index)
	if not portrait:
		return

	# Update HUD player avatar
	var hud: Node = get_tree().get_first_node_in_group("hud")
	if not hud:
		hud = get_node_or_null("../HUD")
	if hud:
		var avatar_rect: TextureRect = hud.get_node_or_null("MarginContainer/TopSection/AvatarCard/PlayerAvatar") as TextureRect
		if avatar_rect:
			avatar_rect.texture = portrait

	# Update Phone status and profile
	var phone: Node = get_node_or_null("../UI/PhoneMenu")
	if phone:
		var home_avatar: TextureRect = phone.get_node_or_null("%ProfileCard/HBox/AvatarIcon") as TextureRect
		if home_avatar:
			home_avatar.texture = portrait
		var home_name: Label = phone.get_node_or_null("%ProfileCard/HBox/VBox/NameLabel") as Label
		if home_name:
			home_name.text = "%s (%s)" % [character_name, character_role]

		var status_avatar: TextureRect = phone.get_node_or_null("%StatusProfile/HBox/AvatarIcon") as TextureRect
		if status_avatar:
			status_avatar.texture = portrait
		var status_name: Label = phone.get_node_or_null("%StatusProfile/HBox/VBox/StatusName") as Label
		if status_name:
			status_name.text = "Character: %s" % character_name
		var status_rep: Label = phone.get_node_or_null("%StatusProfile/HBox/VBox/StatusRep") as Label
		if status_rep:
			status_rep.text = "%s • Good Standing" % character_role

func _is_paused() -> bool:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and "is_paused" in gm:
		return bool(gm.get("is_paused"))
	return get_tree().paused

func _on_game_paused() -> void:
	pass

func _on_game_resumed() -> void:
	pass

## Returns player transform and character data for persistent save files
func get_save_data() -> Dictionary:
	var pos: Vector3 = global_position if is_inside_tree() else position
	return {
		"position": [pos.x, pos.y, pos.z],
		"rotation_y": rotation.y,
		"character_index": character_index,
		"character_name": character_name,
		"character_role": character_role
	}

## Restores player transform and character data from persistent save files
func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		var pos_arr: Variant = data["position"]
		if pos_arr is Array and pos_arr.size() >= 3:
			var target_pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
			if is_inside_tree():
				global_position = target_pos
			else:
				position = target_pos
	if data.has("rotation_y"):
		rotation.y = float(data["rotation_y"])
	if data.has("character_index"):
		character_index = int(data["character_index"])
	if data.has("character_name"):
		character_name = String(data["character_name"])
	if data.has("character_role"):
		character_role = String(data["character_role"])
	apply_character(character_index, character_name, character_role)
