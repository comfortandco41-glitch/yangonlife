extends Node
class_name StreetVendorRunner
## Street Vendor Runner — Food stall culinary gameplay loop for Yangon Life
##
## Simulates street food vending in bustling downtown alleys:
## Manages incoming customer orders (Mohinga, Shan Noodles, Tea Set, Combo),
## tracks customer patience timers, food prep, and payouts (5,000 - 12,000 MMK) + cooking XP.

signal stall_opened
signal stall_closed(total_earnings: int, orders_served: int)
signal order_received(order: Dictionary)
signal order_prepared(order: Dictionary)
signal order_served(order: Dictionary, payout: int)
signal order_expired(order: Dictionary)

const MENU_ITEMS: Dictionary = {
	"mohinga": {
		"id": "mohinga",
		"name": "Hot Mohinga Bowl",
		"base_price": 5000,
		"max_price": 7500,
		"prep_time": 15.0,
		"patience": 45.0,
		"cooking_xp": 30.0
	},
	"shan_noodles": {
		"id": "shan_noodles",
		"name": "Shan Noodles Deluxe",
		"base_price": 6000,
		"max_price": 9500,
		"prep_time": 20.0,
		"patience": 50.0,
		"cooking_xp": 40.0
	},
	"tea_set": {
		"id": "tea_set",
		"name": "Laphet Yay & Fried Samosas",
		"base_price": 5000,
		"max_price": 7000,
		"prep_time": 10.0,
		"patience": 35.0,
		"cooking_xp": 25.0
	},
	"special_combo": {
		"id": "special_combo",
		"name": "Yangon Heritage Feast Set",
		"base_price": 8500,
		"max_price": 12000,
		"prep_time": 25.0,
		"patience": 60.0,
		"cooking_xp": 50.0
	}
}

const CUSTOMER_NAMES: Array[String] = [
	"Ko Aung",
	"Ma Hnin",
	"Uncle Tin",
	"Daw Khin",
	"Ko Kyaw",
	"Ma Thida",
	"Sayar Min"
]

var is_stall_open: bool = false
var active_orders: Array[Dictionary] = []
var total_earnings: int = 0
var orders_served_count: int = 0
var max_concurrent_orders: int = 3

func _ready() -> void:
	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_signal("time_tick"):
		time_node.time_tick.connect(_on_time_tick)

## Opens the street vendor stall for business
func open_stall() -> bool:
	if is_stall_open:
		return false
	is_stall_open = true
	total_earnings = 0
	orders_served_count = 0
	active_orders.clear()
	print_rich("[color=green][StreetVendorRunner] Food stall opened for business.[/color]")
	stall_opened.emit()
	return true

## Closes the stall and finalizes the shift summary
func close_stall() -> void:
	if not is_stall_open:
		return
	is_stall_open = false
	active_orders.clear()
	print_rich("[color=cyan][StreetVendorRunner] Stall closed. Served: %d customers, Total earned: %d MMK.[/color]" % [orders_served_count, total_earnings])
	stall_closed.emit(total_earnings, orders_served_count)

## Generates and registers an incoming customer food order
func spawn_order(dish_id: String = "") -> Dictionary:
	if not is_stall_open:
		print_rich("[color=yellow][StreetVendorRunner] Cannot spawn order: Stall is closed.[/color]")
		return {}

	if active_orders.size() >= max_concurrent_orders:
		print_rich("[color=yellow][StreetVendorRunner] Stall queue is full.[/color]")
		return {}

	var chosen_id: String = dish_id
	if chosen_id == "" or not MENU_ITEMS.has(chosen_id):
		var keys: Array = MENU_ITEMS.keys()
		chosen_id = str(keys[randi() % keys.size()])

	var item_def: Dictionary = MENU_ITEMS[chosen_id]
	var customer_name: String = CUSTOMER_NAMES[randi() % CUSTOMER_NAMES.size()]

	var order: Dictionary = {
		"id": "ord_%d" % randi_range(100, 999),
		"dish_id": chosen_id,
		"dish_name": item_def.get("name", "Street Food"),
		"customer_name": customer_name,
		"base_price": int(item_def.get("base_price", 5000)),
		"max_price": int(item_def.get("max_price", 8000)),
		"patience": float(item_def.get("patience", 45.0)),
		"time_remaining": float(item_def.get("patience", 45.0)),
		"prep_time": float(item_def.get("prep_time", 15.0)),
		"prep_progress": 0.0,
		"is_prepared": false,
		"cooking_xp": float(item_def.get("cooking_xp", 30.0))
	}

	active_orders.append(order)
	print_rich("[color=green][StreetVendorRunner] Customer %s ordered %s![/color]" % [customer_name, order["dish_name"]])
	order_received.emit(order)
	return order

## Prepares the dish for the specified order index
func prepare_order(order_index: int = 0) -> bool:
	if order_index < 0 or order_index >= active_orders.size():
		return false

	var order: Dictionary = active_orders[order_index]
	order["is_prepared"] = true
	order["prep_progress"] = order.get("prep_time", 15.0)

	print_rich("[color=green][StreetVendorRunner] Prepared %s for %s.[/color]" % [order.get("dish_name", ""), order.get("customer_name", "")])
	order_prepared.emit(order)
	return true

## Serves a prepared dish to customer, calculates earnings (5k - 12k MMK) + cooking XP
func serve_order(order_index: int = 0) -> int:
	if order_index < 0 or order_index >= active_orders.size():
		return 0

	var order: Dictionary = active_orders[order_index]
	if not bool(order.get("is_prepared", false)):
		print_rich("[color=yellow][StreetVendorRunner] Cannot serve: Dish is not prepared yet![/color]")
		return 0

	var base_price: int = int(order.get("base_price", 5000))
	var max_price: int = int(order.get("max_price", 8000))

	# Cooking skill margin bonus
	var margin_bonus: float = 0.0
	var sm_node := get_node_or_null("/root/SkillManager")
	if sm_node and sm_node.has_method("get_cooking_margin_bonus"):
		margin_bonus = float(sm_node.call("get_cooking_margin_bonus"))

	# Customer satisfaction multiplier based on remaining patience
	var patience_max: float = float(order.get("patience", 45.0))
	var patience_rem: float = float(order.get("time_remaining", patience_max))
	var satisfaction: float = clampf(patience_rem / maxf(1.0, patience_max), 0.3, 1.0)

	var calculated_price: float = float(base_price) + float(max_price - base_price) * satisfaction
	calculated_price *= (1.0 + margin_bonus)

	var final_payout: int = clampi(int(round(calculated_price)), 5000, 12000)

	# Credit MMK to EconomyManager
	var econ_node := get_node_or_null("/root/EconomyManager")
	if econ_node and econ_node.has_method("add_money"):
		econ_node.call("add_money", final_payout, "Food Stall: %s" % order.get("dish_name", ""))

	# Award cooking XP via SkillManager
	if sm_node and sm_node.has_method("add_xp"):
		sm_node.call("add_xp", "cooking", float(order.get("cooking_xp", 30.0)))
		# Customer service minor XP
		sm_node.call("add_xp", "customer_service", 10.0)

	total_earnings += final_payout
	orders_served_count += 1

	active_orders.remove_at(order_index)
	print_rich("[color=green][StreetVendorRunner] Served %s to %s! Earned %d MMK.[/color]" % [order.get("dish_name", ""), order.get("customer_name", ""), final_payout])
	order_served.emit(order, final_payout)
	return final_payout

## Advances order patience timers and handles customer timeouts
func advance_order_timers(delta_time: float) -> void:
	if not is_stall_open:
		return

	var expired_indices: Array[int] = []
	for i: int in range(active_orders.size()):
		var order: Dictionary = active_orders[i]
		var rem: float = float(order.get("time_remaining", 0.0)) - delta_time
		order["time_remaining"] = rem
		if rem <= 0.0:
			expired_indices.append(i)

	# Remove expired orders in reverse order
	expired_indices.reverse()
	for idx: int in expired_indices:
		var expired_order: Dictionary = active_orders[idx]
		active_orders.remove_at(idx)
		print_rich("[color=red][StreetVendorRunner] Customer %s left impatiently! Order for %s lost.[/color]" % [expired_order.get("customer_name", ""), expired_order.get("dish_name", "")])
		order_expired.emit(expired_order)

func _on_time_tick(_hour: int, _minute: int) -> void:
	if is_stall_open:
		advance_order_timers(1.0)
