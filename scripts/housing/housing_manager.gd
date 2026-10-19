extends Node
## Housing Manager — Housing tiers, tenancy, and rest system for Yangon Life
##
## Manages living arrangements across 5 tiers:
## tier_0_bench, tier_1_hostel, tier_2_shophouse, tier_3_apartment, tier_4_heritage.
## Handles leasing, rent payments, eviction safety net, and sleep restoration.

signal housing_tier_changed(new_tier: String)
signal rent_paid(amount: int)
signal slept(hours: int)
signal evicted

const HOUSING_TIERS: Dictionary = {
	"tier_0_bench": {
		"id": "tier_0_bench",
		"name": "Park Bench / Street",
		"rent": 0,
		"is_daily": false,
		"purchase_cost": 0,
		"energy_recovery_rate": 0.5,
		"hygiene_decay_multiplier": 1.5,
		"hygiene_recovery": 0.0,
		"description": "Sleeping rough on park benches. Zero rent, poor rest, and exposure to street dust."
	},
	"tier_1_hostel": {
		"id": "tier_1_hostel",
		"name": "Mahabandula Hostel Bunk",
		"rent": 5000,
		"is_daily": true,
		"purchase_cost": 0,
		"energy_recovery_rate": 1.0,
		"hygiene_decay_multiplier": 1.0,
		"hygiene_recovery": 30.0,
		"description": "Shared dormitory bunk near Maha Bandula Park. Modest rest and communal shower."
	},
	"tier_2_shophouse": {
		"id": "tier_2_shophouse",
		"name": "Colonial Shophouse Upper Room",
		"rent": 150000,
		"is_daily": false, # Monthly (30 game days)
		"purchase_cost": 0,
		"energy_recovery_rate": 1.4,
		"hygiene_decay_multiplier": 0.8,
		"hygiene_recovery": 60.0,
		"description": "Private upper room in historical downtown shophouse with private shower and kitchen."
	},
	"tier_3_apartment": {
		"id": "tier_3_apartment",
		"name": "Downtown Modern Apartment",
		"rent": 350000,
		"is_daily": false, # Monthly (30 game days)
		"purchase_cost": 0,
		"energy_recovery_rate": 2.0,
		"hygiene_decay_multiplier": 0.6,
		"hygiene_recovery": 80.0,
		"description": "Modern downtown flat with air conditioning, backup generator, and luxury amenities."
	},
	"tier_4_heritage": {
		"id": "tier_4_heritage",
		"name": "Heritage Shophouse (Owned)",
		"rent": 0,
		"is_daily": false,
		"purchase_cost": 50000000,
		"energy_recovery_rate": 2.5,
		"hygiene_decay_multiplier": 0.5,
		"hygiene_recovery": 100.0,
		"description": "Magnificent owned colonial heritage property. Maximum comfort, permanent asset, zero rent."
	}
}

var current_housing_tier: String = "tier_0_bench"
var rent_due_day: int = 1

func _ready() -> void:
	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_signal("day_changed"):
		time_node.day_changed.connect(_on_day_changed)

## Returns tier data dictionary for the active property
func get_current_tier_data() -> Dictionary:
	if HOUSING_TIERS.has(current_housing_tier):
		return (HOUSING_TIERS[current_housing_tier] as Dictionary).duplicate(true)
	return (HOUSING_TIERS["tier_0_bench"] as Dictionary).duplicate(true)

## Returns dictionary of all housing tier definitions
func get_all_tiers() -> Dictionary:
	return HOUSING_TIERS.duplicate(true)

## Rents or purchases a property tier by ID if player has required funds
func rent_property(tier_id: String) -> bool:
	if not HOUSING_TIERS.has(tier_id):
		print_rich("[color=red][HousingManager] Invalid housing tier '%s'.[/color]" % tier_id)
		return false

	if tier_id == current_housing_tier:
		return true

	var tier_data: Dictionary = HOUSING_TIERS[tier_id]
	var cost: int = 0
	var is_purchase: bool = (tier_id == "tier_4_heritage")

	if is_purchase:
		cost = int(tier_data.get("purchase_cost", 50000000))
	else:
		cost = int(tier_data.get("rent", 0))

	# Check and spend funds via EconomyManager
	if cost > 0:
		var econ_node := get_node_or_null("/root/EconomyManager")
		if econ_node:
			if not econ_node.can_afford(cost):
				print_rich("[color=yellow][HousingManager] Cannot afford '%s' (Cost: %d MMK).[/color]" % [tier_data.get("name", tier_id), cost])
				return false
			var reason: String = "Property Acquisition: %s" % tier_data.get("name", tier_id) if is_purchase else "Rent Deposit: %s" % tier_data.get("name", tier_id)
			if not econ_node.spend_money(cost, reason):
				return false

	current_housing_tier = tier_id

	var current_day: int = 1
	var time_node := get_node_or_null("/root/TimeManager")
	if time_node:
		current_day = int(time_node.get("game_day"))

	rent_due_day = current_day + (1 if tier_data.get("is_daily", false) else 30)

	print_rich("[color=green][HousingManager] Successfully leased/acquired: %s[/color]" % tier_data.get("name", tier_id))
	housing_tier_changed.emit(current_housing_tier)
	return true

## Deducts rent payment. If unable to pay, evicts player back to tier_0_bench safely.
func pay_rent() -> bool:
	var tier_data := get_current_tier_data()
	var rent_cost: int = int(tier_data.get("rent", 0))

	if rent_cost <= 0:
		return true

	var econ_node := get_node_or_null("/root/EconomyManager")
	if econ_node and econ_node.can_afford(rent_cost):
		var success: bool = econ_node.spend_money(rent_cost, "Rent payment: %s" % tier_data.get("name", ""))
		if success:
			var current_day: int = 1
			var time_node := get_node_or_null("/root/TimeManager")
			if time_node:
				current_day = int(time_node.get("game_day"))
			rent_due_day = current_day + (1 if tier_data.get("is_daily", false) else 30)
			print_rich("[color=green][HousingManager] Paid %d MMK rent for %s.[/color]" % [rent_cost, tier_data.get("name", "")])
			rent_paid.emit(rent_cost)
			return true

	# Default safety net: Eviction to bench without game over
	print_rich("[color=yellow][HousingManager] Defaulted on %d MMK rent. Evicted to park bench![/color]" % rent_cost)
	current_housing_tier = "tier_0_bench"
	housing_tier_changed.emit(current_housing_tier)
	evicted.emit()
	return false

## Sleeps at home for specified hours. Advances time and restores energy/hygiene based on tier.
func sleep_at_home(hours: int) -> void:
	if hours <= 0:
		return

	# Advance game time
	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_method("advance_time"):
		time_node.call("advance_time", hours * 60)

	var tier_data := get_current_tier_data()
	var energy_rate: float = float(tier_data.get("energy_recovery_rate", 1.0))
	var hygiene_rec: float = float(tier_data.get("hygiene_recovery", 0.0))

	var needs_node := get_node_or_null("/root/NeedsManager")
	if needs_node:
		# Energy restoration: 10.0 base energy per hour * tier multiplier
		var energy_to_restore: float = float(hours) * 10.0 * energy_rate
		if needs_node.has_method("rest"):
			needs_node.call("rest", energy_to_restore)

		# Hygiene restoration or decay
		if hygiene_rec > 0.0 and needs_node.has_method("bathe"):
			needs_node.call("bathe", hygiene_rec)
		elif current_housing_tier == "tier_0_bench":
			# Sleeping rough outside incurs hygiene decay
			var penalty: float = float(hours) * 2.0 * float(tier_data.get("hygiene_decay_multiplier", 1.5))
			needs_node.hygiene = maxf(0.0, needs_node.hygiene - penalty)
			needs_node.need_changed.emit("hygiene", needs_node.hygiene)

		# Stress relief
		var stress_relief: float = float(hours) * 4.0 * energy_rate
		if needs_node.has_method("relax"):
			needs_node.call("relax", stress_relief)

	print_rich("[color=green][HousingManager] Slept for %d hours at %s.[/color]" % [hours, tier_data.get("name", "")])
	slept.emit(hours)

func _on_day_changed(new_day: int) -> void:
	var tier_data := get_current_tier_data()
	if int(tier_data.get("rent", 0)) > 0 and new_day >= rent_due_day:
		pay_rent()

## Serializes housing state for save game
func get_save_data() -> Dictionary:
	return {
		"current_housing_tier": current_housing_tier,
		"rent_due_day": rent_due_day
	}

## Restores housing state from save game
func load_save_data(data: Dictionary) -> void:
	current_housing_tier = str(data.get("current_housing_tier", "tier_0_bench"))
	rent_due_day = int(data.get("rent_due_day", 1))
	housing_tier_changed.emit(current_housing_tier)
