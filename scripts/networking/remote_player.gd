class_name RemotePlayer
extends CharacterBody3D
## Multiplayer Puppet Entity for Yangon Life (ရန်ကုန် ဘဝ).
##
## Represents another player in the open world with overhead status display,
## visual character meshes (traditional Burmese eingyi & longyi), and smooth
## cubic Hermite kinematic interpolation at 20 Hz.

const INTERPOLATION_PERIOD: float = 0.05 # 20 Hz = 50ms tick interval
const SNAP_DISTANCE_THRESHOLD: float = 8.0 # Teleport snap threshold (meters)

@export var player_name: String = "Player" : set = set_player_name
@export var player_balance: int = 50000 : set = set_player_balance
@export var player_status: String = "Downtown" : set = set_player_status

@onready var overhead_label: Label3D = $OverheadLabel if has_node("OverheadLabel") else null
@onready var body_mesh: MeshInstance3D = $BodyMesh if has_node("BodyMesh") else null
@onready var longyi_mesh: MeshInstance3D = $LongyiMesh if has_node("LongyiMesh") else null

var target_position: Vector3 = Vector3.ZERO
var target_rotation_y: float = 0.0
var previous_position: Vector3 = Vector3.ZERO
var previous_rotation_y: float = 0.0
var interpolation_elapsed: float = INTERPOLATION_PERIOD

func _ready() -> void:
	add_to_group("remote_player")
	collision_layer = 2 # Characters layer
	collision_mask = 1 # World layer
	
	target_position = global_position
	previous_position = global_position
	target_rotation_y = rotation.y
	previous_rotation_y = rotation.y
	
	update_overhead_label()

func set_player_name(p_name: String) -> void:
	player_name = p_name
	update_overhead_label()

func set_player_balance(p_balance: int) -> void:
	player_balance = p_balance
	update_overhead_label()

func set_player_status(p_status: String) -> void:
	player_status = p_status
	update_overhead_label()

## Sets target position and rotation from network snapshot with cubic interpolation.
func set_target_transform(target_pos: Vector3, target_rot_y: float) -> void:
	var current_pos: Vector3 = global_position if is_inside_tree() else position
	var current_rot_y: float = rotation.y
	
	# Snap immediately if distance exceeds teleport threshold
	if current_pos.distance_to(target_pos) > SNAP_DISTANCE_THRESHOLD:
		if is_inside_tree():
			global_position = target_pos
		else:
			position = target_pos
		rotation.y = target_rot_y
		previous_position = target_pos
		previous_rotation_y = target_rot_y
		target_position = target_pos
		target_rotation_y = target_rot_y
		interpolation_elapsed = INTERPOLATION_PERIOD
		return
	
	previous_position = current_pos
	previous_rotation_y = current_rot_y
	target_position = target_pos
	target_rotation_y = target_rot_y
	interpolation_elapsed = 0.0

func _process(delta: float) -> void:
	if interpolation_elapsed < INTERPOLATION_PERIOD:
		interpolation_elapsed += delta
		var t: float = clampf(interpolation_elapsed / INTERPOLATION_PERIOD, 0.0, 1.0)
		
		# Smooth cubic Hermite interpolation curve (smoothstep): S(t) = 3t^2 - 2t^3
		var hermite_t: float = t * t * (3.0 - 2.0 * t)
		
		var interp_pos: Vector3 = previous_position.lerp(target_position, hermite_t)
		var interp_rot_y: float = lerp_angle(previous_rotation_y, target_rotation_y, hermite_t)
		
		if is_inside_tree():
			global_position = interp_pos
		else:
			position = interp_pos
		rotation.y = interp_rot_y
	else:
		if is_inside_tree():
			global_position = target_position
		else:
			position = target_position
		rotation.y = target_rotation_y

## Updates the 3D billboard text displaying identity, wallet, and status.
func update_overhead_label() -> void:
	if overhead_label == null and has_node("OverheadLabel"):
		overhead_label = get_node("OverheadLabel") as Label3D
	if overhead_label == null:
		return
	var formatted_money: String = _format_money(player_balance)
	overhead_label.text = "%s\n%s • %s" % [player_name, formatted_money, player_status]

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
