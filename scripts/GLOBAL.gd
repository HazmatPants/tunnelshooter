extends Node

var settings: ConfigFile = null

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
	settings = load_settings()

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

func playsound(stream: AudioStream, volume: float=0, pitch=1.0, position=null):
	var ap
	if position == null:
		ap = AudioStreamPlayer.new()
	else:
		ap = AudioStreamPlayer3D.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	if position != null:
		ap.global_position = position
	ap.stream = stream
	ap.pitch_scale = pitch
	ap.play()
	await ap.finished
	ap.queue_free()

func play_random_sfx(sound_list, volume: float=0):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], volume)

func load_settings() -> ConfigFile:
	var cfg := ConfigFile.new()
	var err = cfg.load("user://settings.cfg")

	print("Load settings: " + error_string(err))

	if err != OK:
		var s = default_config()
		return s

	return cfg

func set_setting(section: String, key: String, value: Variant):
	settings.set_value(section, key, value)
	settings.save("user://settings.cfg")

func default_config() -> ConfigFile:
	var s = ConfigFile.new()
	s.set_value("Misc", "accepted_disclaimer", false)
	s.save("user://settings.cfg")
	return s
