extends Node

@export var music_enabled: bool = false
@export var infinite_ammo: bool = true

var playerScene
var player
var playerGUI

var godmode: bool = false
var flashmode: bool = false

var bgm_pain: AudioStreamPlayer

signal initialized
var is_initialized

func _ready() -> void:
	await get_tree().scene_changed

	playerScene = get_tree().get_current_scene()
	player = get_tree().get_current_scene().get_node("Player")
	playerGUI = get_tree().get_current_scene().get_node("PlayerGUI")

	bgm_pain = AudioStreamPlayer.new()
	bgm_pain.volume_linear = 0.0
	bgm_pain.stream = preload("res://assets/audio/music/PainDrone.ogg")
	bgm_pain.autoplay = true
	get_tree().current_scene.add_child(bgm_pain)

	initialized.emit()
	is_initialized = true

func _process(_delta: float) -> void:
	if not is_initialized:
		return
	if not player:
		return
	bgm_pain.volume_db = linear_to_db(clamp(player.healthCtl.get_limb_all("pain").values().max() - 0.1, 0.0, 1.0))

	if godmode:
		player.healthCtl.consciousness = 1.0
		player.healthCtl.brainHealth = 1.0
		player.healthCtl.stamina = 1.0
