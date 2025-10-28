extends Node

@export var infinite_ammo: bool = false
@export var console_enabled: bool = false
@export var quiet_guns: bool = false
@export var hand_shake_enabled: bool = true
@export var no_recoil: bool = false

var playerScene
var player
var playerGUI

var godmode: bool = false
var flashmode: bool = false

var bgm_pain: AudioStreamPlayer
var bgm_agony: AudioStreamPlayer

var cause_of_death: String = "unknown"

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

	bgm_agony = AudioStreamPlayer.new()
	bgm_agony.volume_linear = 0.0
	bgm_agony.stream = preload("res://assets/audio/music/agony.ogg")
	bgm_agony.autoplay = true
	get_tree().current_scene.add_child(bgm_agony)

	initialized.emit()
	is_initialized = true

func _process(_delta: float) -> void:
	if not is_initialized:
		return
	if not player:
		return
	bgm_pain.volume_linear = clampf(player.healthCtl.get_limb_all("pain").values().max() - 0.1, 0.0, 1.0)
	if player.healthCtl.consciousness <= player.healthCtl.unconsciousThreshold:
		bgm_pain.volume_linear = 0.0
		bgm_agony.volume_linear = 0.0
	if player.healthCtl.get_limb_all("pain").values().max() > 0.9:
		bgm_agony.volume_linear = lerp(bgm_agony.volume_linear, 1.0, 0.01)
	else:
		bgm_agony.volume_linear = lerp(bgm_agony.volume_linear, 0.0, 0.01)

	if godmode:
		player.healthCtl.consciousness = 1.0
		player.healthCtl.brainHealth = 1.0
		player.healthCtl.stamina = 1.0

	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.play()
	await ap.finished
	ap.queue_free()

func play_random_sfx(sound_list, volume: float=0):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], volume)
