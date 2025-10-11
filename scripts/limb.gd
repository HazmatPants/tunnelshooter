extends Node3D

@export var isHead: bool = false
@export var isArm: bool = false
@export var isLeg: bool = false
@export var bleedingRateMult: float = 1.0
@export var muscleHealMult: float = 1.0
var dislocated: bool = false

const sfx_flesh_hit := [
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_1.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_2.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_3.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_4.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_5.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_6.wav")
]

var bleedingRate: float = 0.0
var pain: float = 0.0
var muscleHealth: float = 1.0
var skinHealth: float = 1.0

func _process(delta: float) -> void:
	if not Global.is_initialized:
		return
	bleedingRate -= Global.player.healthCtl.bloodClotSpeed * delta
	bleedingRate = clampf(bleedingRate, 0.0, INF)
	var pain_sub = ((0.01 * (1.0 - Global.player.healthCtl.adrenaline)) * 
		1.0 + (Global.player.healthCtl.opioidAmount +
		Global.player.healthCtl.stimAmount * 10) / 10)

	pain += (1.0 - muscleHealth) / 1000 * delta
	pain -= clampf(pain_sub, 0.0, INF) * delta

	muscleHealMult = lerp(muscleHealMult, 1.0, 0.005)

	pain = clampf(pain, 0.0, 1.0)
	if muscleHealth > 0.2:
		muscleHealth += (0.0005 * muscleHealMult) * delta
	else:
		muscleHealth += (0.0001 * muscleHealMult) * delta
	if skinHealth > 0.2:
		skinHealth += 0.0005 * delta
	else:
		skinHealth += 0.0001 * delta

	muscleHealth = clampf(muscleHealth, 0.0, 1.0)
	skinHealth = clampf(skinHealth, 0.0, 1.0)

func hit(_bullet):
	if Global.godmode:
		return
	if isHead:
		Global.player.healthCtl.brainHealth = 0
		play_random_sfx(sfx_flesh_hit, 40)

	bleedingRate += randf_range(1.0, 3.0) * bleedingRateMult
	pain += randf_range(0.075, 0.2) * (1.0 - Global.player.healthCtl.adrenaline)
	Global.player.healthCtl.adrenaline += 0.05
	muscleHealth -= randf_range(0.1, 0.3)
	skinHealth -= randf_range(0.005, 0.05)
	play_random_sfx(sfx_flesh_hit, 10)
	Global.player.viewpunch_velocity += Vector3(200.0, 0, 0)

func play_random_sfx(sound_list, volume: float=0):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], volume)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.bus = "SFX"
	ap.play()
	await ap.finished
	ap.queue_free()
