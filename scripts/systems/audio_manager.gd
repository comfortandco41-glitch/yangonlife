extends Node
## Audio Manager — Procedural Soundscapes, Foley, UI Clicks & Ambient City Audio for Yangon Life
##
## Fully browser-first and WebGL2-compatible: Synthesizes AudioStreamWAV sample buffers
## in GDScript at runtime with zero external binary dependencies.

signal audio_unlocked

var _ui_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _weather_player: AudioStreamPlayer

var _sample_cache: Dictionary = {}
var is_unlocked: bool = false
var _last_balance: int = 50000

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()
	_generate_audio_samples()
	_connect_system_signals()

func _setup_audio_players() -> void:
	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "UIPlayer"
	_ui_player.bus = "Master"
	add_child(_ui_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = "Master"
	_ambience_player.volume_db = -12.0
	add_child(_ambience_player)

	_weather_player = AudioStreamPlayer.new()
	_weather_player.name = "WeatherPlayer"
	_weather_player.bus = "Master"
	_weather_player.volume_db = -10.0
	add_child(_weather_player)

func _generate_audio_samples() -> void:
	_sample_cache["click"] = _generate_tone_stream(1400.0, 0.035, true, 0.4)
	_sample_cache["coin"] = _generate_chime_stream(659.25, 880.0, 0.16) # E5 + A5 MMK chime
	_sample_cache["footstep"] = _generate_tone_stream(160.0, 0.045, true, 0.25)
	_sample_cache["alert"] = _generate_tone_stream(880.0, 0.08, false, 0.3)
	_sample_cache["city_ambience"] = _generate_rumble_stream(1.5, 0.15)
	_sample_cache["rain_ambience"] = _generate_hiss_stream(1.2, 0.2)

	# Start background ambient traffic murmur
	if _ambience_player and _sample_cache.has("city_ambience"):
		_ambience_player.stream = _sample_cache["city_ambience"]
		_ambience_player.play()

func _connect_system_signals() -> void:
	if root_has_singleton("EconomyManager"):
		var em = get_node("/root/EconomyManager")
		if em.has_signal("money_changed"):
			_last_balance = em.get("balance") if "balance" in em else 50000
			em.connect("money_changed", Callable(self, "_on_economy_money_changed"))

func root_has_singleton(singleton_name: String) -> bool:
	var tree = get_tree()
	if tree and tree.root and tree.root.has_node(singleton_name):
		return true
	return false

func _on_economy_money_changed(new_balance: int) -> void:
	if new_balance > _last_balance:
		play_coin()
	elif new_balance < _last_balance:
		play_sfx("click")
	_last_balance = new_balance

## Unlocks WebAudio context (called upon first browser click)
func unlock_audio() -> void:
	if is_unlocked:
		return
	is_unlocked = true
	AudioServer.set_bus_mute(0, false)
	audio_unlocked.emit()
	if _ambience_player and not _ambience_player.playing:
		_ambience_player.play()

func play_ui_click() -> void:
	play_stream_on(_ui_player, "click")

func play_coin() -> void:
	play_stream_on(_sfx_player, "coin")

func play_footstep() -> void:
	play_stream_on(_sfx_player, "footstep")

func play_sfx(sound_name: String) -> void:
	if _sample_cache.has(sound_name):
		play_stream_on(_sfx_player, sound_name)

func set_rain_sound(active: bool) -> void:
	if not _weather_player:
		return
	if active:
		if not _weather_player.playing:
			_weather_player.stream = _sample_cache.get("rain_ambience")
			_weather_player.play()
	else:
		if _weather_player.playing:
			_weather_player.stop()

func play_stream_on(player: AudioStreamPlayer, sound_name: String) -> void:
	if player and _sample_cache.has(sound_name):
		player.stream = _sample_cache[sound_name]
		player.play()

## Procedural 16-bit PCM Sine/Decay Tone Generator
func _generate_tone_stream(freq: float, duration: float, decay: bool, max_amp: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames * 2)

	for i in range(total_frames):
		var t: float = float(i) / float(sample_rate)
		var env: float = 1.0
		if decay:
			env = max(0.0, 1.0 - (float(i) / float(total_frames)))
		var val: float = sin(t * freq * TAU) * env * max_amp
		var sample_int: int = int(clamp(val * 32767.0, -32768.0, 32767.0))
		byte_array.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

## Procedural Dual Frequency Harmonic Chime (for MMK earnings)
func _generate_chime_stream(freq1: float, freq2: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames * 2)

	for i in range(total_frames):
		var t: float = float(i) / float(sample_rate)
		var env: float = max(0.0, 1.0 - (float(i) / float(total_frames)))
		var val: float = (sin(t * freq1 * TAU) * 0.5 + sin(t * freq2 * TAU) * 0.5) * env * 0.45
		var sample_int: int = int(clamp(val * 32767.0, -32768.0, 32767.0))
		byte_array.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

## Procedural Low Frequency City Rumble Loop
func _generate_rumble_stream(duration: float, max_amp: float) -> AudioStreamWAV:
	var sample_rate: int = 11025
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames * 2)

	for i in range(total_frames):
		var t: float = float(i) / float(sample_rate)
		# Combination of low frequencies (45Hz, 70Hz, 110Hz)
		var val: float = (sin(t * 45.0 * TAU) * 0.4 + sin(t * 70.0 * TAU) * 0.35 + sin(t * 110.0 * TAU) * 0.25) * max_amp
		var sample_int: int = int(clamp(val * 32767.0, -32768.0, 32767.0))
		byte_array.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_frames
	stream.data = byte_array
	return stream

## Procedural Rain Droplet Hiss Loop
func _generate_hiss_stream(duration: float, max_amp: float) -> AudioStreamWAV:
	var sample_rate: int = 16000
	var total_frames: int = int(sample_rate * duration)
	var byte_array: PackedByteArray = PackedByteArray()
	byte_array.resize(total_frames * 2)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	for i in range(total_frames):
		var noise: float = rng.randf_range(-1.0, 1.0)
		var val: float = noise * max_amp
		var sample_int: int = int(clamp(val * 32767.0, -32768.0, 32767.0))
		byte_array.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_frames
	stream.data = byte_array
	return stream
