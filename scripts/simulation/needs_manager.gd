extends Node
## Needs Manager — tracks hunger, energy, hygiene, stress

signal need_changed(need_name: String, value: float)
signal need_critical(need_name: String)

# Need values 0-100 (100 = full/good, 0 = depleted/bad)
var hunger: float = 80.0
var energy: float = 100.0
var hygiene: float = 90.0
var stress: float = 10.0 # Lower is better

# Decay rates per game-hour
var hunger_decay: float = 6.0
var energy_decay: float = 4.0
var hygiene_decay: float = 2.5
var stress_growth: float = 1.5

var _tick_accumulator: float = 0.0

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_tick_accumulator += delta
	# Update needs every real second (= 1 game minute at default speed)
	var tick_interval: float = 1.0
	if _tick_accumulator >= tick_interval:
		_tick_accumulator -= tick_interval
		_update_needs()

func _update_needs() -> void:
	var game_minutes_per_tick: float = 1.0
	var hours_fraction: float = game_minutes_per_tick / 60.0

	hunger = max(0.0, hunger - hunger_decay * hours_fraction)
	energy = max(0.0, energy - energy_decay * hours_fraction)
	hygiene = max(0.0, hygiene - hygiene_decay * hours_fraction)
	stress = min(100.0, stress + stress_growth * hours_fraction)

	need_changed.emit("hunger", hunger)
	need_changed.emit("energy", energy)
	need_changed.emit("hygiene", hygiene)
	need_changed.emit("stress", stress)

	if hunger < 15.0:
		need_critical.emit("hunger")
	if energy < 15.0:
		need_critical.emit("energy")

func eat(restore_amount: float) -> void:
	hunger = min(100.0, hunger + restore_amount)
	need_changed.emit("hunger", hunger)

func rest(restore_amount: float) -> void:
	energy = min(100.0, energy + restore_amount)
	need_changed.emit("energy", energy)

func bathe(restore_amount: float) -> void:
	hygiene = min(100.0, hygiene + restore_amount)
	need_changed.emit("hygiene", hygiene)

func relax(reduce_amount: float) -> void:
	stress = max(0.0, stress - reduce_amount)
	need_changed.emit("stress", stress)

func can_sprint() -> bool:
	return energy > 15.0

func get_work_efficiency() -> float:
	var eff: float = 1.0
	if hunger < 30.0:
		eff *= 0.7
	if energy < 30.0:
		eff *= 0.6
	if stress > 70.0:
		eff *= 0.8
	return eff

func get_save_data() -> Dictionary:
	return {"hunger": hunger, "energy": energy, "hygiene": hygiene, "stress": stress}

func load_save_data(data: Dictionary) -> void:
	hunger = data.get("hunger", 80.0)
	energy = data.get("energy", 100.0)
	hygiene = data.get("hygiene", 90.0)
	stress = data.get("stress", 10.0)
