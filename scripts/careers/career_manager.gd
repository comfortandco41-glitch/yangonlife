extends Node
## Career Manager — Job and career progression system
##
## Manages job listings, employment state, 8-hour work shifts,
## skill requirements, and shift earnings based on player needs efficiency.

signal job_started(job: Dictionary)
signal job_completed(earnings: int)
signal job_changed(job: Dictionary)

const WORK_SHIFT_MINUTES: float = 480.0 # 8 game hours

var available_jobs: Array[Dictionary] = []
var current_job: Dictionary = {}
var is_working: bool = false
var work_time_remaining: float = 0.0
var player_skills: Array[String] = []

func _ready() -> void:
	_init_jobs()
	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_signal("time_tick"):
		time_node.time_tick.connect(_on_time_tick)

func _init_jobs() -> void:
	available_jobs = [
		{
			"id": "delivery_worker",
			"title": "Delivery Worker",
			"pay": 8000,
			"min_pay": 8000,
			"max_pay": 8000,
			"skill_required": "",
			"description": "Deliver packages around downtown"
		},
		{
			"id": "street_vendor",
			"title": "Street Vendor",
			"pay": 8500,
			"min_pay": 5000,
			"max_pay": 12000,
			"skill_required": "",
			"description": "Sell street food and snacks at local stalls"
		},
		{
			"id": "tea_shop_worker",
			"title": "Tea Shop Worker",
			"pay": 6000,
			"min_pay": 6000,
			"max_pay": 6000,
			"skill_required": "",
			"description": "Serve laphet yay and snacks to neighborhood regulars"
		},
		{
			"id": "taxi_driver",
			"title": "Taxi Driver",
			"pay": 15000,
			"min_pay": 15000,
			"max_pay": 15000,
			"skill_required": "driving",
			"description": "Drive passengers through Yangon traffic"
		},
		{
			"id": "shopkeeper",
			"title": "Shopkeeper",
			"pay": 20000,
			"min_pay": 15000,
			"max_pay": 25000,
			"skill_required": "business",
			"description": "Manage inventory and serve customers in a convenience store"
		}
	]

## Returns list of all predefined jobs
func get_available_jobs() -> Array[Dictionary]:
	return available_jobs

## Returns job dictionary matching job_id, or empty dictionary
func get_job_by_id(job_id: String) -> Dictionary:
	for job: Dictionary in available_jobs:
		if job.get("id", "") == job_id:
			return job
	return {}

## Accepts a job by ID if requirements are met
func accept_job(job_id: String) -> bool:
	var job := get_job_by_id(job_id)
	if job.is_empty():
		print_rich("[color=red][CareerManager] Job '%s' not found.[/color]" % job_id)
		return false

	var req_skill: String = job.get("skill_required", "")
	if req_skill != "" and not has_skill(req_skill):
		print_rich("[color=yellow][CareerManager] Cannot accept '%s': Requires '%s' skill.[/color]" % [job.get("title", job_id), req_skill])
		return false

	if is_working:
		print_rich("[color=yellow][CareerManager] Cannot change jobs while currently working a shift.[/color]")
		return false

	current_job = job.duplicate()
	print_rich("[color=green][CareerManager] Accepted job: %s[/color]" % current_job.get("title", job_id))
	job_changed.emit(current_job)
	return true

## Quits the current job, returning to unemployed status
func quit_job() -> void:
	if current_job.is_empty():
		return
	var old_title: String = current_job.get("title", "Job")
	current_job = {}
	is_working = false
	work_time_remaining = 0.0
	print_rich("[color=cyan][CareerManager] Resigned from job: %s[/color]" % old_title)
	job_changed.emit(current_job)

## Starts an 8-hour (480 game minutes) work shift if employed and daytime
func start_work() -> bool:
	if current_job.is_empty():
		print_rich("[color=yellow][CareerManager] Cannot start work: You are unemployed.[/color]")
		return false
	if is_working:
		print_rich("[color=yellow][CareerManager] Already working a shift.[/color]")
		return false

	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_method("is_daytime"):
		if not time_node.is_daytime():
			print_rich("[color=yellow][CareerManager] Cannot start work: Shifts must start during daytime (06:00 - 18:00).[/color]")
			return false

	is_working = true
	work_time_remaining = WORK_SHIFT_MINUTES
	print_rich("[color=green][CareerManager] Started work shift: %s (Duration: %d game minutes)[/color]" % [current_job.get("title", "Work"), int(WORK_SHIFT_MINUTES)])
	job_started.emit(current_job)
	return true

## Checks if player possesses a skill
func has_skill(skill_name: String) -> bool:
	if skill_name == "":
		return true
	if skill_name in player_skills:
		return true
	var sm := get_node_or_null("/root/SkillManager")
	if sm and sm.has_method("has_skill_level"):
		return sm.has_skill_level(skill_name, 1)
	return false

## Grants a new skill to the player
func add_skill(skill_name: String) -> void:
	if not skill_name in player_skills:
		player_skills.append(skill_name)
		print_rich("[color=green][CareerManager] Acquired skill: %s[/color]" % skill_name)

## Manually advances work shift timer (e.g., skip shift or fast time passage)
func advance_work(minutes: float) -> void:
	if not is_working or minutes <= 0.0:
		return
	work_time_remaining = maxf(0.0, work_time_remaining - minutes)
	if work_time_remaining <= 0.0:
		_complete_work_session()

func _on_time_tick(_hour: int, _minute: int) -> void:
	if not is_working:
		return
	work_time_remaining = maxf(0.0, work_time_remaining - 1.0)
	if work_time_remaining <= 0.0:
		_complete_work_session()

func _complete_work_session() -> void:
	is_working = false
	work_time_remaining = 0.0

	var min_pay: int = int(current_job.get("min_pay", current_job.get("pay", 5000)))
	var max_pay: int = int(current_job.get("max_pay", current_job.get("pay", 5000)))
	var base_pay: int = min_pay
	if max_pay > min_pay:
		base_pay = randi_range(min_pay, max_pay)

	# Modify earnings by player needs efficiency
	var efficiency: float = 1.0
	var needs_node := get_node_or_null("/root/NeedsManager")
	if needs_node and needs_node.has_method("get_work_efficiency"):
		efficiency = needs_node.get_work_efficiency()

	var earnings: int = int(round(float(base_pay) * efficiency))
	earnings = maxi(0, earnings)

	var job_title: String = current_job.get("title", "Work")
	var economy_node := get_node_or_null("/root/EconomyManager")
	if economy_node and economy_node.has_method("add_money"):
		economy_node.add_money(earnings, "Salary: %s" % job_title)

	print_rich("[color=green][CareerManager] Completed shift for %s! Earned: %d MMK (Efficiency: %.1f%%)[/color]" % [job_title, earnings, efficiency * 100.0])
	job_completed.emit(earnings)

## Serializes state for save game
func get_save_data() -> Dictionary:
	return {
		"current_job_id": current_job.get("id", ""),
		"current_job": current_job,
		"is_working": is_working,
		"work_time_remaining": work_time_remaining,
		"player_skills": player_skills
	}

## Restores state from save game
func load_save_data(data: Dictionary) -> void:
	var job_id: String = str(data.get("current_job_id", ""))
	if job_id != "":
		current_job = get_job_by_id(job_id)
		if current_job.is_empty() and data.has("current_job") and data["current_job"] is Dictionary:
			current_job = data["current_job"]
	else:
		current_job = {}

	is_working = bool(data.get("is_working", false))
	work_time_remaining = float(data.get("work_time_remaining", 0.0))

	player_skills.clear()
	var skills_val: Variant = data.get("player_skills", [])
	if skills_val is Array:
		for s in skills_val:
			player_skills.append(str(s))

	job_changed.emit(current_job)
