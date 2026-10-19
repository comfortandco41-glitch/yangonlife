class_name HitboxComponent
extends Area3D

signal hit_received(amount: float, source_team: int, hit_point: Vector3)

@export var health_component: HealthComponent
@export var team_id: int = 0
@export var damage_multiplier: float = 1.0
@export var allow_friendly_fire: bool = false

func _ready() -> void:
	# Place on physics layer 3 (Hitboxes)
	collision_layer = 4
	collision_mask = 0

func receive_damage(amount: float, source_team: int, hit_point: Vector3 = Vector3.ZERO, _hit_normal: Vector3 = Vector3.ZERO) -> bool:
	# Filter out friendly fire if not permitted
	if not allow_friendly_fire and source_team != 0 and source_team == team_id:
		return false

	var final_damage = amount * damage_multiplier
	hit_received.emit(final_damage, source_team, hit_point)

	if health_component:
		health_component.take_damage(final_damage, source_team)
		return true

	return false
