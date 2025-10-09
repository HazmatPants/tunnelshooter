extends Control

@onready var playButton: MenuButton = $PlayButton

func _ready() -> void:
	playButton.get_popup().index_pressed.connect(_playButton_pressed)

func _playButton_pressed(idx: int):
	if idx == 0:
		Global.is_initialized = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")
