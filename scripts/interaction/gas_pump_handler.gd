class_name GasPumpHandler
extends Node
## Handles refueling vehicles at Yangon Gas Stations.
##
## Fuel cost: 1,200 MMK per liter.
## Detects motorized vehicles in proximity, calculates fuel capacity needed,
## verifies wallet funds, deducts MMK via EconomyManager, and refuels the vehicle.

const FUEL_PRICE_PER_LITER: int = 1200
const PUMP_RANGE: float = 8.0

@export var fuel_price: int = FUEL_PRICE_PER_LITER

func _ready() -> void:
	var parent := get_parent()
	if parent is Area3D:
		if parent.has_signal("interacted"):
			parent.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	refuel_nearest_vehicle()

## Refuels the closest motorized vehicle within range; returns liters added
func refuel_nearest_vehicle() -> float:
	var parent := get_parent() as Node3D
	var pump_pos: Vector3 = parent.global_position if parent else Vector3(45.0, 0.0, 40.0)

	var target_vehicle: VehicleController = null
	var min_dist: float = PUMP_RANGE

	var tree := get_tree()
	if tree:
		var vehicles := tree.get_nodes_in_group("vehicles")
		for v in vehicles:
			if v is VehicleController and v.is_motorized:
				var d: float = pump_pos.distance_to(v.global_position)
				if d < min_dist:
					min_dist = d
					target_vehicle = v

		if target_vehicle == null:
			for node in tree.root.find_children("*", "VehicleController", true, false):
				if node is VehicleController and node.is_motorized:
					var d: float = pump_pos.distance_to(node.global_position)
					if d < min_dist:
						min_dist = d
						target_vehicle = node

	if target_vehicle == null:
		print("[GasPump] No motorized vehicle nearby to refuel (Range: %.1fm)." % PUMP_RANGE)
		return 0.0

	var needed_fuel: float = target_vehicle.fuel_capacity - target_vehicle.current_fuel
	if needed_fuel <= 0.05:
		print("[GasPump] Vehicle '%s' tank is already full (%.1f L)." % [target_vehicle.vehicle_name, target_vehicle.fuel_capacity])
		return 0.0

	var em: Node = get_node_or_null("/root/EconomyManager")
	var balance: int = 0
	if em and em.has_method("get_balance"):
		balance = int(em.call("get_balance"))

	if balance < fuel_price:
		print("[GasPump] Insufficient funds: 1L costs %d MMK (Current balance: %d MMK)." % [fuel_price, balance])
		return 0.0

	var max_affordable_liters: float = float(balance) / float(fuel_price)
	var liters_to_add: float = minf(needed_fuel, max_affordable_liters)
	var total_cost: int = int(ceil(liters_to_add * float(fuel_price)))

	if em and em.has_method("spend_money"):
		var success: bool = bool(em.call("spend_money", total_cost, "Gas Station: %.1f L" % liters_to_add))
		if not success:
			return 0.0

	var added: float = target_vehicle.refuel(liters_to_add)
	print("[GasPump] Successfully refueled %s with %.1f L for %d MMK." % [target_vehicle.vehicle_name, added, total_cost])
	return added
