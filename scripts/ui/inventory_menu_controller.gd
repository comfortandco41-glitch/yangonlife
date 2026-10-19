class_name InventoryMenuController
extends Control
## InventoryMenuController — Grid backpack inventory screen for Yangon Life.
##
## Manages a 16-slot (4x4) item grid, item selection, effect info cards,
## and item consumption triggering InventoryManager and NeedsManager.
## Toggled via 'I' key; closed via 'I' or 'Escape'.

signal inventory_opened
signal inventory_closed
signal item_selected(slot_index: int, item_data: Dictionary)

const TOTAL_SLOTS: int = 16

var is_open: bool = false
var selected_slot_index: int = -1

# UI Node References
@onready var slots_grid: GridContainer = %SlotsGrid if has_node("%SlotsGrid") else find_child("SlotsGrid", true, false)
@onready var item_title_label: Label = %ItemTitleLabel if has_node("%ItemTitleLabel") else find_child("ItemTitleLabel", true, false)
@onready var item_category_badge: Label = %ItemCategoryBadge if has_node("%ItemCategoryBadge") else find_child("ItemCategoryBadge", true, false)
@onready var item_qty_label: Label = %ItemQtyLabel if has_node("%ItemQtyLabel") else find_child("ItemQtyLabel", true, false)
@onready var item_desc_label: Label = %ItemDescLabel if has_node("%ItemDescLabel") else find_child("ItemDescLabel", true, false)
@onready var item_effects_label: Label = %ItemEffectsLabel if has_node("%ItemEffectsLabel") else find_child("ItemEffectsLabel", true, false)
@onready var use_item_button: Button = %UseItemButton if has_node("%UseItemButton") else find_child("UseItemButton", true, false)
@onready var close_button: Button = %CloseButton if has_node("%CloseButton") else find_child("CloseButton", true, false)
@onready var use_feedback_toast: Label = %UseFeedbackToast if has_node("%UseFeedbackToast") else find_child("UseFeedbackToast", true, false)
@onready var capacity_label: Label = %CapacityLabel if has_node("%CapacityLabel") else find_child("CapacityLabel", true, false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false

	if use_item_button and not use_item_button.pressed.is_connected(use_selected_item):
		use_item_button.pressed.connect(use_selected_item)

	if close_button and not close_button.pressed.is_connected(close_inventory):
		close_button.pressed.connect(close_inventory)

	var inv := get_node_or_null("/root/InventoryManager")
	if inv and inv.has_signal("inventory_changed"):
		inv.connect("inventory_changed", _on_inventory_changed)

	_clear_info_card()
	_refresh_inventory_grid()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	if is_open and event.is_action_pressed("pause"):
		close_inventory()
		get_viewport().set_input_as_handled()
		return

## Opens backpack inventory and unlocks mouse cursor
func open_inventory() -> void:
	is_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_inventory_grid()
	if selected_slot_index >= 0:
		select_slot(selected_slot_index)
	else:
		_clear_info_card()
	inventory_opened.emit()

## Closes backpack inventory and restores mouse capture if game active
func close_inventory() -> void:
	is_open = false
	visible = false
	if not get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	inventory_closed.emit()

## Toggles backpack inventory visibility
func toggle_inventory() -> void:
	if is_open:
		close_inventory()
	else:
		open_inventory()

## Re-renders all 16 slot buttons
func _refresh_inventory_grid() -> void:
	if not slots_grid:
		return

	# Clear previous slot buttons
	for child in slots_grid.get_children():
		slots_grid.remove_child(child)
		child.queue_free()

	var inv := get_node_or_null("/root/InventoryManager")
	var slots_data: Array = []
	if inv and "slots" in inv and inv.slots is Array:
		slots_data = inv.slots

	var occupied_count: int = 0

	for i: int in range(TOTAL_SLOTS):
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(84, 84)
		slot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

		var has_data: bool = i < slots_data.size() and not (slots_data[i] as Dictionary).is_empty()
		if has_data:
			occupied_count += 1
			var item: Dictionary = slots_data[i]
			var item_id: String = str(item.get("id", ""))
			var item_name: String = str(item.get("name", item_id))
			var category: String = str(item.get("category", "misc")).to_upper()
			var qty: int = int(item.get("quantity", 1))

			slot_btn.text = "%s\n[%s]\nx%d" % [item_name, category, qty]
			if i == selected_slot_index:
				slot_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3)) # Gold highlight
		else:
			slot_btn.text = "—\n[EMPTY]"
			slot_btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

		slot_btn.pressed.connect(select_slot.bind(i))
		slots_grid.add_child(slot_btn)

	if capacity_label:
		capacity_label.text = "Backpack Slots: %d / %d" % [occupied_count, TOTAL_SLOTS]

## Selects a slot index and displays its details on the info card
func select_slot(index: int) -> void:
	selected_slot_index = index

	var inv := get_node_or_null("/root/InventoryManager")
	var slot_data: Dictionary = {}
	if inv and "slots" in inv and index >= 0 and index < inv.slots.size():
		slot_data = inv.slots[index]

	if slot_data.is_empty():
		_clear_info_card()
		return

	var item_id: String = str(slot_data.get("id", ""))
	var item_name: String = str(slot_data.get("name", item_id))
	var category: String = str(slot_data.get("category", "misc")).to_upper()
	var qty: int = int(slot_data.get("quantity", 1))
	var desc: String = str(slot_data.get("description", ""))

	# Get definition effects if not on slot
	var def: Dictionary = {}
	if inv and inv.has_method("get_item_definition"):
		def = inv.call("get_item_definition", item_id)
		if desc == "":
			desc = str(def.get("description", ""))

	if item_title_label:
		item_title_label.text = item_name
	if item_category_badge:
		item_category_badge.text = "[ %s ]" % category
	if item_qty_label:
		item_qty_label.text = "Quantity in Bag: %d" % qty
	if item_desc_label:
		item_desc_label.text = desc if desc != "" else "Useful item found in Yangon."

	# Format effects
	var effects_str: String = _format_effects_string(def)
	if item_effects_label:
		item_effects_label.text = effects_str

	if use_item_button:
		use_item_button.disabled = false
		match category.to_lower():
			"food":
				use_item_button.text = "Eat Food (စားမည်)"
			"drink":
				use_item_button.text = "Drink Beverage (သောက်မည်)"
			_:
				use_item_button.text = "Use Item (အသုံးပြုမည်)"

	item_selected.emit(index, slot_data)

func _format_effects_string(def: Dictionary) -> String:
	var effects: Array[String] = []

	if def.has("hunger_restore"):
		effects.append("+%d Hunger" % int(def["hunger_restore"]))
	if def.has("energy_restore"):
		effects.append("+%d Energy" % int(def["energy_restore"]))
	if def.has("stress_reduce"):
		effects.append("-%d Stress" % int(def["stress_reduce"]))
	if def.has("hygiene_restore"):
		effects.append("+%d Hygiene" % int(def["hygiene_restore"]))
	if def.has("value") and int(def["value"]) > 0:
		effects.append("Value: %d MMK" % int(def["value"]))

	if effects.is_empty():
		return "No stat effects."
	return "Effects: " + ", ".join(effects)

func _clear_info_card() -> void:
	if item_title_label: item_title_label.text = "No Item Selected"
	if item_category_badge: item_category_badge.text = "[ EMPTY ]"
	if item_qty_label: item_qty_label.text = "Quantity: 0"
	if item_desc_label: item_desc_label.text = "Select an item slot on the left to view description and stat effects."
	if item_effects_label: item_effects_label.text = "Effects: None"
	if use_item_button:
		use_item_button.disabled = true
		use_item_button.text = "Use / Eat / Drink"

## Consumes the currently selected item
func use_selected_item() -> void:
	if selected_slot_index < 0:
		return

	var inv := get_node_or_null("/root/InventoryManager")
	if not inv:
		return

	var slots_data: Array = inv.get("slots") if "slots" in inv else []
	if selected_slot_index >= slots_data.size():
		return

	var slot: Dictionary = slots_data[selected_slot_index]
	if slot.is_empty():
		return

	var item_id: String = str(slot.get("id", ""))
	var item_name: String = str(slot.get("name", item_id))

	var success: bool = false
	if inv.has_method("use_item_at"):
		success = inv.call("use_item_at", selected_slot_index)
	elif inv.has_method("use_item"):
		success = inv.call("use_item", item_id)

	if success:
		_show_feedback_toast("Consumed '%s'!" % item_name, Color(0.2, 0.8, 0.3))
	else:
		_show_feedback_toast("Could not use item.", Color(0.9, 0.3, 0.3))

	_refresh_inventory_grid()

	# Re-check selected slot
	if selected_slot_index < slots_data.size() and not (slots_data[selected_slot_index] as Dictionary).is_empty():
		select_slot(selected_slot_index)
	else:
		_clear_info_card()
		selected_slot_index = -1

func _show_feedback_toast(msg: String, color: Color) -> void:
	if use_feedback_toast:
		use_feedback_toast.text = msg
		use_feedback_toast.add_theme_color_override("font_color", color)
		use_feedback_toast.visible = true
		get_tree().create_timer(2.5).timeout.connect(func() -> void:
			if use_feedback_toast:
				use_feedback_toast.visible = false
		)

func _on_inventory_changed() -> void:
	if is_open:
		_refresh_inventory_grid()
