class_name PhoneController
extends Control

const CharacterData = preload("res://scripts/systems/character_data.gd")

## PhoneController — Smartphone personal organizer for Yangon Life.
##
## Simulates a Burmese Android smartphone interface (KBZPay/WavePay, Jobs, GPS Map, Status).
## Toggled via the 'P' key or closed via 'Escape'. Manages responsive layouts and pointer locking.

signal phone_opened
signal phone_closed
signal app_switched(app_name: String)

## Points of interest across Downtown Yangon for GPS navigation
const POI_LOCATIONS: Array[Dictionary] = [
	{
		"id": "sule_pagoda",
		"name": "Sule Pagoda (ဆူးလေဘုရား)",
		"category": "Heritage / Landmark",
		"position": Vector3(0.0, 0.0, 0.0)
	},
	{
		"id": "maha_bandula_park",
		"name": "Maha Bandula Park (မဟာဗန္ဓုလပန်းခြံ)",
		"category": "Public Park",
		"position": Vector3(-30.0, 0.0, 30.0)
	},
	{
		"id": "chinatown",
		"name": "Chinatown 19th St (တရုတ်တန်း)",
		"category": "Night Market / Food",
		"position": Vector3(10.0, 0.0, 50.0)
	},
	{
		"id": "city_hall",
		"name": "Yangon City Hall (မြို့တော်ခန်းမ)",
		"category": "Colonial Landmark",
		"position": Vector3(20.0, 0.0, -30.0)
	},
	{
		"id": "botahtaung",
		"name": "Botahtaung Pagoda (ဗိုလ်တထောင်ဘုရား)",
		"category": "Religious / Riverfront",
		"position": Vector3(-40.0, 0.0, -35.0)
	}
]

var is_open: bool = false
var current_app: String = "home"

# UI Node References
@onready var phone_frame: Control = %PhoneFrame if has_node("%PhoneFrame") else find_child("PhoneFrame", true, false)
@onready var status_bar_time: Label = %StatusBarTime if has_node("%StatusBarTime") else find_child("StatusBarTime", true, false)
@onready var home_clock: Label = %HomeClock if has_node("%HomeClock") else find_child("HomeClock", true, false)
@onready var home_date: Label = %HomeDate if has_node("%HomeDate") else find_child("HomeDate", true, false)

# Screen containers
@onready var home_screen: Control = %HomeScreen if has_node("%HomeScreen") else find_child("HomeScreen", true, false)
@onready var bank_app: Control = %BankApp if has_node("%BankApp") else find_child("BankApp", true, false)
@onready var jobs_app: Control = %JobsApp if has_node("%JobsApp") else find_child("JobsApp", true, false)
@onready var map_app: Control = %MapApp if has_node("%MapApp") else find_child("MapApp", true, false)
@onready var status_app: Control = %StatusApp if has_node("%StatusApp") else find_child("StatusApp", true, false)

# Banking app nodes
@onready var bank_balance_label: Label = %BankBalanceLabel if has_node("%BankBalanceLabel") else find_child("BankBalanceLabel", true, false)
@onready var bank_ledger_container: VBoxContainer = %BankLedgerContainer if has_node("%BankLedgerContainer") else find_child("BankLedgerContainer", true, false)
@onready var bank_status_toast: Label = %BankStatusToast if has_node("%BankStatusToast") else find_child("BankStatusToast", true, false)

# Jobs app nodes
@onready var job_status_label: Label = %JobStatusLabel if has_node("%JobStatusLabel") else find_child("JobStatusLabel", true, false)
@onready var shift_info_label: Label = %ShiftInfoLabel if has_node("%ShiftInfoLabel") else find_child("ShiftInfoLabel", true, false)
@onready var start_shift_button: Button = %StartShiftButton if has_node("%StartShiftButton") else find_child("StartShiftButton", true, false)
@onready var resign_job_button: Button = %ResignJobButton if has_node("%ResignJobButton") else find_child("ResignJobButton", true, false)
@onready var jobs_list_container: VBoxContainer = %JobsListContainer if has_node("%JobsListContainer") else find_child("JobsListContainer", true, false)
@onready var job_toast_label: Label = %JobToastLabel if has_node("%JobToastLabel") else find_child("JobToastLabel", true, false)

# Map app nodes
@onready var poi_list_container: VBoxContainer = %PoiListContainer if has_node("%PoiListContainer") else find_child("PoiListContainer", true, false)

# Status app nodes
@onready var hunger_meter: ProgressBar = %HungerMeter if has_node("%HungerMeter") else find_child("HungerMeter", true, false)
@onready var energy_meter: ProgressBar = %EnergyMeter if has_node("%EnergyMeter") else find_child("EnergyMeter", true, false)
@onready var hygiene_meter: ProgressBar = %HygieneMeter if has_node("%HygieneMeter") else find_child("HygieneMeter", true, false)
@onready var stress_meter: ProgressBar = %StressMeter if has_node("%StressMeter") else find_child("StressMeter", true, false)
@onready var hunger_val_label: Label = %HungerValLabel if has_node("%HungerValLabel") else find_child("HungerValLabel", true, false)
@onready var energy_val_label: Label = %EnergyValLabel if has_node("%EnergyValLabel") else find_child("EnergyValLabel", true, false)
@onready var hygiene_val_label: Label = %HygieneValLabel if has_node("%HygieneValLabel") else find_child("HygieneValLabel", true, false)
@onready var stress_val_label: Label = %StressValLabel if has_node("%StressValLabel") else find_child("StressValLabel", true, false)
@onready var efficiency_label: Label = %EfficiencyLabel if has_node("%EfficiencyLabel") else find_child("EfficiencyLabel", true, false)
@onready var skills_list_container: VBoxContainer = %SkillsListContainer if has_node("%SkillsListContainer") else find_child("SkillsListContainer", true, false)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false

	# Connect simulation manager signals
	_connect_manager_signals()
	_setup_app_buttons()

	# Setup initial citizen portraits using cropped 32x32 atlas
	var portrait: AtlasTexture = CharacterData.get_character_portrait(1)
	if portrait:
		var home_av := find_child("AvatarIcon", true, false) as TextureRect
		if home_av:
			home_av.texture = portrait
		var status_av := get_node_or_null("%StatusProfile/HBox/AvatarIcon") as TextureRect
		if status_av:
			status_av.texture = portrait

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("phone"):
		toggle_phone()
		get_viewport().set_input_as_handled()
		return

	if is_open and event.is_action_pressed("pause"):
		close_phone()
		get_viewport().set_input_as_handled()
		return

func _connect_manager_signals() -> void:
	var econ_node := get_node_or_null("/root/EconomyManager")
	if econ_node and econ_node.has_signal("money_changed"):
		econ_node.connect("money_changed", _on_money_changed)
	if econ_node and econ_node.has_signal("transaction_completed"):
		econ_node.connect("transaction_completed", _on_transaction_completed)

	var time_node := get_node_or_null("/root/TimeManager")
	if time_node and time_node.has_signal("time_tick"):
		time_node.connect("time_tick", _on_time_tick)

	var career_node := get_node_or_null("/root/CareerManager")
	if career_node and career_node.has_signal("job_changed"):
		career_node.connect("job_changed", _on_job_changed)
	if career_node and career_node.has_signal("job_started"):
		career_node.connect("job_started", _on_job_started)
	if career_node and career_node.has_signal("job_completed"):
		career_node.connect("job_completed", _on_job_completed)

func _setup_app_buttons() -> void:
	# App launcher buttons on Home Screen
	var btn_bank: Button = %BtnLaunchBank if has_node("%BtnLaunchBank") else find_child("BtnLaunchBank", true, false)
	if btn_bank and not btn_bank.pressed.is_connected(show_app.bind("bank")):
		btn_bank.pressed.connect(show_app.bind("bank"))

	var btn_jobs: Button = %BtnLaunchJobs if has_node("%BtnLaunchJobs") else find_child("BtnLaunchJobs", true, false)
	if btn_jobs and not btn_jobs.pressed.is_connected(show_app.bind("jobs")):
		btn_jobs.pressed.connect(show_app.bind("jobs"))

	var btn_map: Button = %BtnLaunchMap if has_node("%BtnLaunchMap") else find_child("BtnLaunchMap", true, false)
	if btn_map and not btn_map.pressed.is_connected(show_app.bind("map")):
		btn_map.pressed.connect(show_app.bind("map"))

	var btn_status: Button = %BtnLaunchStatus if has_node("%BtnLaunchStatus") else find_child("BtnLaunchStatus", true, false)
	if btn_status and not btn_status.pressed.is_connected(show_app.bind("status")):
		btn_status.pressed.connect(show_app.bind("status"))

	# Phone dock buttons
	var dock_bank: Button = %DockBank if has_node("%DockBank") else find_child("DockBank", true, false)
	if dock_bank and not dock_bank.pressed.is_connected(show_app.bind("bank")):
		dock_bank.pressed.connect(show_app.bind("bank"))

	var dock_jobs: Button = %DockJobs if has_node("%DockJobs") else find_child("DockJobs", true, false)
	if dock_jobs and not dock_jobs.pressed.is_connected(show_app.bind("jobs")):
		dock_jobs.pressed.connect(show_app.bind("jobs"))

	var dock_map: Button = %DockMap if has_node("%DockMap") else find_child("DockMap", true, false)
	if dock_map and not dock_map.pressed.is_connected(show_app.bind("map")):
		dock_map.pressed.connect(show_app.bind("map"))

	var dock_status: Button = %DockStatus if has_node("%DockStatus") else find_child("DockStatus", true, false)
	if dock_status and not dock_status.pressed.is_connected(show_app.bind("status")):
		dock_status.pressed.connect(show_app.bind("status"))

	# Navigation bar buttons
	var nav_back: Button = %NavBack if has_node("%NavBack") else find_child("NavBack", true, false)
	if nav_back and not nav_back.pressed.is_connected(_on_nav_back_pressed):
		nav_back.pressed.connect(_on_nav_back_pressed)

	var nav_home: Button = %NavHome if has_node("%NavHome") else find_child("NavHome", true, false)
	if nav_home and not nav_home.pressed.is_connected(return_to_home):
		nav_home.pressed.connect(return_to_home)

	var nav_close: Button = %NavClose if has_node("%NavClose") else find_child("NavClose", true, false)
	if nav_close and not nav_close.pressed.is_connected(close_phone):
		nav_close.pressed.connect(close_phone)

	# App internal action buttons
	var btn_pay_rent: Button = %BtnPayRent if has_node("%BtnPayRent") else find_child("BtnPayRent", true, false)
	if btn_pay_rent and not btn_pay_rent.pressed.is_connected(pay_rent_action):
		btn_pay_rent.pressed.connect(pay_rent_action)

	if start_shift_button and not start_shift_button.pressed.is_connected(start_work_action):
		start_shift_button.pressed.connect(start_work_action)

	if resign_job_button and not resign_job_button.pressed.is_connected(resign_job_action):
		resign_job_button.pressed.connect(resign_job_action)

## Opens the smartphone interface and unlocks mouse cursor
func open_phone() -> void:
	is_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_all_views()
	phone_opened.emit()

## Closes the smartphone interface and restores mouse capture if game active
func close_phone() -> void:
	is_open = false
	visible = false
	if not get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	phone_closed.emit()

## Toggles smartphone visibility
func toggle_phone() -> void:
	if is_open:
		close_phone()
	else:
		open_phone()

## Switches to a specific smartphone app screen
func show_app(app_name: String) -> void:
	current_app = app_name

	if home_screen: home_screen.visible = (app_name == "home")
	if bank_app: bank_app.visible = (app_name == "bank")
	if jobs_app: jobs_app.visible = (app_name == "jobs")
	if map_app: map_app.visible = (app_name == "map")
	if status_app: status_app.visible = (app_name == "status")

	match app_name:
		"bank":
			update_bank_view()
		"jobs":
			update_jobs_view()
		"map":
			update_map_view()
		"status":
			update_status_view()
		"home":
			_update_time_and_date()

	app_switched.emit(app_name)

## Returns to home launcher screen
func return_to_home() -> void:
	show_app("home")

func _on_nav_back_pressed() -> void:
	if current_app == "home":
		close_phone()
	else:
		return_to_home()

func _refresh_all_views() -> void:
	_update_time_and_date()
	update_bank_view()
	update_jobs_view()
	update_map_view()
	update_status_view()

func _update_time_and_date() -> void:
	var time_str: String = "08:00"
	var day_num: int = 1

	var tm := get_node_or_null("/root/TimeManager")
	if tm:
		if tm.has_method("get_time_string"):
			time_str = str(tm.call("get_time_string"))
		elif "game_hour" in tm and "game_minute" in tm:
			time_str = "%02d:%02d" % [tm.game_hour, tm.game_minute]

		if "game_day" in tm:
			day_num = int(tm.game_day)

	if status_bar_time:
		status_bar_time.text = time_str
	if home_clock:
		home_clock.text = time_str
	if home_date:
		home_date.text = "Day %d (ရန်ကုန်)" % day_num

# ------------------------------------------------------------------------------
# 1. KBZPay / WavePay Banking App
# ------------------------------------------------------------------------------

func update_bank_view() -> void:
	var balance: int = 50000
	var em := get_node_or_null("/root/EconomyManager")
	if em:
		if em.has_method("get_balance"):
			balance = em.call("get_balance")
		elif "balance" in em:
			balance = int(em.balance)

	if bank_balance_label:
		bank_balance_label.text = "K " + _format_number(balance) + " MMK"

	_populate_bank_ledger()

func _populate_bank_ledger() -> void:
	if not bank_ledger_container:
		return

	# Clear existing children
	for child in bank_ledger_container.get_children():
		bank_ledger_container.remove_child(child)
		child.queue_free()

	var transactions: Array[Dictionary] = []
	var em := get_node_or_null("/root/EconomyManager")
	if em and em.has_method("get_transactions"):
		var tx_variant: Variant = em.call("get_transactions")
		if tx_variant is Array:
			for item in tx_variant:
				if item is Dictionary:
					transactions.append(item)

	if transactions.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No recent transactions."
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		bank_ledger_container.add_child(empty_lbl)
		return

	# Show recent transactions up to 10
	var count: int = 0
	for tx: Dictionary in transactions:
		if count >= 10:
			break
		count += 1

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var reason_lbl := Label.new()
		reason_lbl.text = str(tx.get("reason", "Transaction"))
		reason_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		reason_lbl.add_theme_font_size_override("font_size", 13)

		var amount_val: int = int(tx.get("amount", 0))
		var amount_lbl := Label.new()
		if amount_val >= 0:
			amount_lbl.text = "+K " + _format_number(amount_val)
			amount_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3)) # Green
		else:
			amount_lbl.text = "-K " + _format_number(abs(amount_val))
			amount_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3)) # Red
		amount_lbl.add_theme_font_size_override("font_size", 13)

		row.add_child(reason_lbl)
		row.add_child(amount_lbl)
		bank_ledger_container.add_child(row)

func pay_rent_action() -> void:
	var hm := get_node_or_null("/root/HousingManager")
	var rent_amount: int = 15000
	var success: bool = false

	if hm and hm.has_method("pay_rent"):
		success = hm.call("pay_rent")
	else:
		var em := get_node_or_null("/root/EconomyManager")
		if em and em.has_method("spend_money"):
			success = em.call("spend_money", rent_amount, "Apartment Rent (အိမ်လခ)")

	if success:
		_show_bank_toast("Rent paid successfully! (အိမ်လခပေးပြီးပါပြီ)", Color(0.2, 0.8, 0.3))
	else:
		_show_bank_toast("Insufficient funds for rent! (ငွေမလုံလောက်ပါ)", Color(0.9, 0.3, 0.3))

	update_bank_view()

func _show_bank_toast(msg: String, color: Color) -> void:
	if bank_status_toast:
		bank_status_toast.text = msg
		bank_status_toast.add_theme_color_override("font_color", color)
		bank_status_toast.visible = true
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if bank_status_toast:
				bank_status_toast.visible = false
		)

# ------------------------------------------------------------------------------
# 2. Jobs & Career App
# ------------------------------------------------------------------------------

func update_jobs_view() -> void:
	var cm := get_node_or_null("/root/CareerManager")
	var current_job: Dictionary = {}
	var is_working: bool = false
	var work_remaining: float = 0.0

	if cm:
		if "current_job" in cm and cm.current_job is Dictionary:
			current_job = cm.current_job
		if "is_working" in cm:
			is_working = bool(cm.is_working)
		if "work_time_remaining" in cm:
			work_remaining = float(cm.work_time_remaining)

	# Status display
	if job_status_label:
		if current_job.is_empty():
			job_status_label.text = "Status: Unemployed (အလုပ်ရှာဖွေနေဆဲ)"
		else:
			var title: String = str(current_job.get("title", "Employed"))
			job_status_label.text = "Role: %s" % title

	# Shift info & button states
	if shift_info_label:
		if current_job.is_empty():
			shift_info_label.text = "Select a vacant downtown job below."
		elif is_working:
			shift_info_label.text = "Shift in Progress: %d mins left" % int(work_remaining)
		else:
			shift_info_label.text = "Shift: 8 Hours (480 mins) | Standard Wage: %s MMK" % _format_number(int(current_job.get("pay", 8000)))

	if start_shift_button:
		start_shift_button.disabled = current_job.is_empty() or is_working
		start_shift_button.text = "Shift in Progress" if is_working else "Start Work Shift (အလုပ်ဆင်းမည်)"

	if resign_job_button:
		resign_job_button.visible = not current_job.is_empty()

	_populate_jobs_list(current_job)

func _populate_jobs_list(current_job: Dictionary) -> void:
	if not jobs_list_container:
		return

	for child in jobs_list_container.get_children():
		jobs_list_container.remove_child(child)
		child.queue_free()

	var cm := get_node_or_null("/root/CareerManager")
	var jobs: Array[Dictionary] = []
	if cm and cm.has_method("get_available_jobs"):
		var j_var: Variant = cm.call("get_available_jobs")
		if j_var is Array:
			for j in j_var:
				if j is Dictionary:
					jobs.append(j)

	for job: Dictionary in jobs:
		var job_id: String = str(job.get("id", ""))
		var job_title: String = str(job.get("title", job_id))
		var min_pay: int = int(job.get("min_pay", job.get("pay", 0)))
		var max_pay: int = int(job.get("max_pay", job.get("pay", 0)))
		var skill_req: String = str(job.get("skill_required", ""))

		var job_card := PanelContainer.new()
		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 4)

		var header_row := HBoxContainer.new()
		var title_lbl := Label.new()
		title_lbl.text = job_title
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 14)

		var pay_lbl := Label.new()
		if min_pay == max_pay:
			pay_lbl.text = "K %s" % _format_number(min_pay)
		else:
			pay_lbl.text = "K %s - %s" % [_format_number(min_pay), _format_number(max_pay)]
		pay_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		pay_lbl.add_theme_font_size_override("font_size", 13)

		header_row.add_child(title_lbl)
		header_row.add_child(pay_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(job.get("description", ""))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

		var footer_row := HBoxContainer.new()
		var req_lbl := Label.new()
		req_lbl.text = ("Req: %s" % skill_req.capitalize()) if skill_req != "" else "Req: None"
		req_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		req_lbl.add_theme_font_size_override("font_size", 12)
		req_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))

		var apply_btn := Button.new()
		var is_this_job: bool = not current_job.is_empty() and current_job.get("id", "") == job_id
		apply_btn.text = "Current" if is_this_job else "Apply"
		apply_btn.disabled = is_this_job
		apply_btn.pressed.connect(apply_job_action.bind(job_id))

		footer_row.add_child(req_lbl)
		footer_row.add_child(apply_btn)

		card_box.add_child(header_row)
		card_box.add_child(desc_lbl)
		card_box.add_child(footer_row)
		job_card.add_child(card_box)
		jobs_list_container.add_child(job_card)

func start_work_action() -> void:
	var cm := get_node_or_null("/root/CareerManager")
	if not cm or not cm.has_method("start_work"):
		return

	var success: bool = cm.call("start_work")
	if success:
		_show_job_toast("Shift started! Work diligently.", Color(0.2, 0.8, 0.3))
	else:
		_show_job_toast("Cannot start shift (Daytime 06:00-18:00 only).", Color(0.9, 0.3, 0.3))

	update_jobs_view()

func resign_job_action() -> void:
	var cm := get_node_or_null("/root/CareerManager")
	if cm and cm.has_method("quit_job"):
		cm.call("quit_job")
		_show_job_toast("Resigned from current role.", Color(0.9, 0.8, 0.2))
		update_jobs_view()

func apply_job_action(job_id: String) -> void:
	var cm := get_node_or_null("/root/CareerManager")
	if not cm or not cm.has_method("accept_job"):
		return

	var success: bool = cm.call("accept_job", job_id)
	if success:
		_show_job_toast("Accepted job: %s" % job_id.capitalize(), Color(0.2, 0.8, 0.3))
	else:
		_show_job_toast("Application rejected (Skill requirement unmet).", Color(0.9, 0.3, 0.3))

	update_jobs_view()

func _show_job_toast(msg: String, color: Color) -> void:
	if job_toast_label:
		job_toast_label.text = msg
		job_toast_label.add_theme_color_override("font_color", color)
		job_toast_label.visible = true
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if job_toast_label:
				job_toast_label.visible = false
		)

# ------------------------------------------------------------------------------
# 3. GPS Map Navigation App
# ------------------------------------------------------------------------------

func update_map_view() -> void:
	if not poi_list_container:
		return

	for child in poi_list_container.get_children():
		poi_list_container.remove_child(child)
		child.queue_free()

	var player_pos: Vector3 = Vector3.ZERO
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Node3D:
		player_pos = (players[0] as Node3D).global_position

	for poi: Dictionary in POI_LOCATIONS:
		var target_pos: Vector3 = poi.get("position", Vector3.ZERO)
		var distance_m: float = player_pos.distance_to(target_pos)

		var card := PanelContainer.new()
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)

		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = "📍 " + str(poi.get("name", "POI"))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 14)

		var dist_lbl := Label.new()
		dist_lbl.text = "%d m" % int(round(distance_m))
		dist_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
		dist_lbl.add_theme_font_size_override("font_size", 14)

		row.add_child(name_lbl)
		row.add_child(dist_lbl)

		var cat_lbl := Label.new()
		cat_lbl.text = str(poi.get("category", ""))
		cat_lbl.add_theme_font_size_override("font_size", 11)
		cat_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

		vbox.add_child(row)
		vbox.add_child(cat_lbl)
		card.add_child(vbox)
		poi_list_container.add_child(card)

# ------------------------------------------------------------------------------
# 4. Status & Skills App
# ------------------------------------------------------------------------------

func update_status_view() -> void:
	var nm := get_node_or_null("/root/NeedsManager")
	var hunger: float = 80.0
	var energy: float = 100.0
	var hygiene: float = 90.0
	var stress: float = 10.0
	var eff: float = 1.0

	if nm:
		if "hunger" in nm: hunger = float(nm.hunger)
		if "energy" in nm: energy = float(nm.energy)
		if "hygiene" in nm: hygiene = float(nm.hygiene)
		if "stress" in nm: stress = float(nm.stress)
		if nm.has_method("get_work_efficiency"):
			eff = float(nm.call("get_work_efficiency"))

	if hunger_meter: hunger_meter.value = hunger
	if energy_meter: energy_meter.value = energy
	if hygiene_meter: hygiene_meter.value = hygiene
	if stress_meter: stress_meter.value = 100.0 - stress

	if hunger_val_label: hunger_val_label.text = "%d%%" % int(hunger)
	if energy_val_label: energy_val_label.text = "%d%%" % int(energy)
	if hygiene_val_label: hygiene_val_label.text = "%d%%" % int(hygiene)
	if stress_val_label: stress_val_label.text = "%d%%" % int(stress)

	if efficiency_label:
		efficiency_label.text = "Work Efficiency: %d%%" % int(round(eff * 100.0))

	_populate_skills_list()

func _populate_skills_list() -> void:
	if not skills_list_container:
		return

	for child in skills_list_container.get_children():
		skills_list_container.remove_child(child)
		child.queue_free()

	# Check SkillManager first
	var sm := get_node_or_null("/root/SkillManager")
	var skills_found: bool = false

	if sm and "skills" in sm and sm.skills is Dictionary:
		skills_found = true
		for skill_name: String in sm.skills.keys():
			var data: Dictionary = sm.skills[skill_name]
			var lvl: int = int(data.get("level", 1))
			var xp: float = float(data.get("xp", 0.0))

			var row := HBoxContainer.new()
			var name_lbl := Label.new()
			name_lbl.text = "★ " + skill_name.capitalize()
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_lbl.add_theme_font_size_override("font_size", 13)

			var lvl_lbl := Label.new()
			lvl_lbl.text = "Level %d (XP: %d)" % [lvl, int(xp)]
			lvl_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			lvl_lbl.add_theme_font_size_override("font_size", 13)

			row.add_child(name_lbl)
			row.add_child(lvl_lbl)
			skills_list_container.add_child(row)

	# If no SkillManager, check CareerManager.player_skills
	if not skills_found:
		var cm := get_node_or_null("/root/CareerManager")
		var p_skills: Array = []
		if cm and "player_skills" in cm and cm.player_skills is Array:
			p_skills = cm.player_skills

		if p_skills.is_empty():
			var no_skill_lbl := Label.new()
			no_skill_lbl.text = "No certifications acquired yet.\nTrain at academies or work shifts to unlock."
			no_skill_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			no_skill_lbl.add_theme_font_size_override("font_size", 12)
			skills_list_container.add_child(no_skill_lbl)
		else:
			for s in p_skills:
				var row := HBoxContainer.new()
				var s_lbl := Label.new()
				s_lbl.text = "★ " + str(s).capitalize()
				s_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(s_lbl)
				skills_list_container.add_child(row)

# ------------------------------------------------------------------------------
# Helpers & Signal Callbacks
# ------------------------------------------------------------------------------

func _on_money_changed(_new_balance: int) -> void:
	if is_open and current_app == "bank":
		update_bank_view()

func _on_transaction_completed(_amount: int, _reason: String) -> void:
	if is_open and current_app == "bank":
		update_bank_view()

func _on_time_tick(_hour: Variant = null, _minute: Variant = null) -> void:
	if is_open:
		_update_time_and_date()
		if current_app == "jobs":
			update_jobs_view()
		elif current_app == "status":
			update_status_view()

func _on_job_changed(_job: Dictionary) -> void:
	if is_open and current_app == "jobs":
		update_jobs_view()

func _on_job_started(_job: Dictionary) -> void:
	if is_open and current_app == "jobs":
		update_jobs_view()

func _on_job_completed(_earnings: int) -> void:
	if is_open:
		if current_app == "jobs":
			update_jobs_view()
		elif current_app == "bank":
			update_bank_view()

func _format_number(amount: int) -> String:
	var s: String = str(abs(amount))
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			res = "," + res
		res = s[i] + res
		count += 1
	return res
