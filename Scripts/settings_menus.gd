extends Panel

@onready var tab: TabContainer = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer

# --- Video ---
@onready var display_options: OptionButton = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/VideoTab/GridContainer/BtnResolutionDropdown
@onready var display_fps_btn: CheckButton = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/VideoTab/GridContainer/BtnFps
@onready var max_fps_slider: HSlider = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/VideoTab/GridContainer/MaxFPSContainer/SliderMaxFPS
@onready var max_fps_value: Label = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/VideoTab/GridContainer/MaxFPSContainer/LabelCurrentFPS
@onready var brightness_slider: HSlider = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/VideoTab/GridContainer/SliderBrightness

# --- Audio ---
@onready var audio_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/AudioTab/GridContainer
@onready var audio_label_template: Label = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/AudioTab/GridContainer/AudioLabelTemplate
@onready var audio_slider_template: HSlider = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/AudioTab/GridContainer/AudioSliderTemplate
var audio_sliders: Dictionary[String, HSlider] = {}
var audio_initialized: bool = false

# --- Controls ---
@onready var control_grid: GridContainer = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/ControlsTab/ScrollContainer/VBoxContainer/GridContainer
@onready var control_label_template: Label = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/ControlsTab/ScrollContainer/VBoxContainer/GridContainer/ControlLabelTemplate
@onready var control_button_template: Button = $MarginContainer/VBoxContainer/HBoxContainer/TabContainer/ControlsTab/ScrollContainer/VBoxContainer/GridContainer/ControlButtonTemplate
var action_buttons: Dictionary[String, Button] = {}
var waiting_for_action: String = ""

# --- Actions ---
@onready var btn_exit: Button = $MarginContainer/VBoxContainer/ActionsContainer/ExitButton
@onready var btn_reset: Button = $MarginContainer/VBoxContainer/ActionsContainer/ResetButton


func _ready() -> void:
	hide()
	GlobalSettings.brightness_changed.connect(_on_brightness_live_update)
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))

	# Conectar botones de pestañas
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Video.pressed.connect(func(): tab.current_tab = 0)
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Audio.pressed.connect(func(): tab.current_tab = 1)
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/Controls.pressed.connect(func(): tab.current_tab = 2)
	tab.current_tab = 0

	# Conectar botones de acción (salir y reset)
	if not btn_exit.pressed.is_connected(_on_exit_button_pressed):
		btn_exit.pressed.connect(_on_exit_button_pressed)
	if not btn_reset.pressed.is_connected(_on_reset_button_pressed):
		btn_reset.pressed.connect(_on_reset_button_pressed)

	_update_video_settings()
	_create_dynamic_audio_controls()
	_create_dynamic_control_list()
	_center_on_screen()


func _on_visibility_changed() -> void:
	if visible:
		_center_on_screen()
		_update_video_settings()
		if not audio_initialized:
			_update_audio_settings()
			audio_initialized = true


func _on_exit_button_pressed() -> void:
	hide()


func _unhandled_input(_event) -> void:
	pass  # Intencional para evitar warnings


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if waiting_for_action != "":
			accept_event()

			if event.physical_keycode == KEY_ESCAPE:
				action_buttons[waiting_for_action].text = _get_first_key(waiting_for_action)
				waiting_for_action = ""
				return

			var new_key: int = event.physical_keycode
			if GlobalSettings.save_control(waiting_for_action, new_key):
				action_buttons[waiting_for_action].text = OS.get_keycode_string(new_key)
			else:
				action_buttons[waiting_for_action].text = _get_first_key(waiting_for_action)
			waiting_for_action = ""
		else:
			if event.physical_keycode == KEY_ESCAPE:
				hide()


func _center_on_screen() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	position = (vp_size - size) * 0.5


func _update_video_settings() -> void:
	display_options.select(GlobalSettings.resolution_index)
	display_fps_btn.set_pressed(GlobalSettings.show_fps)
	
	if GlobalSettings.max_fps > 0:
		max_fps_slider.value = float(GlobalSettings.max_fps)
		max_fps_value.text = str(GlobalSettings.max_fps)
	else:
		max_fps_slider.value = max_fps_slider.max_value
		max_fps_value.text = "max"
	
	brightness_slider.value = GlobalSettings.brightness


func _on_btn_resolution_dropdown_item_selected(index: int) -> void:
	GlobalSettings.set_resolution_index(index)


func _on_btn_fps_toggled(pressed: bool) -> void:
	GlobalSettings.toggle_fps_display(pressed)


func _on_slider_max_fps_value_changed(value: float) -> void:
	GlobalSettings.set_max_fps(value)
	if value < max_fps_slider.max_value:
		max_fps_value.text = str(int(value))
	else:
		max_fps_value.text = "max"


func _on_slider_brightness_value_changed(value: float) -> void:
	GlobalSettings.update_brightness(value)


func _on_brightness_live_update(value: float) -> void:
	if brightness_slider.value != value:
		brightness_slider.value = value


func _create_dynamic_audio_controls() -> void:
	audio_sliders.clear()
	for child in audio_grid.get_children():
		if child != audio_label_template and child != audio_slider_template:
			audio_grid.remove_child(child)
			child.queue_free()

	var bus_count: int = AudioServer.get_bus_count()
	for i in range(bus_count):
		var bus_name: String = AudioServer.get_bus_name(i)

		var label: Label = audio_label_template.duplicate()
		label.visible = true
		label.text = bus_name

		var slider: HSlider = audio_slider_template.duplicate()
		slider.visible = true
		slider.value = GlobalSettings.get_bus_volume(bus_name)
		
		# Conectar con función anónima para pasar bus_name y value correctamente
		slider.value_changed.connect(func(value: float): GlobalSettings.update_audio_bus(bus_name, value))

		audio_grid.add_child(label)
		audio_grid.add_child(slider)
		audio_sliders[bus_name] = slider


func _update_audio_settings() -> void:
	for bus_name in audio_sliders.keys():
		audio_sliders[bus_name].value = GlobalSettings.get_bus_volume(bus_name)


func _create_dynamic_control_list() -> void:
	action_buttons.clear()
	for child in control_grid.get_children():
		if child != control_label_template and child != control_button_template:
			control_grid.remove_child(child)
			child.queue_free()

	var actions: Array = InputMap.get_actions()
	for action in actions:
		if action.begins_with("ui_"):  # Filtrar acciones internas
			continue

		var label: Label = control_label_template.duplicate()
		label.visible = true
		label.text = action

		var button: Button = control_button_template.duplicate()
		button.visible = true
		button.text = _get_first_key(action)
		button.pressed.connect(Callable(self, "_start_key_remap").bind(action, button))

		control_grid.add_child(label)
		control_grid.add_child(button)
		action_buttons[action] = button


func _get_first_key(action: String) -> String:
	var events: Array = InputMap.action_get_events(action)
	if events.size() > 0 and events[0] is InputEventKey:
		return OS.get_keycode_string(events[0].physical_keycode)
	return "..."


func _start_key_remap(action: String, button: Button) -> void:
	waiting_for_action = action
	button.text = "Presiona una tecla..."


func _on_reset_button_pressed() -> void:
	GlobalSettings.reset_to_defaults()
	_update_video_settings()
	_update_audio_settings()
	_create_dynamic_control_list()
