extends Node

signal fps_displayed(value: bool)
signal brightness_changed(value: float)

# --- Video ---
var resolution_index: int = 3
var show_fps: bool = false
var max_fps: int = 0
var brightness: float = 1.0

# --- Audio ---
var audio_volumes: Dictionary = {} # { "BusName": volumen_dB }

# ---------------- READY ----------------
func _ready() -> void:
	load_settings()
	apply_resolution()
	apply_fps()
	emit_signal("brightness_changed", brightness)
	apply_audio()

# ---------------- RESET TO DEFAULTS ----------------
func reset_to_defaults() -> void:
	# Video defaults
	resolution_index = 3  # Fullscreen
	show_fps = false
	max_fps = 0
	brightness = 1.0

	# Audio defaults
	_initialize_default_audio_volumes()

	# Controles defaults
	_reset_controls_to_default()

	# Aplicar cambios
	apply_resolution()
	apply_fps()
	emit_signal("brightness_changed", brightness)
	apply_audio()
	save_settings()

# ---------------- RESOLUCIÓN ----------------
func set_resolution_index(index: int) -> void:
	resolution_index = index
	apply_resolution()
	save_settings()

func apply_resolution() -> void:
	match resolution_index:
		0: _set_windowed_resolution(Vector2i(640, 360))
		1: _set_windowed_resolution(Vector2i(1280, 720))
		2: _set_windowed_resolution(Vector2i(1920, 1080))
		3: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _set_windowed_resolution(size: Vector2i) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await get_tree().process_frame
	DisplayServer.window_set_size(size)

# ---------------- FPS ----------------
func toggle_fps_display(toggle: bool) -> void:
	show_fps = toggle
	emit_signal("fps_displayed", toggle)
	save_settings()

func set_max_fps(value: float) -> void:
	max_fps = int(value)
	apply_fps()
	save_settings()

func apply_fps() -> void:
	Engine.max_fps = max_fps if max_fps > 0 else 0

# ---------------- BRILLO ----------------
func update_brightness(value: float) -> void:
	brightness = clamp(value, 0.1, 2.0)
	emit_signal("brightness_changed", brightness)
	save_settings()

# ---------------- AUDIO ----------------
func update_audio_bus(bus_name: String, vol: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("Bus de audio no encontrado: %s" % bus_name)
		return

	AudioServer.set_bus_mute(bus_idx, vol <= -50.0)
	if vol > -50.0:
		AudioServer.set_bus_volume_db(bus_idx, vol)

	audio_volumes[bus_name] = vol
	save_settings()

func get_bus_volume(bus_name: String) -> float:
	return audio_volumes.get(bus_name, -15.0)

func apply_audio() -> void:
	var bus_count: int = AudioServer.get_bus_count()
	for i in range(bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		var vol: float = audio_volumes.get(bus_name, -15.0)
		update_audio_bus(bus_name, vol)

# ---------------- CONTROLES (API PÚBLICA) ----------------
func save_control(action_name: String, key_code: int) -> bool:
	if not InputMap.has_action(action_name):
		push_warning("Acción no existe: %s" % action_name)
		return false

	# Evitar duplicados
	for other_action in InputMap.get_actions():
		if other_action == action_name:
			continue
		var events: Array = InputMap.action_get_events(other_action)
		for e in events:
			if e is InputEventKey and e.physical_keycode == key_code:
				push_warning("Tecla %s ya asignada a la acción %s" % [OS.get_keycode_string(key_code), other_action])
				return false

	InputMap.action_erase_events(action_name)
	var ev: InputEventKey = InputEventKey.new()
	@warning_ignore("INT_AS_ENUM_WITHOUT_CAST")
	ev.physical_keycode = key_code
	InputMap.action_add_event(action_name, ev)

	save_settings()
	return true

func save_controls() -> void:
	save_settings()

# ---------------- CONFIGURACIÓN ----------------
func save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()

	# --- Video
	config.set_value("display", "resolution_index", resolution_index)
	config.set_value("video", "show_fps", show_fps)
	config.set_value("video", "max_fps", max_fps)
	config.set_value("video", "brightness", brightness)

	# --- Audio
	var audio_data: Dictionary = {}
	for bus_name in audio_volumes.keys():
		audio_data[bus_name] = audio_volumes[bus_name]
	config.set_value("audio", "volumes", audio_data)

	# --- Controles
	_save_controls_to_config(config)

	config.save("user://settings.cfg")

func load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		# --- Video
		resolution_index = config.get_value("display", "resolution_index", 3)
		show_fps        = config.get_value("video", "show_fps", false)
		max_fps         = config.get_value("video", "max_fps", 0)
		brightness      = config.get_value("video", "brightness", 1.0)

		# --- Audio
		audio_volumes.clear()
		var audio_data: Dictionary = config.get_value("audio", "volumes", {}) as Dictionary
		var bus_count: int = AudioServer.get_bus_count()
		for i in range(bus_count):
			var bus_name: String = AudioServer.get_bus_name(i)
			audio_volumes[bus_name] = audio_data.get(bus_name, -15.0)

		# --- Controles
		_load_controls_from_config(config)
	else:
		_initialize_default_audio_volumes()

func _initialize_default_audio_volumes() -> void:
	audio_volumes.clear()
	var bus_count: int = AudioServer.get_bus_count()
	for i in range(bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)
		audio_volumes[bus_name] = -15.0

# ---------------- CONTROLES (INTERNAL) ----------------
func _save_controls_to_config(config: ConfigFile) -> void:
	var controls_data: Dictionary = {}
	var actions: Array = InputMap.get_actions()
	for action in actions:
		var events: Array = InputMap.action_get_events(action)
		for e in events:
			if e is InputEventKey:
				controls_data[action] = e.physical_keycode
				break

	config.set_value("controls", "keys", controls_data)

func _load_controls_from_config(config: ConfigFile) -> void:
	var controls_data: Dictionary = config.get_value("controls", "keys", {}) as Dictionary
	for action in controls_data.keys():
		var key_code: int = controls_data[action]
		if not InputMap.has_action(action):
			continue
		InputMap.action_erase_events(action)
		var ev: InputEventKey = InputEventKey.new()
		@warning_ignore("INT_AS_ENUM_WITHOUT_CAST")
		ev.physical_keycode = key_code
		InputMap.action_add_event(action, ev)

# ---------------- RESET CONTROLS DEFAULT ----------------
func _reset_controls_to_default() -> void:
	# Aquí define tus controles por defecto
	var default_keys := {
		"move_up": KEY_W,
		"move_down": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"shoot": KEY_SPACE
	}

	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		InputMap.action_erase_events(action)
		if default_keys.has(action):
			var ev := InputEventKey.new()
			@warning_ignore("INT_AS_ENUM_WITHOUT_CAST")
			ev.physical_keycode = default_keys[action]
			InputMap.action_add_event(action, ev)
