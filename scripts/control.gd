extends Control

@onready var background_music: AudioStreamPlayer2D = $BackgroundMusic

func _ready() -> void:
	background_music.play()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/fase_1.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
