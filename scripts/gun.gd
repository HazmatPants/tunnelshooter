extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var muzzleRay: RayCast3D = $"320/MuzzleRay"
@onready var casingPos: Node3D = $CasePos
@onready var magPos: Node3D = $"320/Magazine"
@onready var magInsertPos: Node3D = $"320/MagazineInsert"

@onready var laserRay: RayCast3D = $"320/LaserRay"
@onready var laserPoint: Decal = $LaserPoint

var ammo_label: Label

var recoil: float = 0.0
var hrecoil: float = 0.0

@export var laser := false
var holster := true

var muzzleflash = preload("res://scenes/muzzleflash.tscn")
var casing = preload("res://scenes/9mm_casing.tscn")

const sfx_dryfire := preload("res://assets/audio/sfx/gun/dry_fire.wav")
const sfx_shoot := [
	preload("res://assets/audio/sfx/gun/gun_fire_1.wav"),
	preload("res://assets/audio/sfx/gun/gun_fire_2.wav"),
	preload("res://assets/audio/sfx/gun/gun_fire_3.wav")
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
	preload("res://assets/audio/sfx/gun/slide_back_1.wav"),
	preload("res://assets/audio/sfx/gun/slide_back_2.wav")
]
const sfx_slideforward := [
	preload("res://assets/audio/sfx/gun/slide_release_1.wav"),
	preload("res://assets/audio/sfx/gun/slide_release_2.wav"),
	preload("res://assets/audio/sfx/gun/slide_release_3.wav")
]
const sfx_slidehit := preload("res://assets/audio/sfx/gun/slide_lock_hit.wav")

const sfx_mag_out := [
	preload("res://assets/audio/sfx/gun/mag_out_1.wav"),
	preload("res://assets/audio/sfx/gun/mag_out_2.wav")
]
const sfx_mag_in := [
	preload("res://assets/audio/sfx/gun/mag_in_1.wav"),
	preload("res://assets/audio/sfx/gun/mag_in_2.wav")
]
const sfx_mag_insert := [
	preload("res://assets/audio/sfx/gun/insert_mag_1.wav"),
	preload("res://assets/audio/sfx/gun/insert_mag_2.wav"),
	preload("res://assets/audio/sfx/gun/insert_mag_3.wav")
]

var magazine: RigidBody3D = preload("res://scenes/magazine.tscn").instantiate()
var chamber: bool = false
var hammer: bool = false
var slidelock: bool = false

func _ready() -> void:
	get_tree().current_scene.call_deferred("add_child", magazine)
	magazine.freeze = true
	magazine.position = magPos.position
	magazine.inserted = true
	ammo_label = Global.playerGUI.get_node("AmmoLabel")
	get_parent().call_deferred("remove_child", self)
	Global.player.call_deferred("add_child", self)

var first_input: String = ""
var magAction: String = "none"
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("holster"):
		holster = !holster
		play_random_sfx(sfx_holster if holster else sfx_unholster)
	if holster:
		global_transform = lerp(global_transform, Global.player.holster_position.global_transform, 0.2)
	else:
		if Input.is_action_pressed("rmb"):
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
	else:
		laserRay.enabled = false
		laserPoint.visible = false

	if not holster:
		if Input.is_action_just_pressed("lmb"):
			if not slidelock:
				if hammer:
					if chamber:
						playsound(sfx_dryfire)
						anim.play("shoot")
						chamber = false
						playsound(sfx_shoot[randi_range(0, sfx_shoot.size() - 1)], 16)
						if not "ear-pro" in Global.player.equipment:
							Global.player.damage_ears(0.002)

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
							randf_range(-0.1, 0.1)
						)
						Global.player.viewpunch_rotation += Vector3(
							randf_range(-1.0, 1.0), 
							randf_range(-1.0, 1.0),
							randf_range(-1.0, 1.0)
						) * 5

						shoot_bullet()
						
						if magazine:
							if magazine.ammo > 0:
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
							hrecoil += 0.01
							recoil += -0.01
		if not holster:
			if Input.is_action_just_pressed("pullslide"): 
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
			if Input.is_action_just_released("pullslide"):
				recoil -= 0.1
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
					play_random_sfx(sfx_slideforward)
					if not first_input == "slidelock":
						if magazine:
							if magazine.ammo > 0:
								magazine.ammo -= 1
								chamber = true
			if Input.is_action_just_pressed("slidelock"):
				if slidelock:
					anim.play("sliderelease")
					recoil -= 0.1
					play_random_sfx(sfx_slideforward)
					slidelock = false
					if magazine:
						if magazine.ammo > 0:
							magazine.ammo -= 1
							chamber = true
			if Input.is_action_just_released("slidelock"):
				if Input.is_action_pressed("pullslide"):
					anim.play("slideback")
					hammer = true
					if chamber:
						spawn_casing()
						chamber = false
					if magazine:
						if magazine.ammo > 0:
							magazine.ammo -= 1
							chamber = true
			if Input.is_action_just_pressed("eject_mag"):
				if magazine:
					play_random_sfx(sfx_mag_out)
					magAction = "eject"
					recoil += 0.05
					await get_tree().create_timer(0.2).timeout
					magAction = "none"
					magazine.inserted = false
					Global.player.left_hand = magazine
					magazine = null
			if Input.is_action_just_pressed("insert_mag"):
				if not magazine:
					if Global.player.left_hand != null:
						if Global.player.left_hand.name.begins_with("Magazine"):
							magazine = Global.player.left_hand
							Global.player.left_hand = null
							magAction = "inserting"
							await get_tree().create_timer(0.1).timeout
							magAction = "insert"
							await get_tree().create_timer(0.3).timeout
							play_random_sfx(sfx_mag_in)
							magazine.inserted = true
							magazine.freeze = true
							recoil -= 0.05
							magAction = "none"
							play_random_sfx(sfx_mag_insert)
		
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
					
		$"320/Round".visible = chamber

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
	ap.global_transform = muzzleRay.global_transform
	ap.stream = stream
	ap.bus = "SFX"
	ap.play()
	await ap.finished
	ap.queue_free()

func shoot_bullet():
	var ray := muzzleRay
	if !ray.is_colliding():
		return
	
	var collider = ray.get_collider()
	
	if collider.has_method("hit"):
		collider.hit()

	var pos := ray.get_collision_point()
	var n := ray.get_collision_normal().normalized()

	var decal := Decal.new()
	get_tree().current_scene.add_child(decal)
	decal.texture_albedo = preload("res://assets/textures/decals/bullet_hole.png")
	var up := n
	var right := up.cross(Vector3.FORWARD)
	if right.length() < 0.001:
		right = up.cross(Vector3.RIGHT)
	right = right.normalized()
	var forward := right.cross(up).normalized()

	var decalbasis := Basis(right, up, forward)

	decal.global_transform = Transform3D(decalbasis, pos + n * 0.01)
	decal.size = Vector3(0.05, 0.5, 0.05)

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
