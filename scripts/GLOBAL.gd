extends Node

@export var music_enabled: bool = false
@export var infinite_ammo: bool = true

@onready var playerScene = get_tree().get_current_scene()
@onready var player = get_tree().get_current_scene().get_node("Player")
@onready var playerGUI = get_tree().get_current_scene().get_node("PlayerGUI")

var intensity: float = 0.0

var bgm_drums: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	bgm_drums.stream = preload("res://assets/audio/music/FUNKDRUMS.wav")
	bgm_drums.volume_db = linear_to_db(0.0)
	bgm_drums.autoplay = true
	get_tree().current_scene.add_child(bgm_drums)

var last_intensity := -INF
var intensity_changed := false
var intensity_pause := 0.0
func _process(delta: float) -> void:
	if music_enabled:
		intensity_changed = intensity > last_intensity
		if intensity_changed:
			intensity_pause = 3.0

		if intensity > 0.5:
			bgm_drums.volume_db = linear_to_db(intensity - 0.5)
		if intensity_pause > 0:
			intensity_pause -= delta
		else:
			intensity_pause = 0
		
		if intensity_pause == 0:
			intensity = lerp(intensity, 0.0, 0.1 * delta)
		
		if intensity > 5:
			intensity = 5
		
		last_intensity = intensity
