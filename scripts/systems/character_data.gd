class_name CharacterData
extends RefCounted
## Character Registry & Data helper for Yangon Life.
##
## Manages 32 selectable character styles, archetype profiles,
## sprite sheet paths, and cropped 32x32 UI portrait atlas generation.

const TOTAL_CHARACTERS: int = 32

const PRESETS: Array[Dictionary] = [
	{
		"index": 1,
		"name": "Ko Thet",
		"role": "Novice Citizen",
		"desc": "Arrived in downtown Yangon with modest savings. Determined to build a new life.",
		"bonus": "Balanced Needs | 50,000 MMK Starting Cash"
	},
	{
		"index": 2,
		"name": "Ko Zaw",
		"role": "City Hall Clerk",
		"desc": "Civil administrator at Yangon City Hall. Knowledgeable in public municipal services.",
		"bonus": "+1 Customer Service Skill | +10,000 MMK Bonus"
	},
	{
		"index": 3,
		"name": "Ma Thida",
		"role": "KBZ Bank Specialist",
		"desc": "Mobile wallet expert managing Kyat commerce and merchant ledgers.",
		"bonus": "+1 Business Management | 10% Lower Rent"
	},
	{
		"index": 4,
		"name": "U Bo Htay",
		"role": "Senior Employment Broker",
		"desc": "Respected trade recruiter with connections across all downtown business sectors.",
		"bonus": "+1 Customer Service | Faster Shift Approvals"
	},
	{
		"index": 26,
		"name": "Ashin Teza",
		"role": "Theravada Monk",
		"desc": "Practices mindfulness and meditation in the shadow of Sule Pagoda.",
		"bonus": "+50% Stress Resilience | Double Rest Recovery"
	},
	{
		"index": 8,
		"name": "Daw Lay",
		"role": "Street Food Chef",
		"desc": "Veteran cook famous for aromatic Mohinga soup broth and crispy Burmese fritters.",
		"bonus": "+2 Cooking Skill | 50% Cheaper Market Food"
	},
	{
		"index": 7,
		"name": "Ko Phyo",
		"role": "Express Courier",
		"desc": "Energetic bicycle courier navigating Yangon's bustling alleys and traffic.",
		"bonus": "+20% Courier Cycling Speed | Higher Stamina"
	},
	{
		"index": 11,
		"name": "U Ba",
		"role": "Veteran Taxi Driver",
		"desc": "Yangon native who knows every shortcut from Sule Pagoda to Botahtaung Jetty.",
		"bonus": "+1 Driving Skill | Immediate Taxi Access"
	}
]

## Returns the sprite sheet path for a given character index (1 to 32)
static func get_sprite_sheet_path(character_index: int) -> String:
	var idx: int = clampi(character_index, 1, TOTAL_CHARACTERS)
	return "res://assets/new/SuperRetroWorld_CharacterPack_Full/SuperRetroWorld_CharacterPack_Full/sprite_split/character_%d/character_%d_frame32x32.png" % [idx, idx]

## Returns a cropped 32x32 AtlasTexture of the character's front-facing neutral frame
static func get_character_portrait(character_index: int) -> AtlasTexture:
	var path: String = get_sprite_sheet_path(character_index)
	var tex: Texture2D = load(path) as Texture2D
	if not tex:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	# Front-facing standing frame is column 1 (x: 32..64) and row 0 (y: 0..32)
	atlas.region = Rect2(32.0, 0.0, 32.0, 32.0)
	return atlas

## Returns preset data or generates a default citizen record
static func get_preset_for_index(character_index: int) -> Dictionary:
	var idx: int = clampi(character_index, 1, TOTAL_CHARACTERS)
	for p in PRESETS:
		if int(p.get("index", 1)) == idx:
			return p
	return {
		"index": idx,
		"name": "Citizen #%d" % idx,
		"role": "Yangon Resident",
		"desc": "An ambitious resident striving for success in downtown Yangon.",
		"bonus": "Standard citizen attributes"
	}
