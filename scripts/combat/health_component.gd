class_name HealthComponent
extends Node

signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float, source_team: int)
signal died(killer_team: int)

@export var max_health: float = 100.0
@export var team_id: int = 0

var current_health: float = 100.0
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, source_team: int = 0) -> void:
	if is_dead or amount <= 0.0:
		return

	current_health = max(0.0, current_health - amount)
	damaged.emit(amount, source_team)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0 and not is_dead:
		is_dead = true
		died.emit(source_team)

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func reset() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
