extends Node3D

@export var fire_rate: float = 0.33

@onready var muzzleRay = $MuzzleRay
@onready var casingPos = $casingPos

const muzzleflash = preload("res://scenes/muzzleflash.tscn")
const casing = preload("res://scenes/9mm_casing.tscn")
const bullet = preload("res://scenes/bullet.tscn")

var shoot_cooldown: float = 1.0
var aggro_timer: float = 0.0
var state: String = "idle"
var ammo: int = 30

const sfx_fire := [
	preload("res://assets/audio/sfx/weapons/turret/fire1.wav"),
	preload("res://assets/audio/sfx/weapons/turret/fire2.wav"),
	preload("res://assets/audio/sfx/weapons/turret/fire3.wav"),
	preload("res://assets/audio/sfx/weapons/turret/fire4.wav")
]

const sfx_alert := [
	preload("res://assets/audio/sfx/weapons/turret/alert1.wav"),
	preload("res://assets/audio/sfx/weapons/turret/alert2.wav"),
	preload("res://assets/audio/sfx/weapons/turret/alert3.wav")
]

const sfx_scan := preload("res://assets/audio/sfx/weapons/turret/ping.wav")
const sfx_activate := preload("res://assets/audio/sfx/weapons/turret/activate.wav")
const sfx_deactivate := preload("res://assets/audio/sfx/weapons/turret/deactivate.wav")
const sfx_dryfire := preload("res://assets/audio/sfx/weapons/turret/dryfire.wav")

var ap_alarm := AudioStreamPlayer3D.new()

func _ready() -> void:
	ap_alarm.bus = "SFX"
	ap_alarm.stream = preload("res://assets/audio/sfx/weapons/turret/alarm.wav")
	ap_alarm.volume_db = -20
	get_tree().current_scene.call_deferred("add_child", ap_alarm)

var search_turn: float = 0.15
func _process(delta: float) -> void:
	var target = Global.player.get_node("Head").global_transform.origin + Global.player.velocity / 2
	var target_basis: Basis
	if state == "shoot":
		if aggro_timer > 3.5:
			target_basis = Transform3D().looking_at(target - global_transform.origin).basis
		else:
			target_basis = Basis.from_euler(Vector3(rotation.x, rotation.y + search_turn, rotation.z))
		if aggro_timer <= 0:
			state = "idle"
			playsound(sfx_deactivate)
	if state == "idle":
		target_basis = Basis.from_euler(Vector3(0, rotation.y + 0.3, 0))

	global_transform.basis = global_transform.basis.slerp(target_basis, 3.0 * delta)

	if muzzleRay.is_colliding():
		var collider = muzzleRay.get_collider()
		if collider:
			if collider.name == "PlayerShootRad" and not Global.player.dead:
				if not ap_alarm.playing:
					ap_alarm.playing = true
					playsound(sfx_activate)
					play_random_sfx(sfx_alert)
				aggro_timer = 4
				if state == "shoot":
					if shoot_cooldown >= fire_rate:
						if ammo >= 0:
							play_random_sfx(sfx_fire)
							shoot_bullet()
							shoot_cooldown = 0.0
							ammo -= 1
						else:
							playsound(sfx_dryfire)
							shoot_cooldown = 0.0
					if aggro_timer < 4:
						shoot_cooldown = -0.5
						playsound(sfx_activate)
						ap_alarm.play()
				elif state == "idle":
					state = "shoot"
					shoot_cooldown = -0.5
					play_random_sfx(sfx_alert)
					ap_alarm.play()
			elif state == "shoot":
				ap_alarm.playing = false
				shoot_cooldown = -0.5
				aggro_timer -= delta
				if abs(fmod(aggro_timer, 1.0)) < 0.000001:
					playsound(sfx_scan)
					search_turn = -search_turn

	shoot_cooldown += delta

func shoot_bullet():
	var b = bullet.instantiate()

	get_tree().current_scene.call_deferred("add_child", b)
	b.global_transform = muzzleRay.global_transform
	b.rotation_degrees.y += 90

	var f = muzzleflash.instantiate()
	get_tree().current_scene.add_child(f)
	f.global_position = muzzleRay.global_position

	var case: RigidBody3D = casing.instantiate()
	get_tree().current_scene.add_child(case)
	case.global_transform = casingPos.global_transform
	case.scale = Vector3(2, 2, 2)
	case.linear_velocity = Vector3(
		randf_range(-0.5, 2.0),
		randf_range(4.0, 8.0),
		randf_range(-1.0, 1.0)
	)

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
