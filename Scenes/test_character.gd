extends CharacterBody2D

# Constantes de movimiento
const SPEED = 120
const JUMP_VELOCITY = 175
const GRAVITY = 9

# Constantes de zoom
const DEFAULT_ZOOM = Vector2(3.0, 3.0)
const CLOSE_ZOOM = Vector2(1.5, 1.5)
const ZOOM_SPEED = 2.0

# Variables
var direction = 0.0
var target_zoom = DEFAULT_ZOOM

# Referencias a nodos
@onready var animationPlayer = $AnimationPlayer
@onready var animaciones = $AnimatedSprite2D
@onready var PlayerCam = $Cameras/PlayerCam

func _physics_process(delta: float) -> void:
	# Obtener dirección de movimiento
	direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED
	
	# Gestionar salto
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		velocity.y -= JUMP_VELOCITY
	
	# Aplicar gravedad si no está en el suelo
	if !is_on_floor():
		velocity.y += GRAVITY
	
	# Gestionar animaciones
	_handle_animations()
	
	# Voltear el sprite según la dirección
	if direction != 0:
		animaciones.flip_h = direction < 0
	
	# Suavizar el zoom hacia el objetivo
	PlayerCam.zoom = PlayerCam.zoom.lerp(target_zoom, ZOOM_SPEED * delta)
	
	# Aplicar el movimiento
	move_and_slide()

func _handle_animations():
	# Prioridad: Primero verificar si está en el aire
	if !is_on_floor():
		if velocity.y < 0:  # Subiendo (saltando)
			animaciones.play("Jump")
		else:  # Cayendo
			# Si tienes animación de caída, úsala aquí
			animaciones.play("Jump")  # O "Fall" si tienes esa animación
	# Si está en el suelo, verificar movimiento horizontal	
	elif direction != 0:
		animaciones.play("Walk")
	else:
		animaciones.play("Idle")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == self:  # Verificar que sea el jugador
		target_zoom = CLOSE_ZOOM

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == self:  # Verificar que sea el jugador
		target_zoom = DEFAULT_ZOOM
