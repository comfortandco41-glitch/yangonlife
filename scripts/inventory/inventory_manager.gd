extends Node
## Inventory Manager — Slot-based backpack storage and consumables system for Yangon Life
##
## Manages 16 inventory slots, authentic Yangon item catalog, item addition,
## removal, stacking, and consumption effects with NeedsManager integration.

signal inventory_changed
signal item_used(item_id: String, effects: Dictionary)

const MAX_SLOTS: int = 16

const ITEM_CATALOG: Dictionary = {
	"mohinga": {
		"id": "mohinga",
		"name": "Mohinga",
		"category": "food",
		"hunger_restore": 40.0,
		"value": 2500,
		"description": "Rich lemongrass catfish broth and rice vermicelli noodles",
		"effects": {"hunger": 40.0, "stress": -5.0}
	},
	"shan_noodles": {
		"id": "shan_noodles",
		"name": "Shan Noodles",
		"category": "food",
		"hunger_restore": 35.0,
		"value": 3000,
		"description": "Sticky rice noodles with seasoned chicken/pork and roasted peanuts",
		"effects": {"hunger": 35.0, "energy": 10.0}
	},
	"laphet_yay": {
		"id": "laphet_yay",
		"name": "Laphet Yay",
		"category": "drink",
		"hunger_restore": 15.0,
		"stress_reduce": 10.0,
		"value": 1500,
		"description": "Rich sweet condensed milk tea brewed in local teashops",
		"effects": {"hunger": 15.0, "energy": 20.0, "stress": -10.0}
	},
	"energy_drink": {
		"id": "energy_drink",
		"name": "Sparks Energy Drink",
		"category": "drink",
		"energy_restore": 35.0,
		"value": 2000,
		"description": "Caffeinated cold energy drink to battle fatigue",
		"effects": {"energy": 35.0}
	},
	"herbal_balm": {
		"id": "herbal_balm",
		"name": "Myanmar Herbal Balm",
		"category": "health",
		"stress_reduce": 25.0,
		"value": 3500,
		"description": "Traditional soothing eucalyptus and menthol balm",
		"effects": {"stress": -25.0}
	},
	"delivery_parcel": {
		"id": "delivery_parcel",
		"name": "Downtown Express Parcel",
		"category": "quest",
		"value": 0,
		"description": "Express package for delivery client",
		"effects": {}
	},
	"transit_pass": {
		"id": "transit_pass",
		"name": "YBS Bus SmartCard",
		"category": "transit",
		"value": 10000,
		"description": "Contactless card for Yangon Bus Service",
		"effects": {}
	},
	"water_bottle": {
		"id": "water_bottle",
		"name": "Purified Water",
		"category": "drink",
		"energy_restore": 15.0,
		"value": 500,
		"description": "Cold purified bottled water",
		"effects": {"energy": 15.0, "hygiene": 10.0}
	},
	"thanaka": {
		"id": "thanaka",
		"name": "Thanaka Bark Paste",
		"category": "health",
		"stress_reduce": 15.0,
		"value": 1200,
		"description": "Cooling fragrant ground bark paste for sun protection",
		"effects": {"hygiene": 30.0, "stress": -15.0}
	},
	"kun_ya": {
		"id": "kun_ya",
		"name": "Kun-ya Betel Quid",
		"category": "snack",
		"energy_restore": 20.0,
		"value": 500,
		"description": "Betel leaf quid with areca nut and spices",
		"effects": {"energy": 20.0, "hygiene": -5.0}
	},
	"paracetamol": {
		"id": "paracetamol",
		"name": "Paracetamol Tablets",
		"category": "health",
		"stress_reduce": 30.0,
		"value": 1000,
		"description": "Headache and body ache relief tablets",
		"effects": {"stress": -30.0, "energy": 10.0}
	},
	"samosa": {
		"id": "samosa",
		"name": "Fried Samosa",
		"category": "food",
		"hunger_restore": 25.0,
		"value": 800,
		"description": "Crispy triangular potato and spice pastry",
		"effects": {"hunger": 25.0}
	}
}

var slots: Array[Dictionary] = []

func _init() -> void:
	clear_inventory()

## Clears all slots in the inventory
func clear_inventory() -> void:
	slots.clear()
	inventory_changed.emit()

## Checks if inventory has reached maximum capacity of 16 occupied slots
func is_full() -> bool:
	var occupied: int = 0
	for s: Dictionary in slots:
		if not s.is_empty() and s.get("id", "") != "":
			occupied += 1
	return occupied >= MAX_SLOTS

## Returns item definition dictionary from the catalog, or empty dictionary
func get_item_definition(item_id: String) -> Dictionary:
	if ITEM_CATALOG.has(item_id):
		return (ITEM_CATALOG[item_id] as Dictionary).duplicate(true)
	return {}

## Alias for get_item_definition
func get_catalog_entry(item_id: String) -> Dictionary:
	return get_item_definition(item_id)

## Returns item at slot index, or empty dictionary
func get_item_at(index: int) -> Dictionary:
	if index >= 0 and index < slots.size():
		return slots[index]
	return {}

## Returns list of all slots
func get_slots() -> Array[Dictionary]:
	return slots

## Adds item with specified quantity. Stacks in existing slot or allocates a new slot.
func add_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false

	var def: Dictionary = get_item_definition(item_id)

	# 1. Try stacking into existing occupied slot
	for slot: Dictionary in slots:
		if not slot.is_empty() and slot.get("id", "") == item_id:
			slot["quantity"] = int(slot.get("quantity", 0)) + quantity
			inventory_changed.emit()
			return true

	# 2. Try filling an empty slot dictionary within slots array
	for i: int in range(slots.size()):
		if slots[i].is_empty() or slots[i].get("id", "") == "":
			slots[i] = {
				"id": item_id,
				"name": def.get("name", item_id),
				"category": def.get("category", "misc"),
				"description": def.get("description", ""),
				"quantity": quantity
			}
			inventory_changed.emit()
			return true

	# 3. If slots array is under MAX_SLOTS, append a new slot
	if slots.size() < MAX_SLOTS:
		slots.append({
			"id": item_id,
			"name": def.get("name", item_id),
			"category": def.get("category", "misc"),
			"description": def.get("description", ""),
			"quantity": quantity
		})
		inventory_changed.emit()
		return true

	print_rich("[color=yellow][InventoryManager] Cannot add '%s': Inventory is full (%d/%d slots).[/color]" % [item_id, slots.size(), MAX_SLOTS])
	return false

## Removes an item quantity from the inventory.
func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0:
		return false

	if get_item_count(item_id) < quantity:
		return false

	var remaining_to_remove: int = quantity
	var indices_to_remove: Array[int] = []

	for i: int in range(slots.size()):
		var slot: Dictionary = slots[i]
		if not slot.is_empty() and slot.get("id", "") == item_id:
			var slot_qty: int = int(slot.get("quantity", 0))
			if slot_qty <= remaining_to_remove:
				remaining_to_remove -= slot_qty
				indices_to_remove.append(i)
			else:
				slot["quantity"] = slot_qty - remaining_to_remove
				remaining_to_remove = 0
				break

	indices_to_remove.reverse()
	for idx: int in indices_to_remove:
		slots.remove_at(idx)

	inventory_changed.emit()
	return true

## Removes item at specified slot index
func remove_item_at(index: int, count: int = 1) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false

	var current_qty: int = int(slots[index].get("quantity", 1))
	if current_qty > count:
		slots[index]["quantity"] = current_qty - count
	else:
		slots.remove_at(index)

	inventory_changed.emit()
	return true

## Returns the total quantity of the specified item across all slots
func get_item_count(item_id: String) -> int:
	var total: int = 0
	for slot: Dictionary in slots:
		if not slot.is_empty() and slot.get("id", "") == item_id:
			total += int(slot.get("quantity", 0))
	return total

## Returns true if inventory contains at least the specified quantity of an item
func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity

## Consumes an item, applies restorative effects to NeedsManager, and reduces quantity
func use_item(item_id: String) -> bool:
	if not has_item(item_id, 1):
		print_rich("[color=yellow][InventoryManager] Cannot use '%s': Item not in inventory.[/color]" % item_id)
		return false

	var item_def: Dictionary = get_item_definition(item_id)
	var effects: Dictionary = {}

	# Apply restorative effects to NeedsManager
	var needs_node := get_node_or_null("/root/NeedsManager")
	if needs_node and not item_def.is_empty():
		if item_def.has("hunger_restore") and needs_node.has_method("eat"):
			var amt: float = float(item_def["hunger_restore"])
			needs_node.call("eat", amt)
			effects["hunger_restore"] = amt

		if item_def.has("energy_restore") and needs_node.has_method("rest"):
			var amt: float = float(item_def["energy_restore"])
			needs_node.call("rest", amt)
			effects["energy_restore"] = amt

		if item_def.has("stress_reduce") and needs_node.has_method("relax"):
			var amt: float = float(item_def["stress_reduce"])
			needs_node.call("relax", amt)
			effects["stress_reduce"] = amt

		if item_def.has("hygiene_restore") and needs_node.has_method("bathe"):
			var amt: float = float(item_def["hygiene_restore"])
			needs_node.call("bathe", amt)
			effects["hygiene_restore"] = amt

		# Handle effects dictionary format if present
		if item_def.has("effects") and item_def["effects"] is Dictionary:
			var eff_dict: Dictionary = item_def["effects"]
			if eff_dict.has("hunger") and not effects.has("hunger_restore") and needs_node.has_method("eat"):
				needs_node.call("eat", float(eff_dict["hunger"]))
			if eff_dict.has("energy") and not effects.has("energy_restore") and needs_node.has_method("rest"):
				needs_node.call("rest", float(eff_dict["energy"]))
			if eff_dict.has("hygiene") and not effects.has("hygiene_restore") and needs_node.has_method("bathe"):
				needs_node.call("bathe", float(eff_dict["hygiene"]))
			if eff_dict.has("stress") and not effects.has("stress_reduce") and needs_node.has_method("relax"):
				var s: float = float(eff_dict["stress"])
				needs_node.call("relax", absf(s) if s < 0.0 else -s)

	remove_item(item_id, 1)
	print_rich("[color=green][InventoryManager] Used item '%s'.[/color]" % item_id)
	item_used.emit(item_id, item_def)
	return true

## Consumes item at slot index
func use_item_at(index: int) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false
	var item_id: String = str(slots[index].get("id", ""))
	return use_item(item_id)

## Serializes inventory data for persistent save files
func get_save_data() -> Dictionary:
	return {
		"slots": slots.duplicate(true)
	}

## Restores inventory data from persistent save files
func load_save_data(data: Dictionary) -> void:
	slots.clear()
	var raw_slots: Variant = data.get("slots", [])
	if raw_slots is Array:
		for s in raw_slots:
			if s is Dictionary and s.has("id") and str(s.get("id", "")) != "":
				slots.append({
					"id": str(s.get("id", "")),
					"name": str(s.get("name", s.get("id", ""))),
					"category": str(s.get("category", "misc")),
					"quantity": maxi(1, int(s.get("quantity", 1)))
				})
	inventory_changed.emit()
