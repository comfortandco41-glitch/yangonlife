extends Node
class_name TaxiShiftRunner
## Taxi Shift Runner — Urban taxi transportation loop for Yangon Life
##
## Simulates cruising Yangon thoroughfares, roadside passenger flag-downs,
## distance-based metered fares, fuel consumption adjustments, and driving XP.

signal shift_started
signal shift_ended(total_earnings: int, trips_completed: int)
signal fare_hailed(fare: Dictionary)
signal passenger_boarded(fare: Dictionary)
signal fare_completed(fare: Dictionary, net_earnings: int)
signal trip_cancelled(reason: String)

enum TaxiState {
	OFF_DUTY,
	CRUISING,
	PASSENGER_ONBOARD,
	ARRIVED
}

const PICKUP_POINTS: Array[String] = [
	"Sule Pagoda Roundabout",
	"Yangon Central Railway Station",
	"Junction City Mall",
	"Bogyoke Aung San Market",
	"Shwedagon Pagoda South Gate",
	"Kandawgyi Lake Garden",
	"Inya Road University Junction",
	"Botahtaung River Jetty",
	"Chinatown 19th Street"
]

const PASSENGER_NAMES: Array[String] = [
	"U Myint",
	"Daw San",
	"Ko Thein",
	"Ma Myat",
	"U Kyaw Aye",
	"Dr. Aung",
	"Ma Nilar"
]

const BASE_FLAG_DROP_FEE: int = 3000
const RATE_PER_KM: int = 2500
const BASE_FUEL_COST_PER_KM: int = 600
const XP_PER_KM: float = 12.0

var current_state: TaxiState = TaxiState.OFF_DUTY
var active_fare: Dictionary = {}
var shift_earnings: int = 0
var trips_completed: int = 0

## Starts the taxi shift, transitioning to CRUISING
func start_shift() -> bool:
	if current_state != TaxiState.OFF_DUTY:
		print_rich("[color=yellow][TaxiShiftRunner] Already on shift.[/color]")
		return false

	# Verify driving certification if SkillManager is available
	var sm_node := get_node_or_null("/root/SkillManager")
	if sm_node and sm_node.has_method("has_skill_level"):
		if not bool(sm_node.call("has_skill_level", "driving", 1)):
			print_rich("[color=yellow][TaxiShiftRunner] Cannot start shift: Requires Driving skill level 1.[/color]")
			return false

	current_state = TaxiState.CRUISING
	shift_earnings = 0
	trips_completed = 0
	active_fare.clear()
	print_rich("[color=green][TaxiShiftRunner] Started taxi shift. Cruising for fares.[/color]")
	shift_started.emit()
	return true

## Ends the active taxi shift and reports aggregate results
func end_shift() -> void:
	if current_state == TaxiState.OFF_DUTY:
		return

	if not active_fare.is_empty():
		cancel_trip("Shift ended while on trip")

	current_state = TaxiState.OFF_DUTY
	print_rich("[color=cyan][TaxiShiftRunner] Shift ended. Completed %d trips, Net earnings: %d MMK.[/color]" % [trips_completed, shift_earnings])
	shift_ended.emit(shift_earnings, trips_completed)

## Generates a roadside fare flag-down request
func generate_hail(
	passenger: String = "",
	pickup: String = "",
	destination: String = "",
	distance: float = 0.0
) -> Dictionary:
	var pass_name: String = passenger
	if pass_name == "":
		pass_name = PASSENGER_NAMES[randi() % PASSENGER_NAMES.size()]

	var p_pickup: String = pickup
	if p_pickup == "":
		p_pickup = PICKUP_POINTS[randi() % PICKUP_POINTS.size()]

	var p_dest: String = destination
	if p_dest == "":
		var candidate: String = PICKUP_POINTS[randi() % PICKUP_POINTS.size()]
		while candidate == p_pickup and PICKUP_POINTS.size() > 1:
			candidate = PICKUP_POINTS[randi() % PICKUP_POINTS.size()]
		p_dest = candidate

	var dist_km: float = distance
	if dist_km <= 0.0:
		dist_km = roundf(randf_range(2.0, 7.5) * 10.0) / 10.0

	var fare_estimate: int = BASE_FLAG_DROP_FEE + int(round(dist_km * float(RATE_PER_KM)))

	return {
		"id": "fare_%d" % randi_range(100, 999),
		"passenger_name": pass_name,
		"pickup": p_pickup,
		"destination": p_dest,
		"distance_km": dist_km,
		"estimated_fare": fare_estimate
	}

## Accepts a passenger hail and sets it as active fare
func accept_hail(fare: Dictionary = {}) -> bool:
	if current_state != TaxiState.CRUISING:
		print_rich("[color=yellow][TaxiShiftRunner] Cannot accept hail: Current state is %d.[/color]" % current_state)
		return false

	if fare.is_empty():
		active_fare = generate_hail()
	else:
		active_fare = fare.duplicate(true)

	print_rich("[color=green][TaxiShiftRunner] Accepted fare for %s (%s -> %s, %.1f km).[/color]" % [
		active_fare.get("passenger_name", ""),
		active_fare.get("pickup", ""),
		active_fare.get("destination", ""),
		float(active_fare.get("distance_km", 0.0))
	])
	fare_hailed.emit(active_fare)
	return true

## Simulates passenger boarding the taxi vehicle
func board_passenger() -> bool:
	if active_fare.is_empty() or current_state != TaxiState.CRUISING:
		return false

	current_state = TaxiState.PASSENGER_ONBOARD
	print_rich("[color=green][TaxiShiftRunner] Passenger %s boarded. En route to %s.[/color]" % [
		active_fare.get("passenger_name", ""),
		active_fare.get("destination", "")
	])
	passenger_boarded.emit(active_fare)
	return true

## Completes the taxi trip, calculates gross fare + tip - fuel expense, awards driving XP
func complete_trip(satisfaction_score: float = 1.0) -> int:
	if current_state != TaxiState.PASSENGER_ONBOARD:
		print_rich("[color=yellow][TaxiShiftRunner] Cannot complete trip: No passenger onboard.[/color]")
		return 0

	var dist_km: float = float(active_fare.get("distance_km", 3.0))
	var base_gross: int = BASE_FLAG_DROP_FEE + int(round(dist_km * float(RATE_PER_KM)))

	# Tip calculation based on satisfaction and customer_service skill
	var tip_mult: float = 0.0
	var sm_node := get_node_or_null("/root/SkillManager")
	if sm_node and sm_node.has_method("get_customer_service_tip_bonus"):
		tip_mult = float(sm_node.call("get_customer_service_tip_bonus"))

	var tip: int = int(round(float(base_gross) * 0.15 * clampf(satisfaction_score, 0.0, 1.0) * (1.0 + tip_mult)))

	# Fuel cost deduction adjusted by driving skill
	var fuel_mult: float = 1.0
	if sm_node and sm_node.has_method("get_driving_fuel_multiplier"):
		fuel_mult = float(sm_node.call("get_driving_fuel_multiplier"))

	var fuel_cost: int = int(round(dist_km * float(BASE_FUEL_COST_PER_KM) * fuel_mult))
	var net_earned: int = maxi(1000, base_gross + tip - fuel_cost)

	# Deposit net earnings to EconomyManager
	var econ_node := get_node_or_null("/root/EconomyManager")
	if econ_node and econ_node.has_method("add_money"):
		econ_node.call("add_money", net_earned, "Taxi Fare: %s (Net after fuel)" % active_fare.get("passenger_name", "Passenger"))

	# Award driving XP
	if sm_node and sm_node.has_method("add_xp"):
		sm_node.call("add_xp", "driving", dist_km * XP_PER_KM)
		sm_node.call("add_xp", "customer_service", 8.0)

	# NeedsManager: driving drains some energy
	var needs_node := get_node_or_null("/root/NeedsManager")
	if needs_node and needs_node.has_method("rest"):
		needs_node.energy = maxf(0.0, needs_node.energy - dist_km * 1.5)
		needs_node.need_changed.emit("energy", needs_node.energy)

	shift_earnings += net_earned
	trips_completed += 1

	print_rich("[color=green][TaxiShiftRunner] Trip completed! Net: %d MMK (Gross: %d, Tip: %d, Fuel: -%d).[/color]" % [
		net_earned, base_gross, tip, fuel_cost
	])
	fare_completed.emit(active_fare, net_earned)

	active_fare.clear()
	current_state = TaxiState.CRUISING
	return net_earned

## Cancels current trip
func cancel_trip(reason: String = "Passenger cancelled") -> void:
	if active_fare.is_empty():
		return

	print_rich("[color=yellow][TaxiShiftRunner] Trip cancelled: %s[/color]" % reason)
	trip_cancelled.emit(reason)
	active_fare.clear()
	if current_state != TaxiState.OFF_DUTY:
		current_state = TaxiState.CRUISING
