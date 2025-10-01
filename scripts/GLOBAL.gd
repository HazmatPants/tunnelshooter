extends Node

@export var music_enabled: bool = false
@export var infinite_ammo: bool = true

@onready var playerScene = get_tree().get_current_scene()
@onready var player = get_tree().get_current_scene().get_node("Player")
@onready var playerGUI = get_tree().get_current_scene().get_node("PlayerGUI")


var bgm_pain: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	bgm_pain.stream = preload("res://assets/audio/music/PainDrone.ogg")
	bgm_pain.autoplay = true
	get_tree().current_scene.add_child(bgm_pain)

func _process(_delta: float) -> void:
	bgm_pain.volume_db = linear_to_db(clamp(player.healthCtl.get_limb_all("pain").values().max() - 0.1, 0.0, 1.0))
