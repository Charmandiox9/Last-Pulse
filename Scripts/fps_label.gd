extends Label

@export var alert_threshold: int = 30               # FPS mínimo aceptable
@export var alert_color: Color = Color.RED          # Color cuando fps es bajo
@export var normal_color: Color = Color.WHITE       # Color normal

func _ready() -> void:
	# Sincroniza visibilidad con GlobalSettings (si existe la señal)
	if GlobalSettings.has_signal("fps_displayed"):
		GlobalSettings.fps_displayed.connect(_on_fps_displayed)
		visible = GlobalSettings.show_fps
	
	_update_color(int(round(Engine.get_frames_per_second())))

func _process(_delta: float) -> void:
	var fps := int(round(Engine.get_frames_per_second()))
	text = "FPS: %d" % fps
	_update_color(fps)

func _update_color(fps: int) -> void:
	if fps < alert_threshold:
		add_theme_color_override("font_color", alert_color)
	else:
		add_theme_color_override("font_color", normal_color)

func _on_fps_displayed(value: bool) -> void:
	visible = value
