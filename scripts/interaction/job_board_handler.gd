extends Node
## Job board handler — placeholder for career listing and employment signup

func _ready() -> void:
	var parent: Node = get_parent()
	if parent and parent.has_signal("interacted"):
		parent.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	if not has_node("/root/CareerManager"):
		print("[JobBoard] CareerManager autoload not found.")
		return

	var cm: Node = get_node("/root/CareerManager")
	var jobs: Array = []
	if cm.has_method("get_available_jobs"):
		jobs = cm.get_available_jobs()
	elif "available_jobs" in cm:
		jobs = cm.available_jobs

	print("[JobBoard] --- Available Jobs in Downtown Yangon ---")
	for job in jobs:
		if job is Dictionary:
			print(" - %s (%s): %d MMK/shift — %s" % [
				job.get("title", "Job"),
				job.get("id", ""),
				job.get("pay", 0),
				job.get("description", "")
			])
		else:
			print(" - %s" % str(job))

	var is_employed: bool = false
	if cm.has_method("is_employed"):
		is_employed = cm.is_employed()
	elif "current_job" in cm:
		if cm.current_job is Dictionary:
			is_employed = not cm.current_job.is_empty()
		elif cm.current_job is String:
			is_employed = cm.current_job != ""

	if not is_employed:
		if jobs.size() > 0:
			var first_job: Variant = jobs[0]
			var job_id: String = ""
			if first_job is Dictionary:
				job_id = str(first_job.get("id", ""))
			elif first_job is String:
				job_id = first_job

			if job_id != "":
				var accepted: bool = false
				if cm.has_method("accept_job"):
					accepted = cm.accept_job(job_id)
				if accepted:
					print("[JobBoard] Accepted first available job: '%s'" % job_id)
				else:
					print("[JobBoard] Could not accept job '%s'." % job_id)
		else:
			print("[JobBoard] No available jobs to accept.")
	else:
		var current_title: String = ""
		if "current_job" in cm and cm.current_job is Dictionary:
			current_title = cm.current_job.get("title", cm.current_job.get("id", "Employed"))
		print("[JobBoard] Player is already employed as '%s'." % current_title)
