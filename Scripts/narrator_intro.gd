extends CanvasLayer

func _ready() -> void:
	# Esperar un frame para asegurar que todos los nodos estén listos
	await get_tree().process_frame
	
	var anim = $AnimationPlayer
	var audio = $AudioStreamPlayer
	
	# Verificar que ambos nodos existan
	if anim == null:
		print("Error: AnimationPlayer no encontrado")
		return
	
	if audio == null:
		print("Error: AudioStreamPlayer no encontrado")
		return
	
	get_tree().paused = true
	
	anim.play("narrator_play")
	audio.play()
	
	await anim.animation_finished
	get_tree().paused = false
