extends CanvasLayer

var brightness_rect: ColorRect
var mat: ShaderMaterial
var _shader: Shader

func _ready() -> void:
	# 1) Que siempre se dibuje al final
	layer = 100

	# 2) Crear (o encontrar) el overlay full-screen
	brightness_rect = get_node_or_null("BrightnessOverlay")
	if brightness_rect == null:
		brightness_rect = ColorRect.new()
		brightness_rect.name = "BrightnessOverlay"
		brightness_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		brightness_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(brightness_rect)

	# 3) Preparar el shader
	_shader = Shader.new()
	_shader.code = """
		shader_type canvas_item;
		uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
		uniform float brightness = 1.0;
		void fragment() {
			vec4 src = texture(screen_tex, SCREEN_UV);
			COLOR = vec4(src.rgb * brightness, src.a);
		}
	"""

	# 4) Material para el overlay
	mat = ShaderMaterial.new()
	mat.shader = _shader
	brightness_rect.material = mat

	# 5) Conectar la señal de GlobalSettings
	GlobalSettings.brightness_changed.connect(_on_brightness_changed)

	# 6) Aplicar valor inicial
	_on_brightness_changed(GlobalSettings.brightness)

func _on_brightness_changed(value: float) -> void:
	var safe = clamp(value, 0.1, 2.0)
	mat.set_shader_parameter("brightness", safe)
