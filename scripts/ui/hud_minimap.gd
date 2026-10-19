class_name HUDMinimap
extends Control

## Real-time GPS Minimap & Radar for Yangon Life (ရန်ကုန် ဘဝ).
##
## Tracks player coordinates across Downtown Yangon, visualizes arterial roads,
## key cultural landmarks (Sule, Chinatown, Secretariat, Riverfront, Railway Station),
## and locates nearby rideable vehicles (Taxis, Motorcycles, Bicycles).

signal district_changed(new_district: String)
signal zoom_changed(radar_radius: float)

@export var radar_radius: float = 120.0 # meters visible from center to edge
@export var zoom_levels: Array[float] = [80.0, 160.0, 300.0]
var current_zoom_index: int = 1

var player_node: Node3D = null
var current_district: String = "Sule Pagoda Plaza"

# Prominent downtown landmarks with coordinates and signature radar colors
const POIS: Array[Dictionary] = [
	{"name": "Sule Pagoda", "pos": Vector2(0.0, 0.0), "color": Color(1.0, 0.84, 0.0), "code": "S"},
	{"name": "City Hall", "pos": Vector2(30.0, -50.0), "color": Color(0.3, 0.8, 0.3), "code": "H"},
	{"name": "Maha Bandula Park", "pos": Vector2(35.0, 35.0), "color": Color(0.4, 0.9, 0.4), "code": "P"},
	{"name": "Chinatown 19th St", "pos": Vector2(-130.0, 30.0), "color": Color(0.95, 0.2, 0.2), "code": "C"},
	{"name": "Theingyi Zei Bazaar", "pos": Vector2(-130.0, -90.0), "color": Color(1.0, 0.6, 0.1), "code": "M"},
	{"name": "Secretariat Complex", "pos": Vector2(130.0, -90.0), "color": Color(0.7, 0.2, 0.7), "code": "B"},
	{"name": "Strand Riverfront & Jetty", "pos": Vector2(0.0, 240.0), "color": Color(0.1, 0.7, 1.0), "code": "J"},
	{"name": "Central Railway Station", "pos": Vector2(0.0, -220.0), "color": Color(0.4, 0.4, 0.9), "code": "R"},
	{"name": "Gas Station Refuel", "pos": Vector2(45.0, 40.0), "color": Color(1.0, 0.9, 0.2), "code": "G"}
]

func _ready() -> void:
	radar_radius = zoom_levels[current_zoom_index]

func _process(_delta: float) -> void:
	if not is_instance_valid(player_node):
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			player_node = p_nodes[0] as Node3D

	if is_instance_valid(player_node):
		var dist := get_district_name(player_node.global_position)
		if dist != current_district:
			current_district = dist
			district_changed.emit(current_district)

	queue_redraw()

func toggle_zoom() -> float:
	current_zoom_index = (current_zoom_index + 1) % zoom_levels.size()
	radar_radius = zoom_levels[current_zoom_index]
	zoom_changed.emit(radar_radius)
	return radar_radius

## Calculates player district based on spatial sector in Yangon
func get_district_name(pos: Vector3) -> String:
	if pos.z > 170.0:
		return "Strand Riverfront & Ferry Jetty"
	if pos.z < -160.0:
		return "Central Railway District"
	if pos.x < -70.0 and pos.z > -20.0:
		return "Chinatown & 19th St Night Market"
	if pos.x < -70.0 and pos.z <= -20.0:
		return "Theingyi Zei Wholesale Bazaar"
	if pos.x > 70.0 and pos.z < 0.0:
		return "Secretariat Heritage Complex"
	if pos.x > 5.0 and pos.z > 10.0 and pos.z < 80.0:
		return "Maha Bandula Park & Monument"
	if pos.x > 10.0 and pos.z < -20.0 and pos.z > -80.0:
		return "Yangon City Hall & High Court"
	return "Sule Pagoda Central Plaza"

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var center := Vector2(w * 0.5, h * 0.5)
	var radius: float = minf(w, h) * 0.48

	# Background dark radar circle
	draw_circle(center, radius, Color(0.06, 0.09, 0.13, 0.88))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.3, 0.45, 0.6, 0.9), 2.0)
	draw_arc(center, radius * 0.5, 0.0, TAU, 32, Color(0.2, 0.35, 0.5, 0.4), 1.0)

	# Crosshairs (North-South & East-West)
	draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), Color(0.2, 0.35, 0.5, 0.4), 1.0)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), Color(0.2, 0.35, 0.5, 0.4), 1.0)

	# North indicator badge
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 4, center.y - radius + 14), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.9, 0.3, 0.3))

	if not is_instance_valid(player_node):
		return

	var p_pos := player_node.global_position
	var scale_factor: float = radius / radar_radius

	# Draw arterial roads relative to player
	_draw_road(center, scale_factor, radius, p_pos, Vector2(0.0, -300.0), Vector2(0.0, 300.0), 4.0) # Sule Pagoda Rd NS
	_draw_road(center, scale_factor, radius, p_pos, Vector2(-300.0, 0.0), Vector2(300.0, 0.0), 4.0) # Maha Bandula Rd EW
	_draw_road(center, scale_factor, radius, p_pos, Vector2(-300.0, 210.0), Vector2(300.0, 210.0), 3.0) # Strand Rd
	_draw_road(center, scale_factor, radius, p_pos, Vector2(-300.0, -180.0), Vector2(300.0, -180.0), 3.0) # Bogyoke Rd
	_draw_road(center, scale_factor, radius, p_pos, Vector2(-130.0, -300.0), Vector2(-130.0, 300.0), 2.5) # Chinatown 19th St
	_draw_road(center, scale_factor, radius, p_pos, Vector2(130.0, -300.0), Vector2(130.0, 300.0), 2.5) # Secretariat St

	# Draw Landmarks (POIs)
	for poi in POIS:
		var poi_pos: Vector2 = poi["pos"]
		var offset := Vector2(poi_pos.x - p_pos.x, poi_pos.y - p_pos.z)
		var r_pos := center + offset * scale_factor
		if (r_pos - center).length() < radius - 8.0:
			var col: Color = poi["color"]
			draw_circle(r_pos, 4.5, col)
			draw_circle(r_pos, 6.0, Color(col.r, col.g, col.b, 0.3))
			draw_string(ThemeDB.fallback_font, r_pos + Vector2(6, 4), String(poi["code"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.9))

	# Draw nearby rideable vehicles (Taxis, Motorcycles, Bicycles)
	var vehicles := get_tree().get_nodes_in_group("vehicles")
	for v in vehicles:
		if v is Node3D and v != player_node:
			var v3: Node3D = v as Node3D
			var v_offset := Vector2(v3.global_position.x - p_pos.x, v3.global_position.z - p_pos.z)
			var vr_pos := center + v_offset * scale_factor
			if (vr_pos - center).length() < radius - 4.0:
				draw_circle(vr_pos, 3.5, Color(1.0, 0.85, 0.2)) # Yellow vehicle dot

	# Draw Player in center with heading triangle
	var cam_yaw: float = 0.0
	if player_node.has_node("CameraYaw"):
		cam_yaw = player_node.get_node("CameraYaw").rotation.y
	else:
		cam_yaw = player_node.rotation.y

	# Player center dot
	draw_circle(center, 4.0, Color(1.0, 1.0, 1.0))
	draw_arc(center, 6.0, 0.0, TAU, 16, Color(0.2, 0.8, 1.0), 2.0)

	# Direction arrow pointing forward relative to radar orientation
	var heading_dir := Vector2(sin(-cam_yaw), -cos(-cam_yaw)) * 12.0
	var right_dir := Vector2(-heading_dir.y, heading_dir.x) * 0.4
	draw_line(center, center + heading_dir, Color(0.2, 0.85, 1.0), 2.5)
	draw_line(center + heading_dir, center + heading_dir * 0.6 + right_dir, Color(0.2, 0.85, 1.0), 2.0)
	draw_line(center + heading_dir, center + heading_dir * 0.6 - right_dir, Color(0.2, 0.85, 1.0), 2.0)

func _draw_road(center: Vector2, scale_factor: float, radius: float, p_pos: Vector3, start_pt: Vector2, end_pt: Vector2, width: float) -> void:
	var r_start := center + Vector2(start_pt.x - p_pos.x, start_pt.y - p_pos.z) * scale_factor
	var r_end := center + Vector2(end_pt.x - p_pos.x, end_pt.y - p_pos.z) * scale_factor

	# Clip roughly inside circle
	if (r_start - center).length() > radius and (r_end - center).length() > radius:
		var mid := (r_start + r_end) * 0.5
		if (mid - center).length() > radius * 1.2:
			return

	draw_line(r_start, r_end, Color(0.25, 0.32, 0.42, 0.45), width)
