extends Node
class_name DeliveryRunner
## Delivery Runner — Courier and parcel delivery gameplay loop for Yangon Life
##
## Manages delivery order lifecycle: assignment -> depot pickup -> transit -> drop-off.
## Integrates with EconomyManager for payouts (8,000 MMK base + tips),
## SkillManager for driving and customer service XP, and InventoryManager for parcel tracking.

signal order_assigned(order: Dictionary)
signal order_picked_up(order: Dictionary)
signal order_delivered(payout: int, tip: int)
signal order_failed(reason: String)
signal order_cancelled
signal timer_ticked(remaining_minutes: float)

enum OrderState {
	IDLE,
	ASSIGNED,
	PICKED_UP,
	DELIVERED,
	EXPIRED
}

const DEPOT_LOCATIONS: Array[String] = [
	"Botahtaung Jetty Logistics Depot",
	"Pansodan Wholesale Distribution Hub",
	"Theingyizay Cargo Yard",
	"Sule Central Dispatch Point"
]

const DROPOFF_LOCATIONS: Array[String] = [
	"Merchant Street Colonial Tenement #12",
	"Anawrahta Road Residence #402",
	"Maha Bandula Cafe Corner",
	"Strand Road Commercial Office",
	"Seikkan Township Riverfront Apt"
]

const DEFAULT_BASE_PAY: int = 8000
const DEFAULT_TIME_LIMIT: float = 60.0 # Game minutes
const BASE_DRIVING_XP: float = 35.0
const BASE_CUSTOMER_SERVICE_XP: float = 25.0

var current_state: OrderState = OrderState.IDLE
var active_order: Dictionary = {}

func _ready() -> void:
	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_signal("time_tick"):
		time_node.time_tick.connect(_on_time_tick)

## Generates a new delivery order specification dictionary
func create_order(
	depot: String = "",
	dropoff: String = "",
	time_limit: float = DEFAULT_TIME_LIMIT,
	base_pay: int = DEFAULT_BASE_PAY
) -> Dictionary:
	var chosen_depot: String = depot
	if chosen_depot == "":
		chosen_depot = DEPOT_LOCATIONS[randi() % DEPOT_LOCATIONS.size()]

	var chosen_dropoff: String = dropoff
	if chosen_dropoff == "":
		chosen_dropoff = DROPOFF_LOCATIONS[randi() % DROPOFF_LOCATIONS.size()]

	return {
		"id": "del_%d" % randi_range(1000, 9999),
		"depot": chosen_depot,
		"dropoff": chosen_dropoff,
		"base_pay": base_pay,
		"time_limit": time_limit,
		"time_remaining": time_limit,
		"driving_xp": BASE_DRIVING_XP,
		"customer_service_xp": BASE_CUSTOMER_SERVICE_XP,
		"distance_km": roundf(randf_range(1.5, 4.5) * 10.0) / 10.0
	}

## Accepts an order and sets state to ASSIGNED
func accept_order(order: Dictionary = {}) -> bool:
	if current_state != OrderState.IDLE:
		print_rich("[color=yellow][DeliveryRunner] Already handling an active delivery.[/color]")
		return false

	if order.is_empty():
		active_order = create_order()
	else:
		active_order = order.duplicate(true)

	if not active_order.has("time_remaining"):
		active_order["time_remaining"] = active_order.get("time_limit", DEFAULT_TIME_LIMIT)

	current_state = OrderState.ASSIGNED
	print_rich("[color=green][DeliveryRunner] Accepted delivery order '%s' from %s to %s.[/color]" % [
		active_order.get("id", ""),
		active_order.get("depot", ""),
		active_order.get("dropoff", "")
	])
	order_assigned.emit(active_order)
	return true

## Simulates parcel collection at the pickup depot
func pickup_package() -> bool:
	if current_state != OrderState.ASSIGNED:
		print_rich("[color=yellow][DeliveryRunner] Cannot pick up parcel: Current state is %d.[/color]" % current_state)
		return false

	current_state = OrderState.PICKED_UP

	# Add parcel to inventory if InventoryManager is loaded
	var inv_node := get_node_or_null("/root/InventoryManager")
	if inv_node and inv_node.has_method("add_item"):
		inv_node.call("add_item", "delivery_parcel", 1)

	print_rich("[color=green][DeliveryRunner] Collected parcel for order '%s'. Proceed to drop-off.[/color]" % active_order.get("id", ""))
	order_picked_up.emit(active_order)
	return true

## Delivers parcel to drop-off waypoint, awards MMK wage + tips + skill XP
func deliver_package() -> bool:
	if current_state != OrderState.PICKED_UP:
		print_rich("[color=yellow][DeliveryRunner] Cannot deliver parcel: Package not picked up yet.[/color]" % [])
		return false

	var base_pay: int = int(active_order.get("base_pay", DEFAULT_BASE_PAY))
	var time_limit: float = float(active_order.get("time_limit", DEFAULT_TIME_LIMIT))
	var time_rem: float = float(active_order.get("time_remaining", 0.0))

	# Punctuality speed bonus: faster delivery yields higher base tip (up to 2,000 MMK)
	var speed_ratio: float = clampf(time_rem / maxf(1.0, time_limit), 0.0, 1.0)
	var base_tip: int = int(round(speed_ratio * 2000.0))

	# Customer service skill tip bonus
	var tip_mult: float = 1.0
	var sm_node := get_node_or_null("/root/SkillManager")
	if sm_node and sm_node.has_method("get_customer_service_tip_bonus"):
		tip_mult += float(sm_node.call("get_customer_service_tip_bonus"))

	var tip: int = int(round(float(base_tip) * tip_mult))
	var total_payout: int = base_pay + tip

	# Payout via EconomyManager
	var econ_node := get_node_or_null("/root/EconomyManager")
	if econ_node and econ_node.has_method("add_money"):
		econ_node.call("add_money", total_payout, "Delivery Payout: %s" % active_order.get("id", ""))

	# Grant XP via SkillManager
	if sm_node and sm_node.has_method("add_xp"):
		sm_node.call("add_xp", "driving", float(active_order.get("driving_xp", BASE_DRIVING_XP)))
		sm_node.call("add_xp", "customer_service", float(active_order.get("customer_service_xp", BASE_CUSTOMER_SERVICE_XP)))

	# Remove parcel from InventoryManager
	var inv_node := get_node_or_null("/root/InventoryManager")
	if inv_node and inv_node.has_method("remove_item"):
		inv_node.call("remove_item", "delivery_parcel", 1)

	# NeedsManager: courier work expends energy
	var needs_node := get_node_or_null("/root/NeedsManager")
	if needs_node and needs_node.has_method("rest"):
		needs_node.energy = maxf(0.0, needs_node.energy - 8.0)
		needs_node.need_changed.emit("energy", needs_node.energy)

	print_rich("[color=green][DeliveryRunner] Delivery completed! Earned %d MMK (Base: %d, Tip: %d).[/color]" % [total_payout, base_pay, tip])
	order_delivered.emit(total_payout, tip)

	active_order = {}
	current_state = OrderState.IDLE
	return true

## Cancels current active delivery without reward
func cancel_order() -> void:
	if current_state == OrderState.IDLE:
		return

	var inv_node := get_node_or_null("/root/InventoryManager")
	if inv_node and inv_node.has_method("remove_item") and current_state == OrderState.PICKED_UP:
		inv_node.call("remove_item", "delivery_parcel", 1)

	active_order = {}
	current_state = OrderState.IDLE
	print_rich("[color=yellow][DeliveryRunner] Active delivery cancelled.[/color]")
	order_cancelled.emit()

## Fails the current delivery order (e.g. timeout)
func fail_order(reason: String = "Delivery time limit expired") -> void:
	if current_state == OrderState.IDLE:
		return

	var inv_node := get_node_or_null("/root/InventoryManager")
	if inv_node and inv_node.has_method("remove_item") and current_state == OrderState.PICKED_UP:
		inv_node.call("remove_item", "delivery_parcel", 1)

	print_rich("[color=red][DeliveryRunner] Delivery failed: %s[/color]" % reason)
	order_failed.emit(reason)
	active_order = {}
	current_state = OrderState.IDLE

## Advances delivery timer by specified game minutes
func advance_timer(minutes: float) -> void:
	if current_state != OrderState.ASSIGNED and current_state != OrderState.PICKED_UP:
		return

	var rem: float = float(active_order.get("time_remaining", 0.0)) - minutes
	active_order["time_remaining"] = rem
	timer_ticked.emit(rem)

	if rem <= 0.0:
		fail_order("Time limit expired")

func _on_time_tick(_hour: int, _minute: int) -> void:
	advance_timer(1.0)
