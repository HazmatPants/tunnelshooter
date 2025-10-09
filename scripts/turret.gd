extends StaticBody3D

@export var fire_rate: float = 0.2

@onready var muzzleRay = $MuzzleRay
@onready var laserRay = $Laser/LaserRay
@onready var laserMesh = $LaserBeam
@onready var casingPos = $casingPos

var parts := {
	"laser": true,
	"ammo": true
}

const muzzleflash = preload("res://scenes/muzzleflash.tscn")
const casing = preload("res://scenes/9mm_casing.tscn")
const bullet = preload("res://scenes/bullet.tscn")

var shoot_cooldown: float = 1.0
var aggro_timer: float = 0.0
var state: String = "idle"
var ammo: int = 60
var chamber: bool = false
var aggro_time: float = 2.0

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
const sfx_chamber := preload("res://assets/audio/sfx/weapons/turret/turret_chamber.wav")

var ap_alarm := AudioStreamPlayer3D.new()

func _ready() -> void:
	ap_alarm.bus = "SFX"
	ap_alarm.stream = preload("res://assets/audio/sfx/weapons/turret/alarm.wav")
	ap_alarm.volume_db = -10
	get_tree().current_scene.call_deferred("add_child", ap_alarm)
	ap_alarm.global_position = global_position

var last_spotted_rot: Vector3 = Vector3.ZERO
func _process(delta: float) -> void:
	if not Global.is_initialized:
		return
	var target = Global.player.get_node("Head").global_transform.origin + Global.player.velocity / 3
	var target_basis: Basis
	if state == "shoot":
		if aggro_timer > aggro_time - 1.0:
			target_basis = Transform3D().looking_at(target - global_transform.origin).basis
		else:
			target_basis = Basis.from_euler(last_spotted_rot)
		if aggro_timer <= 0:
			state = "idle"
			playsound(sfx_deactivate)
	if state == "idle":
		target_basis = Basis.from_euler(Vector3(0, rotation.y + 0.3, 0))

	global_transform.basis = global_transform.basis.slerp(target_basis, 3.0 * delta)

	if muzzleRay.is_colliding():
		var collider = muzzleRay.get_collider()
		if collider:
			if collider.name == "PlayerShootRad" and not Global.player.dead and parts["laser"]:
				last_spotted_rot = rotation
				if not chamber:
					if ammo > 0:
						playsound(sfx_chamber, 10)
						ammo -= 1
						chamber = true
				if not ap_alarm.playing:
					ap_alarm.playing = true
					playsound(sfx_activate)
					play_random_sfx(sfx_alert)
				aggro_timer = aggro_time
				if state == "shoot":
					if shoot_cooldown >= fire_rate:
						if chamber:
							play_random_sfx(sfx_fire, 40)
							shoot_bullet()
							shoot_cooldown = 0.0
							chamber = false
							#var max_range = 500.0
							#var dist = global_position.distance_to(Global.player.global_position)
							#var t = clamp(1.0 - (dist / max_range), 0.0, 1.0)
							#Global.player.damage_ears(t / 100)
							if ammo > 0:
								chamber = true
								ammo -= 1
						else:
							playsound(sfx_dryfire)
							shoot_cooldown = 0.0
					if aggro_timer < aggro_time:
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
	elif state == "shoot":
		ap_alarm.playing = false
		shoot_cooldown = -0.5
		aggro_timer -= delta

	shoot_cooldown += delta

	if parts["laser"]:
		var mesh = ImmediateMesh.new()
		var mat = StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color("00ff00ff")
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		mesh.surface_add_vertex(laserRay.position)
		if laserRay.is_colliding():
			mesh.surface_add_vertex(to_local(laserRay.get_collision_point()))
		else:
			mesh.surface_add_vertex(laserRay.position + laserRay.target_position)

		mesh.surface_end()
		mesh.surface_set_material(0, mat)
		laserMesh.mesh = mesh
	else:
		laserMesh.visible = false

func shoot_bullet():
	var b = bullet.instantiate()

	get_tree().current_scene.call_deferred("add_child", b)
	b.global_transform = muzzleRay.global_transform
	b.rotation_degrees.y += 90
	b.shooter = self

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
