extends Window

#Video Settings
@onready var display_options = $SettingsTab/Video/MarginContainer/VideoSettings/DisplayModeOptions
@onready var vsync_btn = $SettingsTab/Video/MarginContainer/VideoSettings/VsyncBtn
@onready var display_fps_btn = $SettingsTab/Video/MarginContainer/VideoSettings/FpsBtn
@onready var max_fps_slider = $SettingsTab/Video/MarginContainer/VideoSettings/MaxFPSContainer/SliderMaxFps
@onready var current_fps = $SettingsTab/Video/MarginContainer/VideoSettings/MaxFPSContainer/FPS
@onready var brigthness_slider = $SettingsTab/Video/MarginContainer/VideoSettings/MaxBrightnessContainer2/SliderBrightness

#Audio Settings
@onready var master_slider = $SettingsTab/Audio/MarginContainer/GridContainer/SliderMasterVol
@onready var music_slider = $SettingsTab/Audio/MarginContainer/GridContainer/SliderMusicVol
@onready var sfx_slider = $SettingsTab/Audio/MarginContainer/GridContainer/SliderSFXVol


func _ready() -> void:
	popup()
 


func _on_display_mode_options_item_selected(index: int) -> void:
	GlobalSettings.change_displayMode(index)


func _on_vsync_btn_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_fps_btn_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_slider_max_fps_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_slider_brightness_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_slider_master_vol_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_slider_music_vol_value_changed(value: float) -> void:
	pass # Replace with function body.


func _on_slider_sfx_vol_value_changed(value: float) -> void:
	pass # Replace with function body.
