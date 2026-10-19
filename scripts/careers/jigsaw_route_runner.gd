class_name JigsawRouteRunner
extends Node
## Jigsaw Driver Feeder Route Transit System for Yangon Life.
##
## Simulates fixed-route public transit pickup and dropoff loops
## across central Downtown Yangon landmarks (Sule, Maha Bandula, Botahtaung, Chinatown).

signal route_started
signal stop_reached(stop_index: int, stop_name: String, passengers: int, earnings: int)
signal route_completed(total_bonus: int, total_earnings: int)

const STOPS: Array[Dictionary] = [
	{
		"name": "Sule Roundabout (Origin)",
		"position": Vector3(0.0, 0.0, 0.0),
		"passengers": 4,
		"fare": 500
	},
	{
		"name": "Maha Bandula Park East",
		"position": Vector3(25.0, 0.0, 35.0),
		"passengers": 5,
		"fare": 500
	},
	{
		"name": "Botahtaung Jetty Approach",
		"position": Vector3(60.0, 0.0, -40.0),
		"passengers": 6,
		"fare": 600
	},
	{
		"name": "Chinatown Market Junction",
		"position": Vector3(-50.0, 0.0, 10.0),
		"passengers": 5,
		"fare": 600
	}
]

@export var completion_bonus: int = 3500

var is_active: bool = false
var current_stop_index: int = 0
var route_earnings: int = 0

## Starts the scheduled feeder route beginning at Sule Roundabout
func start_route() -> void:
	is_active = true
	current_stop_index = 0
	route_earnings = 0
	route_started.emit()

## Processes passenger boarding and alighting at a designated route stop
## Returns the stop earnings in Myanmar Kyat (MMK)
func reach_stop(stop_index: int) -> int:
	if stop_index < 0 or stop_index >= STOPS.size():
		return 0

	is_active = true
	var stop_data: Dictionary = STOPS[stop_index]
	var passengers: int = int(stop_data.get("passengers", 4))
	var fare_rate: int = int(stop_data.get("fare", 500))
	var stop_earnings: int = passengers * fare_rate

	# Scale earnings by driver work efficiency if NeedsManager is present
	var efficiency: float = 1.0
	if is_inside_tree():
		var nm: Node = get_node_or_null("/root/NeedsManager")
		if nm and nm.has_method("get_work_efficiency"):
			efficiency = float(nm.call("get_work_efficiency"))
	stop_earnings = int(round(float(stop_earnings) * efficiency))

	route_earnings += stop_earnings

	# Deposit earnings into player MMK wallet
	if is_inside_tree():
		var em: Node = get_node_or_null("/root/EconomyManager")
		if em and em.has_method("add_money"):
			var stop_title: String = str(stop_data.get("name", "Stop"))
			em.call("add_money", stop_earnings, "Jigsaw Fare: %s" % stop_title)

	current_stop_index = stop_index + 1
	var sname: String = str(stop_data.get("name", ""))
	stop_reached.emit(stop_index, sname, passengers, stop_earnings)

	return stop_earnings

## Completes the full route, awards completion bonus, and returns the bonus amount
func complete_route() -> int:
	var bonus: int = completion_bonus
	if is_inside_tree():
		var em: Node = get_node_or_null("/root/EconomyManager")
		if em and em.has_method("add_money"):
			em.call("add_money", bonus, "Jigsaw Route Bonus")

	var total_earned: int = route_earnings + bonus
	route_completed.emit(bonus, total_earned)

	is_active = false
	current_stop_index = STOPS.size()
	return bonus

## Returns the name of the next destination stop along the route
func get_current_stop_name() -> String:
	if current_stop_index >= STOPS.size():
		return "Route Complete"
	if not is_active:
		return "No Active Route"
	return str(STOPS[current_stop_index]["name"])

## Returns progress along the route between 0.0 and 1.0
func get_route_progress() -> float:
	if STOPS.is_empty():
		return 0.0
	return clampf(float(current_stop_index) / float(STOPS.size()), 0.0, 1.0)

## Returns list of all defined route stop dictionaries
func get_stops() -> Array[Dictionary]:
	return STOPS.duplicate(true)

## Exports route state for save persistence
func get_save_data() -> Dictionary:
	return {
		"is_active": is_active,
		"current_stop_index": current_stop_index,
		"route_earnings": route_earnings
	}

## Restores route state from save dictionary
func load_save_data(data: Dictionary) -> void:
	is_active = bool(data.get("is_active", false))
	current_stop_index = int(data.get("current_stop_index", 0))
	route_earnings = int(data.get("route_earnings", 0))
