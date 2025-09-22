extends StaticBody3D

@onready var turret = get_parent()

const sfx_hit_laser := [
	preload("res://assets/audio/sfx/weapons/turret/turret_hit_camera_1.wav"),
	preload("res://assets/audio/sfx/weapons/turret/turret_hit_camera_2.wav")
]

const sfx_hit_ammo := [
	preload("res://assets/audio/sfx/weapons/turret/turret_hit_ammo_1.wav"),
	preload("res://assets/audio/sfx/weapons/turret/turret_hit_ammo_2.wav")
]

func hit(_bullet):
	if name == "AmmoBox":
		turret.parts["ammo"] = false
		turret.ammo = 0
		play_random_sfx(sfx_hit_ammo, 12)
	if name == "Laser":
		turret.parts["laser"] = false
		play_random_sfx(sfx_hit_laser, 12)

func play_random_sfx(sound_list, volume: float=0):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], volume)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer3D.new()
	ap.max_db = volume
	get_tree().current_scene.add_child(ap)
	ap.global_transform = global_transform
	ap.stream = stream
	ap.bus = "SFX"
	ap.play()
	await ap.finished
	ap.queue_free()
