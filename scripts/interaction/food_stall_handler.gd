extends Node
## Handles food stall purchases (Mohinga, Shan noodles, fried snacks)

const COST: int = 3000
const HUNGER_RESTORE: float = 40.0

func _ready() -> void:
	var parent: Node = get_parent()
	if parent and parent.has_signal("interacted"):
		parent.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if not has_node("/root/EconomyManager") or not has_node("/root/NeedsManager"):
		print("[FoodStall] Missing EconomyManager or NeedsManager autoload.")
		return

	var em: Node = get_node("/root/EconomyManager")
	var nm: Node = get_node("/root/NeedsManager")

	if em.can_afford(COST):
		var spent: bool = em.spend_money(COST, "Food Stall")
		if spent:
			nm.eat(HUNGER_RESTORE)
			print("[FoodStall] Purchased meal for %d MMK. Restored %.1f hunger." % [COST, HUNGER_RESTORE])
	else:
		print("[FoodStall] Not enough money (Need %d MMK, balance is %d MMK)" % [COST, em.get_balance()])
