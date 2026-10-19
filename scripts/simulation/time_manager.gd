extends Node
## Time Manager — In-game clock and day/night cycle progression
##
## Controls game time flow (default 1 real second = 1 game minute).
## Emits tick, hourly, and daily signals for other simulation systems.

signal time_tick(hour: int, minute: int)
signal hour_changed(hour: int)
signal day_changed(day: int)

## Duration in real seconds for one game minute to pass
@export var seconds_per_game_minute: float = 1.0

## Multiplier for time progression speed (1.0 = normal, 2.0 = double, 0.0 = stopped)
@export var time_scale: float = 1.0

var game_hour: int = 8
var game_minute: int = 0
var game_day: int = 1

var _tick_accumulator: float = 0.0

func _process(delta: float) -> void:
	if get_tree().paused or time_scale <= 0.0:
		return

	_tick_accumulator += delta * time_scale
	while _tick_accumulator >= seconds_per_game_minute:
		_tick_accumulator -= seconds_per_game_minute
		_advance_one_minute()

func _advance_one_minute() -> void:
	game_minute += 1
	var hour_did_change: bool = false
	var day_did_change: bool = false

	if game_minute >= 60:
		game_minute = 0
		game_hour += 1
		hour_did_change = true
		if game_hour >= 24:
			game_hour = 0
			game_day += 1
			day_did_change = true

	if day_did_change:
		day_changed.emit(game_day)
	if hour_did_change:
		hour_changed.emit(game_hour)

	time_tick.emit(game_hour, game_minute)

## Returns current game time in 'HH:MM' string format
func get_time_string() -> String:
	return "%02d:%02d" % [game_hour, game_minute]

## Returns day period: 'morning' (06:00-11:59), 'afternoon' (12:00-16:59), 'evening' (17:00-20:59), or 'night' (21:00-05:59)
func get_day_period() -> String:
	if game_hour >= 6 and game_hour < 12:
		return "morning"
	elif game_hour >= 12 and game_hour < 17:
		return "afternoon"
	elif game_hour >= 17 and game_hour < 21:
		return "evening"
	else:
		return "night"

## Returns whether current time is daytime (06:00 - 18:00)
func is_daytime() -> bool:
	return game_hour >= 6 and game_hour < 18

## Fast-forwards game time by specified minutes (used for sleep, work shifts, transit)
func advance_time(minutes: int) -> void:
	if minutes <= 0:
		return
	for i: int in range(minutes):
		_advance_one_minute()

## Manually sets specific time
func set_time(hour: int, minute: int, day: int = -1) -> void:
	game_hour = clampi(hour, 0, 23)
	game_minute = clampi(minute, 0, 59)
	if day > 0:
		game_day = day
	_tick_accumulator = 0.0
	hour_changed.emit(game_hour)
	time_tick.emit(game_hour, game_minute)

## Sets the time progression scale
func set_time_scale(new_scale: float) -> void:
	time_scale = maxf(0.0, new_scale)

## Serializes state for save game
func get_save_data() -> Dictionary:
	return {
		"hour": game_hour,
		"minute": game_minute,
		"day": game_day,
		"time_scale": time_scale
	}

## Restores state from save game
func load_save_data(data: Dictionary) -> void:
	game_hour = clampi(int(data.get("hour", 8)), 0, 23)
	game_minute = clampi(int(data.get("minute", 0)), 0, 59)
	game_day = maxi(1, int(data.get("day", 1)))
	time_scale = maxf(0.0, float(data.get("time_scale", 1.0)))
	_tick_accumulator = 0.0

	day_changed.emit(game_day)
	hour_changed.emit(game_hour)
	time_tick.emit(game_hour, game_minute)
