extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var muzzleRay: RayCast3D = $MuzzleRay
@onready var casingPos: Node3D = $CasePos
@onready var magPos: Node3D = $Magazine
@onready var magInsertPos: Node3D = $MagazineInsert


var ammo_label: Label

var recoil: float = 0.0
var hrecoil: float = 0.0

var muzzleflash = preload("res://scenes/muzzleflash.tscn")
var casing = preload("res://scenes/9mm_casing.tscn")

const sfx_shoot := [
	preload("res://assets/audio/sfx/weapons/explosive/plastic_explosive_1.wav"),
	preload("res://assets/audio/sfx/weapons/explosive/plastic_explosive_2.wav"),
	preload("res://assets/audio/sfx/weapons/explosive/plastic_explosive_3.wav"),
	preload("res://assets/audio/sfx/weapons/explosive/plastic_explosive_4.wav"),
	preload("res://assets/audio/sfx/weapons/explosive/plastic_explosive_5.wav")
]

const sfx_shoot2 := [
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_2.wav"),
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_3.wav")
]

const sfx_shoot2_sup := [
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_suppressed_1.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_suppressed_2.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_suppressed_3.ogg")
]

const sfx_prefire := [
	preload("res://assets/audio/sfx/weapons/gun/uzi/prefire1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/prefire2.wav"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/prefire3.wav"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/prefire4.wav")

]

#const sfx_holster := [
	#preload("res://assets/audio/sfx/player/holster1.wav"),
	#preload("res://assets/audio/sfx/player/holster2.wav"),
	#preload("res://assets/audio/sfx/player/holster3.wav"),
	#preload("res://assets/audio/sfx/player/holster4.wav")
#]
#const sfx_unholster := [
	#preload("res://assets/audio/sfx/player/unholster1.wav"),
	#preload("res://assets/audio/sfx/player/unholster2.wav"),
	#preload("res://assets/audio/sfx/player/unholster3.wav"),
	#preload("res://assets/audio/sfx/player/unholster4.wav")
#]

const sfx_slideback := [
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltback1.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltback2.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltback3.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltback4.ogg")
]
const sfx_slideforward := [
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltforward1.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltforward2.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltforward3.ogg"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/boltforward4.ogg")
]
const sfx_slidehit := preload("res://assets/audio/sfx/weapons/gun/slide_lock_hit.wav")

const sfx_mag_out := [
	preload("res://assets/audio/sfx/weapons/gun/uzi/magout1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/magout2.wav")
]
const sfx_mag_in := [
	preload("res://assets/audio/sfx/weapons/gun/uzi/magin1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/uzi/magin2.wav")
]
const sfx_mag_insert := [
	preload("res://assets/audio/sfx/weapons/gun/insert_mag_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/insert_mag_2.wav"),
	preload("res://assets/audio/sfx/weapons/gun/insert_mag_3.wav")
]

var bullet = preload("res://scenes/bullet.tscn")

var magazine: RigidBody3D = preload("res://scenes/uzi_mag.tscn").instantiate()
var chamber: bool = false
var hammer: bool = false
var bolt: bool = false
var firemode: String = "auto"

var crosshair

var rot_offset := Vector3.ZERO
func _unhandled_input(event):
	if not Global.is_initialized:
		return
	if Input.is_key_pressed(KEY_K):
		Global.player.mouse_look_enabled = false
		if event is InputEventMouseMotion:
			rot_offset.y -= event.relative.x * 0.01
			rot_offset.z -= event.relative.y * 0.01
			if muzzleRay.is_colliding():
				if muzzleRay.get_collider().owner.name == "Player":
					shakiness += 0.005
					Global.player.healthCtl.adrenaline += 0.005
	else:
		Global.player.mouse_look_enabled = true
		rot_offset = Vector3.ZERO

func _ready() -> void:
	get_tree().current_scene.call_deferred("add_child", magazine)
	magazine.gravity_scale = 0.0
	magazine.position = magPos.position
	magazine.maximum = 30
	magazine.ammo = 30
	magazine.inserted = true
	await Global.initialized
	ammo_label = Global.playerGUI.get_node("AmmoLabel")

	crosshair = Global.playerGUI.get_node("Crosshair")

var shakiness: float = 0.0

var shootFrames: int = 8
var shootTimer: int = 0
var triggerPulled: bool = false
var fired: bool = false

var first_input: String = ""
var magAction: String = "none"
func _process(_delta: float) -> void:
	if not Global.is_initialized:
		return
	if Global.player.inventory.items["RHand"] != owner or Global.player.inspecting:
		if magazine:
			magazine.get_node("CollisionShape3D").disabled = true
			magazine.global_transform = magPos.global_transform
		return
	shakiness = lerp(shakiness, 1.0, 0.00001)
	if Input.is_action_pressed("rmb") and Global.player.is_input_enabled():
		crosshair.modulate.a = lerp(crosshair.modulate.a, 0.0, 0.1)
		var target_t: Transform3D = Global.player.grab_position.global_transform
		target_t.origin += Vector3(0, 0.04, 0)
		target_t.basis = Basis.from_euler(target_t.basis.get_euler() + rot_offset)
		if Input.is_action_pressed("pullslide"):
			var target = Global.player.grab_position.global_transform
			var targetEuler = target.basis.get_euler() + Vector3(0, 0, 0.4)
			target.basis = Basis.from_euler(targetEuler)
			global_transform = lerp(global_transform, target, 0.2 * Global.player.healthCtl.consciousness)
		else:
			global_transform = lerp(global_transform, target_t, 0.2 * Global.player.healthCtl.consciousness)
	else:
		Global.player.camera.base_fov = lerp(Global.player.camera.base_fov, 85.0, 0.1)
		var target_t: Transform3D = Global.player.right_hand_position.global_transform
		target_t.basis = Basis.from_euler(target_t.basis.get_euler() + rot_offset)
		shakiness = lerp(shakiness, max(0.0, Global.player.healthCtl.get_limb_total("pain") / 16), 0.01)
		crosshair.modulate.a = lerp(crosshair.modulate.a, 1.0, 0.1)
		global_transform = lerp(global_transform, target_t, 0.2 * Global.player.healthCtl.consciousness)
	if magazine:
		magazine.get_node("CollisionShape3D").disabled = true
		if magAction == "none":
			magazine.global_transform = magPos.global_transform
		elif magAction == "eject" or magAction == "inserting":
			magazine.global_transform = lerp(magazine.global_transform, magInsertPos.global_transform, 0.3)
		elif magAction == "insert":
			magazine.global_transform = lerp(magazine.global_transform, magPos.global_transform, 0.3)

	if not Global.hand_shake_enabled:
		shakiness = 0.0

	rotation.z += recoil
	rotation.y += hrecoil

	rotation.y = lerp(rotation.y, rotation.y + randf_range(-shakiness, shakiness), 0.1)
	rotation.z = lerp(rotation.z, rotation.z + randf_range(-shakiness, shakiness), 0.1)
	position.x = lerp(position.x, position.x + randf_range(-shakiness, shakiness), 0.01)
	position.y = lerp(position.y, position.y + randf_range(-shakiness, shakiness), 0.01)
	position.z = lerp(position.z, position.z + randf_range(-shakiness, shakiness), 0.01)

	recoil = lerp(recoil, 0.0, 0.5 * Global.player.healthCtl.consciousness)
	hrecoil = lerp(hrecoil, 0.0, 0.5 * Global.player.healthCtl.consciousness)

	scale = Vector3(0.3, 0.3, 0.3)

	if Input.is_action_pressed("lmb") and Global.player.is_input_enabled() and not fired:
		if hammer:
			if bolt:
				if shootTimer < 1:
					triggerPulled = true
					play_random_sfx(sfx_prefire)
					if magazine:
						if magazine.ammo > 0:
							magazine.ammo -= 1
							chamber = true
	if triggerPulled:
		anim.play("shoot")
		if shootTimer < shootFrames:
			shootTimer += 1
			return
		triggerPulled = false
		shootTimer = 0
		shakiness += 0.001
		bolt = false
		if not chamber:
			return
		chamber = false
		if Global.quiet_guns:
			play_random_sfx(sfx_shoot2, -6)
		else:
			play_random_sfx(sfx_shoot2, 16)
			play_random_sfx(sfx_shoot, 10)
		if not "ear-pro" in Global.player.equipment:
			Global.player.damage_ears(0.01)
			Global.playerGUI.show_hint("Shooting firearms without hearing protection can cause permanent hearing loss.")
		var Flash = muzzleflash.instantiate()
		Flash.light_energy = 30
		get_tree().current_scene.add_child(Flash)
		Flash.global_position = muzzleRay.global_position

		spawn_casing()

		bolt = true
		anim.play("bolt_open")
		if firemode == "semi":
			fired = true

		if not Global.no_recoil:
			Global.player.viewpunch_velocity += Vector3(80, 0, 0)
			recoil += randf_range(0.001, 0.05)
			hrecoil += randf_range(-0.005, 0.005)

			Global.player.viewpunch_rotation += Vector3(
				randf_range(-1.0, 1.0), 
				randf_range(-1.0, 1.0),
				randf_range(-1.0, 1.0)
			) * 5

		shoot_bullet()

	if Input.is_action_just_released("lmb"):
		shootTimer = 0
		fired = false
	if Input.is_action_just_pressed("pullslide") and Global.player.is_input_enabled(): 
		if not Input.is_action_pressed("slidelock"):
			first_input = "pullslide"
			recoil += 0.1
			play_random_sfx(sfx_slideback)
			anim.play("bolt")
			bolt = true
			hammer = true
	if Input.is_action_just_released("pullslide") and Global.player.is_input_enabled():
		anim.play("bolt_release")
		recoil -= 0.2
		play_random_sfx(sfx_slideforward)
	if Input.is_action_just_released("slidelock") and Global.player.is_input_enabled():
		if Input.is_action_pressed("pullslide"):
			anim.play("inspect_to_pull")
			play_random_sfx(sfx_slideback)
			hammer = true
	if Input.is_action_just_pressed("eject_mag") and Global.player.is_input_enabled():
		if magazine and magAction == "none":
			play_random_sfx(sfx_mag_out)
			magAction = "eject"
			recoil += 0.05
			await get_tree().create_timer(0.2).timeout
			magAction = "none"
			magazine.inserted = false
			Global.player.left_hand = magazine
			magazine = null
	if Input.is_action_just_pressed("insert_mag") and Global.player.is_input_enabled():
		if not magazine:
			if Global.player.left_hand != null:
				if "Magazine" in Global.player.left_hand.name:
					magazine = Global.player.left_hand
					Global.player.left_hand = null
					magAction = "inserting"
					await get_tree().create_timer(0.2).timeout
					magAction = "insert"
					play_random_sfx(sfx_mag_in)
					await get_tree().create_timer(0.12).timeout
					play_random_sfx(sfx_mag_insert)
					magazine.inserted = true
					magazine.gravity_scale = 0.0
					recoil -= 0.05
					magAction = "none"
	if Input.is_action_pressed("slidelock") and not first_input == "pullslide":
		if Input.is_action_just_pressed("pullslide"):
			play_random_sfx(sfx_slideback)
			anim.play("inspect")
			recoil -= 0.1
			hammer = true
		else:
			first_input = "slidelock"
	if not Input.is_action_pressed("slidelock") and not Input.is_action_pressed("pullslide"):
		first_input = ""
	if Input.is_action_just_pressed("firemode") and Global.player.is_input_enabled():
		playsound(preload("res://assets/audio/sfx/weapons/gun/uzi/mode.wav"))
		if firemode == "auto":
			firemode = "semi"
		else:
			firemode = "auto"
		ammo_label.text = firemode.to_upper()

	$"Mesh/bolt/Round".visible = chamber

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

func shoot_bullet():
	var b = bullet.instantiate()
	
	get_tree().current_scene.call_deferred("add_child", b)
	b.global_transform = muzzleRay.global_transform
	b.shooter = Global.player

func spawn_casing():
	var case: RigidBody3D = casing.instantiate()
	get_tree().current_scene.add_child(case)
	case.global_transform = casingPos.global_transform
	case.scale = Vector3(2, 2, 2)
	var direction = casingPos.global_transform.basis.z
	case.linear_velocity = direction * 20.0
