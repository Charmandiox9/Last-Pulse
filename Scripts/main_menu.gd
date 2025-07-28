extends Control

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/zone_of_silence.tscn")

func _on_settings_btn_pressed() -> void:
	$SettingsMenu.show()

func _on_credits_btn_pressed() -> void:
	pass # Replace with function body.

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
