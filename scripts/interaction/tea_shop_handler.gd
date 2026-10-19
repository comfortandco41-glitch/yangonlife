extends Node
## Handles tea shop purchases (Laphet-Yay sweet tea and snacks)

const COST: int = 1500
const HUNGER_RESTORE: float = 15.0
const STRESS_REDUCTION: float = 10.0

func _ready() -> void:
	var parent: Node = get_parent()
	if parent and parent.has_signal("interacted"):
		parent.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if not has_node("/root/EconomyManager") or not has_node("/root/NeedsManager"):
		print("[TeaShop] Missing EconomyManager or NeedsManager autoload.")
		return

	var em: Node = get_node("/root/EconomyManager")
	var nm: Node = get_node("/root/NeedsManager")

	if em.can_afford(COST):
		var spent: bool = em.spend_money(COST, "Tea Shop")
		if spent:
			nm.eat(HUNGER_RESTORE)
			nm.relax(STRESS_REDUCTION)
			print("[TeaShop] Enjoyed Burmese tea for %d MMK. Restored %.1f hunger, reduced %.1f stress." % [COST, HUNGER_RESTORE, STRESS_REDUCTION])
	else:
		print("[TeaShop] Not enough money (Need %d MMK, balance is %d MMK)" % [COST, em.get_balance()])
