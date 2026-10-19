extends Node
## Skill Manager — Player skills progression system for Yangon Life
##
## Tracks skills, experience points (XP), and certifications.
## Supported skills: driving, cooking, customer_service, business, mechanic.
## Progression: 1-5 levels with level up thresholds at (100.0 * level) XP.

signal skill_xp_gained(skill_name: String, amount: float, current_xp: float)
signal skill_leveled_up(skill_name: String, new_level: int)

const MAX_LEVEL: int = 5
const BASE_XP_PER_LEVEL: float = 100.0

const DEFAULT_SKILLS: Dictionary = {
	"driving": {"xp": 0.0, "level": 1},
	"cooking": {"xp": 0.0, "level": 1},
	"customer_service": {"xp": 0.0, "level": 1},
	"business": {"xp": 0.0, "level": 1},
	"mechanic": {"xp": 0.0, "level": 1}
}

var skills: Dictionary = {
	"driving": {"xp": 0.0, "level": 1},
	"cooking": {"xp": 0.0, "level": 1},
	"customer_service": {"xp": 0.0, "level": 1},
	"business": {"xp": 0.0, "level": 1},
	"mechanic": {"xp": 0.0, "level": 1}
}

func _init() -> void:
	reset_skills()

## Resets all skills to default base level (1) and 0 XP
func reset_skills() -> void:
	skills = {
		"driving": {"xp": 0.0, "level": 1},
		"cooking": {"xp": 0.0, "level": 1},
		"customer_service": {"xp": 0.0, "level": 1},
		"business": {"xp": 0.0, "level": 1},
		"mechanic": {"xp": 0.0, "level": 1}
	}

## Adds XP to a skill and computes potential level ups
func add_xp(skill_name: String, amount: float) -> void:
	if amount <= 0.0:
		return

	if not skills.has(skill_name):
		skills[skill_name] = {"xp": 0.0, "level": 1}

	var data: Dictionary = skills[skill_name]
	var current_level: int = int(data.get("level", 1))
	var current_xp: float = float(data.get("xp", 0.0)) + amount

	data["xp"] = current_xp
	skill_xp_gained.emit(skill_name, amount, current_xp)

	# Level-up loop: threshold is 100.0 * current_level
	while current_level < MAX_LEVEL:
		var xp_needed: float = float(current_level) * BASE_XP_PER_LEVEL
		if current_xp >= xp_needed:
			current_xp -= xp_needed
			current_level += 1
			data["level"] = current_level
			data["xp"] = current_xp
			print_rich("[color=green][SkillManager] %s leveled up to Level %d![/color]" % [skill_name.capitalize(), current_level])
			skill_leveled_up.emit(skill_name, current_level)
		else:
			break

	skills[skill_name] = data

## Returns the current level (1 to 5) of the given skill
func get_level(skill_name: String) -> int:
	if skills.has(skill_name):
		return int(skills[skill_name].get("level", 1))
	return 1

## Returns the current XP accumulated toward the next level for the given skill
func get_xp(skill_name: String) -> float:
	if skills.has(skill_name):
		return float(skills[skill_name].get("xp", 0.0))
	return 0.0

## Returns the XP needed for next level up from current level (0.0 if at MAX_LEVEL)
func get_xp_for_next_level(skill_name: String) -> float:
	var lvl: int = get_level(skill_name)
	if lvl >= MAX_LEVEL:
		return 0.0
	return float(lvl) * BASE_XP_PER_LEVEL

## Checks if player has attained at least the specified minimum level in a skill
func has_skill_level(skill_name: String, min_level: int) -> bool:
	return get_level(skill_name) >= min_level

## Returns fuel consumption multiplier (driving skill reduces fuel burn by 8% per level above 1)
func get_driving_fuel_multiplier() -> float:
	var lvl: int = get_level("driving")
	return maxf(0.68, 1.0 - float(lvl - 1) * 0.08)

## Returns vendor price margin bonus (cooking skill grants +10% profit margin per level above 1)
func get_cooking_margin_bonus() -> float:
	var lvl: int = get_level("cooking")
	return float(lvl - 1) * 0.10

## Returns tip multiplier bonus (customer_service grants +10% tip bonus per level above 1)
func get_customer_service_tip_bonus() -> float:
	var lvl: int = get_level("customer_service")
	return float(lvl - 1) * 0.10

## Returns lease & wholesale discount multiplier (business skill saves 5% per level above 1)
func get_business_discount_multiplier() -> float:
	var lvl: int = get_level("business")
	return maxf(0.80, 1.0 - float(lvl - 1) * 0.05)

## Returns vehicle maintenance discount multiplier (mechanic saves 8% per level above 1)
func get_mechanic_discount_multiplier() -> float:
	var lvl: int = get_level("mechanic")
	return maxf(0.68, 1.0 - float(lvl - 1) * 0.08)

## Serializes skill data for persistent save files
func get_save_data() -> Dictionary:
	return {
		"skills": skills.duplicate(true)
	}

## Restores skill data from persistent save files
func load_save_data(data: Dictionary) -> void:
	var source: Dictionary = {}
	if data.has("skills") and data["skills"] is Dictionary:
		source = data["skills"]
	else:
		source = data

	for skill_name: String in DEFAULT_SKILLS.keys():
		if source.has(skill_name) and source[skill_name] is Dictionary:
			var s_dict: Dictionary = source[skill_name]
			skills[skill_name] = {
				"level": clampi(int(s_dict.get("level", 1)), 1, MAX_LEVEL),
				"xp": maxf(0.0, float(s_dict.get("xp", 0.0)))
			}
		else:
			skills[skill_name] = {"xp": 0.0, "level": 1}
