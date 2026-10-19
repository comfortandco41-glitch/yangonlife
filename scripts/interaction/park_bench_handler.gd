extends Node
## Handles park bench relaxation (Maha Bandula Park, Sule Pagoda Gardens)

const STRESS_REDUCTION: float = 25.0

func _ready() -> void:
	var parent: Node = get_parent()
	if parent and parent.has_signal("interacted"):
		parent.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if not has_node("/root/NeedsManager"):
		print("[ParkBench] NeedsManager autoload not found.")
		return

	var nm: Node = get_node("/root/NeedsManager")
	nm.relax(STRESS_REDUCTION)
	print("[ParkBench] Relaxing in the park... Stress reduced by %.1f (Current stress: %.1f)" % [
		STRESS_REDUCTION,
		nm.stress
	])
