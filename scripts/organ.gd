extends StaticBody3D

@export var isHeart: bool = false
@export var isLung: bool = false

const sfx_flesh_hit := [
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_1.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_2.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_3.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_4.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_5.wav"),
	preload("res://assets/audio/sfx/physics/flesh/flesh_hit_6.wav")
]

func hit(_bullet):
	if isHeart:
		Global.player.healthCtl.heartRate = 0
		Global.player.healthCtl.organs["Heart"] = false
		Global.player.healthCtl.add_affliction("cardiacArrest", 100)
		Global.player.healthCtl.add_affliction("heartPierced", 100)
	if isLung:
		Global.player.healthCtl.organs[name] = false
		if name == "LLung":
			if Global.player.healthCtl.organs["RLung"]:
				Global.player.healthCtl.bloodOxygen /= 2
				Global.player.healthCtl.add_affliction("lungCollapsed", 1)
			else:
				Global.player.healthCtl.add_affliction("respiratoryFailure", 1)
		if name == "RLung":
			if Global.player.healthCtl.organs["LLung"]:
				Global.player.healthCtl.bloodOxygen /= 2
				Global.player.healthCtl.add_affliction("lungCollapsed", 1)
			else:
				Global.player.healthCtl.add_affliction("respiratoryFailure", 1)

	Global.player.healthCtl.Limbs["Thorax"].bleedingRate += randf_range(5.0, 10.0)
	Global.player.healthCtl.Limbs["Thorax"].pain += randf_range(0.1, 0.4)
	Global.player.healthCtl.Limbs["Thorax"].muscleHealth -= randf_range(0.01, 0.1)
	Global.player.healthCtl.Limbs["Thorax"].skinHealth -= randf_range(0.01, 0.3)
	play_random_sfx(sfx_flesh_hit, 24)
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
