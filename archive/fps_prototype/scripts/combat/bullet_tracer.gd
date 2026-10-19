class_name BulletTracer
extends Node3D

@export var speed: float = 120.0
var target_pos: Vector3 = Vector3.ZERO
var lifetime: float = 0.5

func initialize(start: Vector3, target: Vector3) -> void:
	global_position = start
	target_pos = target
	look_at(target_pos, Vector3.UP)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	var step = speed * delta
	var to_target = target_pos - global_position
	if to_target.length() <= step:
		global_position = target_pos
		queue_free()
	else:
		global_position += to_target.normalized() * step
