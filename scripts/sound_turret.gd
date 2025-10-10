extends StaticBody3D

@export var fire_rate: float = 0.33

@onready var Ray = $Ray

var activated: bool = false
var shot: bool = false

const sfx_charge := preload("res://assets/audio/sfx/weapons/soundturret/sound_turret_charge.wav")
const sfx_hit := preload("res://assets/audio/sfx/weapons/soundturret/sound_turret_hit.wav")
const sfx_blocked := preload("res://assets/audio/sfx/weapons/soundturret/sound_turret_blocked.wav")

func _process(delta: float) -> void:
	if not Global.is_initialized:
		return
	var target = Global.player.get_node("Head").global_transform.origin
	var target_basis: Basis
	target_basis = Transform3D().looking_at(target - global_transform.origin).basis

	Ray.global_transform.basis = target_basis
	$BarrelPivot.global_transform.basis = $BarrelPivot.global_transform.basis.slerp(target_basis, 2.0 * delta)

	if not shot:
		if Ray.is_colliding():
			var collider = Ray.get_collider()
			if collider:
				if collider.name == "PlayerShootRad" and not Global.player.dead:
					if activated:
						shoot()
						shot = true
						activated = false	
					else:
						activated = true

func shoot():
	playsound(sfx_charge)
	await get_tree().create_timer(sfx_charge.get_length()).timeout
	if Ray.is_colliding():
		var collider = Ray.get_collider()
		if collider and not Global.godmode:
			if collider.name == "PlayerShootRad" and not Global.player.dead:
				playsound(sfx_hit, 100)
				await get_tree().create_timer(0.05).timeout
				if "ear-pro" in Global.player.equipment:
					Global.player.viewpunch_velocity += Vector3(100.0, 0, 0)
					Global.player.healthCtl.consciousness -= 0.2
					Global.player.healthCtl.Limbs["Head"].pain = 0.1
					Global.player.healthCtl.Limbs["Head"].muscleHealth -= 0.1
					Global.player.damage_ears(0.05)
				else:
					Global.player.viewpunch_velocity += Vector3(260.0, 0, 0)
					Global.player.healthCtl.consciousness -= 0.85
					Global.player.healthCtl.Limbs["Head"].pain = 1.0
					Global.player.healthCtl.Limbs["Head"].muscleHealth -= 0.33
					Global.player.healthCtl.brainHealth -= 0.40
					Global.player.damage_ears(1)
			else:
				blocked()
		else:
			blocked()

func blocked():
	playsound(sfx_blocked, 60)
	if Global.godmode:
		return
	Global.player.healthCtl.consciousness -= 0.1
	Global.player.viewpunch_velocity += Vector3(60.0, 0, 0)
	Global.player.damage_ears(0.01)

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
