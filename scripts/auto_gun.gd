extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var muzzleRay: RayCast3D = $"Gun/MuzzleRay"
@onready var casingPos: Node3D = $CasePos
@onready var magPos: Node3D = $"Gun/Magazine"
@onready var magInsertPos: Node3D = $"Gun/MagazineInsert"

@onready var laserRay: RayCast3D = $"Gun/LaserRay"
@onready var laserPoint: Decal = $LaserPoint

var ammo_label: Label

var recoil: float = 0.0
var hrecoil: float = 0.0

@export var laser := false
var holster := true

var muzzleflash = preload("res://scenes/muzzleflash.tscn")
var casing = preload("res://scenes/9mm_casing.tscn")

const sfx_dryfire := preload("res://assets/audio/sfx/weapons/gun/dry_fire.wav")
const sfx_shoot := [
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_2.wav"),
	preload("res://assets/audio/sfx/weapons/gun/gun_fire_3.wav")
]

const sfx_holster := [
	preload("res://assets/audio/sfx/player/holster1.wav"),
	preload("res://assets/audio/sfx/player/holster2.wav"),
	preload("res://assets/audio/sfx/player/holster3.wav"),
	preload("res://assets/audio/sfx/player/holster4.wav")
]
const sfx_unholster := [
	preload("res://assets/audio/sfx/player/unholster1.wav"),
	preload("res://assets/audio/sfx/player/unholster2.wav"),
	preload("res://assets/audio/sfx/player/unholster3.wav"),
	preload("res://assets/audio/sfx/player/unholster4.wav")
]

const sfx_slideback := [
	preload("res://assets/audio/sfx/weapons/gun/slide_back_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/slide_back_2.wav")
]
const sfx_slideforward := [
	preload("res://assets/audio/sfx/weapons/gun/slide_release_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/slide_release_2.wav"),
	preload("res://assets/audio/sfx/weapons/gun/slide_release_3.wav")
]
const sfx_slidehit := preload("res://assets/audio/sfx/weapons/gun/slide_lock_hit.wav")

const sfx_mag_out := [
	preload("res://assets/audio/sfx/weapons/gun/mag_out_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/mag_out_2.wav")
]
const sfx_mag_in := [
	preload("res://assets/audio/sfx/weapons/gun/mag_in_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/mag_in_2.wav")
]
const sfx_mag_insert := [
	preload("res://assets/audio/sfx/weapons/gun/insert_mag_1.wav"),
	preload("res://assets/audio/sfx/weapons/gun/insert_mag_2.wav"),
	preload("res://assets/audio/sfx/weapons/gun/insert_mag_3.wav")
]

var bullet = preload("res://scenes/bullet.tscn")

var magazine: RigidBody3D = preload("res://scenes/magazine.tscn").instantiate()
var chamber: bool = false
var hammer: bool = false
var slidelock: bool = false

var laserMesh = MeshInstance3D.new()

func _ready() -> void:
	get_tree().current_scene.call_deferred("add_child", laserMesh)
	get_tree().current_scene.call_deferred("add_child", magazine)
	magazine.gravity_scale = 0.0
	magazine.position = magPos.position
	magazine.inserted = true
	ammo_label = Global.playerGUI.get_node("AmmoLabel")
	get_parent().call_deferred("remove_child", self)
	Global.player.call_deferred("add_child", self)

var first_input: String = ""
var magAction: String = "none"
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("holster") and Global.player.is_input_enabled():
		holster = !holster
		play_random_sfx(sfx_holster if holster else sfx_unholster)
	if holster:
		global_transform = lerp(global_transform, Global.player.holster_position.global_transform, 0.2)
	else:
		if Input.is_action_pressed("rmb") and Global.player.is_input_enabled():
			if Input.is_action_pressed("pullslide"):
				var target = Global.player.grab_position.global_transform
				var targetEuler = target.basis.get_euler() + Vector3(0, 0, 0.4)
				target.basis = Basis.from_euler(targetEuler)
				global_transform = lerp(global_transform, target, 0.2)
			else:
				global_transform = lerp(global_transform, Global.player.grab_position.global_transform, 0.2)
		else:
			global_transform = lerp(global_transform, Global.player.right_hand_position.global_transform, 0.2)
	if magazine:
		if magAction == "none":
			magazine.global_transform = magPos.global_transform
		elif magAction == "eject" or magAction == "inserting":
			magazine.global_transform = lerp(magazine.global_transform, magInsertPos.global_transform, 0.3)
		elif magAction == "insert":
			magazine.global_transform = lerp(magazine.global_transform, magPos.global_transform, 0.3)
	scale = Vector3(3, 3, 3)
	rotation.z += recoil
	rotation.y += hrecoil

	recoil = lerp(recoil, 0.0, 0.5)
	hrecoil = lerp(hrecoil, 0.0, 0.5)

	if laser:
		laserRay.enabled = true
		laserPoint.visible = true
		if laserRay.is_colliding():
			var ray = laserRay
			laserPoint.global_position = ray.get_collision_point()
			laserPoint.rotation = ray.get_collision_normal()
		var mesh = ImmediateMesh.new()
		var mat = StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color("00ff00ff")
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		mesh.surface_add_vertex(laserRay.global_position)
		if laserRay.is_colliding():
			mesh.surface_add_vertex(laserRay.get_collision_point())
		else:
			mesh.surface_add_vertex(to_global(laserRay.position + laserRay.target_position))

		mesh.surface_end()
		mesh.surface_set_material(0, mat)
		laserMesh.mesh = mesh
	else:
		laserRay.enabled = false
		laserPoint.visible = false

	if not holster:
		if Input.is_action_pressed("lmb") and Global.player.is_input_enabled():
			if not slidelock:
				if hammer:
					if chamber:
						playsound(sfx_dryfire)
						play_random_sfx(sfx_slideback)
						anim.play("shoot")
						chamber = false
						playsound(sfx_shoot[randi_range(0, sfx_shoot.size() - 1)], 18)
						if "ear-pro" in Global.player.equipment:
							Global.player.damage_ears(0.00005)
						else:
							Global.player.damage_ears(0.01)
							Global.playerGUI.show_hint("Shooting firearms without hearing protection can cause permanent hearing loss.")

						var Flash = muzzleflash.instantiate()
						get_tree().current_scene.add_child(Flash)
						Flash.global_position = muzzleRay.global_position

						spawn_casing()

						Global.player.viewpunch_velocity += Vector3(300, 0, 0)
						recoil += randf_range(0.18, 0.22)
						hrecoil += randf_range(-0.1, 0.1)
						
						Global.intensity += 0.1

						Global.player.look_rotation += Vector2(
							randf_range(-0.1, 0.1), 
							randf_range(0.1, 0.2)
						)
						Global.player.viewpunch_rotation += Vector3(
							randf_range(-1.0, 1.0), 
							randf_range(-1.0, 1.0),
							randf_range(-1.0, 1.0)
						) * 5

						shoot_bullet()
						
						if magazine:
							if magazine.ammo > 0:
								if not Global.infinite_ammo:
									magazine.ammo -= 1
								chamber = true
							else:
								anim.play("slidelock")
								playsound(sfx_slidehit)
								slidelock = true
					else:
						if hammer:
							playsound(sfx_dryfire)
							hammer = false
							hrecoil += randf_range(-0.01, 0.01)
							recoil += randf_range(-0.01, 0.01)
		if not holster:
			if Input.is_action_just_pressed("pullslide") and Global.player.is_input_enabled(): 
				if not Input.is_action_pressed("slidelock"):
					first_input = "pullslide"
					recoil += 0.1
					play_random_sfx(sfx_slideback)
					if slidelock:
						anim.play("slidebacklock")
						return
					anim.play("slideback")
					hammer = true
					if chamber:
						spawn_casing()
						chamber = false
			if Input.is_action_just_released("pullslide") and Global.player.is_input_enabled():
				recoil -= 0.2
				if magazine:
					if magazine.ammo <= 0:
						anim.play("slidelock")
						playsound(sfx_slidehit)
						slidelock = true
						return
				if Input.is_action_pressed("slidelock") and first_input == "pullslide":
					anim.play("slidelock")
					playsound(sfx_slidehit)
					slidelock = true
				else:
					anim.play("slideforward")
					recoil -= 0.2
					play_random_sfx(sfx_slideforward)
					if not first_input == "slidelock":
						if magazine:
							if magazine.ammo > 0:
								magazine.ammo -= 1
								chamber = true
			if Input.is_action_just_pressed("slidelock") and Global.player.is_input_enabled():
				if slidelock:
					anim.play("sliderelease")
					recoil -= 0.1
					play_random_sfx(sfx_slideforward)
					slidelock = false
					if magazine:
						if magazine.ammo > 0:
							magazine.ammo -= 1
							chamber = true
			if Input.is_action_just_released("slidelock") and Global.player.is_input_enabled():
				if Input.is_action_pressed("pullslide"):
					anim.play("inspect_to_pull")
					play_random_sfx(sfx_slideback)
					hammer = true
					if chamber:
						spawn_casing()
						chamber = false
					if magazine:
						if magazine.ammo > 0:
							magazine.ammo -= 1
							chamber = true
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
						if Global.player.left_hand.name.begins_with("Magazine"):
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
					
		$"Gun/Round".visible = chamber

		if magazine:
			if magazine.ammo == magazine.maximum and chamber:
				ammo_label.text = str(magazine.ammo) + "+1"
			else:
				ammo_label.text = str(magazine.ammo + 1 if chamber else magazine.ammo)
		else:
			ammo_label.text = "X"

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

func spawn_casing():
	var case: RigidBody3D = casing.instantiate()
	get_tree().current_scene.add_child(case)
	case.global_transform = casingPos.global_transform
	case.scale = Vector3(2, 2, 2)
	case.linear_velocity = Vector3(
		randf_range(-0.5, 2.0),
		randf_range(4.0, 8.0),
		randf_range(-1.0, 1.0)
	)
