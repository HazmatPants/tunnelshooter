extends CharacterBody3D

@export var move_speed := 4.0
@export var sprint_speed := 7.0
@export var acceleration := 8.0
@export var decceleration := 8.0
@export var mouse_sensitivity := 0.004
@export var jump_velocity := 4.5
@export var gravity := Vector3.DOWN * 10

@export var crouch_height: float = 0.4
@export var crouch_move_speed := 2.0
@export var crouch_bobbing_speed := 8.0

var hand_shakiness := 0.01

var crouching := false
var default_height

var mouse_look_enabled := true

var look_rotation: Vector2 = Vector2.ZERO

@onready var camera: Camera3D = $Head/Camera3D
@onready var frontRay: RayCast3D = $Head/Camera3D/FrontRay
@onready var footstepRay: RayCast3D = $FootstepRay
@onready var grab_position: Node3D = $Head/Camera3D/GrabPoint
@onready var right_hand_position: Node3D = $Head/Camera3D/RHandPosition
@onready var left_hand_position: Node3D = $Head/Camera3D/LHandPosition
@onready var holster_position: Node3D = $HolsterPosition
@onready var healthCtl: Node = $HealthCtl
@onready var inventory: Node = $Inventory
var sprint_rhand_pos: Node3D = Node3D.new()
var base_rhand_pos

@onready var playerGUI = $"../PlayerGUI"

var left_hand: RigidBody3D = null
var inspecting: bool = false

var bobbing_time := 0.0
@export var bobbing_speed := 14.0
@export var bobbing_amount := 0.05

var last_bob_value := 0.0

var footstep_cooldown := 0.0
@export var footstep_interval := 0.2

@export var sprint_bobbing_speed := 18.0
@export var sprint_bobbing_amount := 0.08
@export var sprint_footstep_interval := 0.15

@export var ambient_sway_speed := 0.5
@export var ambient_pitch_amount := 2.0
@export var ambient_roll_amount := 1.0

@export var strafe_roll_amount := 2.0
@export var strafe_roll_speed := 8.0

var viewpunch_rotation := Vector3.ZERO
var viewpunch_velocity := Vector3.ZERO

@export var viewpunch_damping := 6.0
@export var jump_viewpunch := Vector3(60.0, 0, 0)
@export var land_viewpunch := Vector3(-40.0, 0, 0)
@export var step_viewpunch := Vector3(-10.0, 0, 0)

var was_on_floor := false

@export var step_kick := 12.0
var step_side := true

var current_strafe_roll := 0.0

var ambient_time := 0.0

var base_camera_position := Vector3.ZERO

var was_moving := false
var is_moving := false
var stop_timer := 0.0

var rotating: bool = false
var last_mouse_pos := Vector2.ZERO

var ap_tinnitus = AudioStreamPlayer.new()
var ap_wind = AudioStreamPlayer.new()
var tinnitus: float = 0.0
var hearing_damage: float = 0.0

var dead: bool = false

@export var equipment := [
	#"ear-pro"
]

const sfx_foot_step = {
	"default": [
		preload("res://assets/audio/sfx/footsteps/default/default_step1.wav"),
		preload("res://assets/audio/sfx/footsteps/default/default_step2.wav"),
		preload("res://assets/audio/sfx/footsteps/default/default_step3.wav"),
		preload("res://assets/audio/sfx/footsteps/default/default_step4.wav")
	],
	"plastic": [
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step1.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step2.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step3.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step4.wav")
	],
	"metal": [
		preload("res://assets/audio/sfx/footsteps/metal/metal_step1.ogg"),
		preload("res://assets/audio/sfx/footsteps/metal/metal_step2.ogg"),
		preload("res://assets/audio/sfx/footsteps/metal/metal_step3.ogg"),
		preload("res://assets/audio/sfx/footsteps/metal/metal_step4.ogg")
	],
	"concrete": [
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_step1.ogg"),
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_step2.ogg"),
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_step3.ogg"),
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_step4.ogg")
	],
	"squeakywood": [
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_walk1.ogg"),
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_walk2.ogg"),
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_walk3.ogg"),
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_walk4.ogg")
	],
	"grass": [
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk1.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk2.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk3.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk4.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk5.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk6.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk7.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk8.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk9.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_walk10.ogg")
	]
}

const sfx_foot_impact = {
	"default": [
		preload("res://assets/audio/sfx/footsteps/default/default_step1.wav"),
		preload("res://assets/audio/sfx/footsteps/default/default_step2.wav"),
		preload("res://assets/audio/sfx/footsteps/default/default_step3.wav"),
		preload("res://assets/audio/sfx/footsteps/default/default_step4.wav")
	],
	"plastic": [
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step1.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step2.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step3.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step4.wav")
	],
	"metal": [
		preload("res://assets/audio/sfx/footsteps/metal/metal_land1.ogg"),
		preload("res://assets/audio/sfx/footsteps/metal/metal_land2.ogg")
	],
	"concrete": [
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_land1.ogg"),
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_land2.ogg")
	]
}

const sfx_foot_wander = {
	"default": [
		preload("res://assets/audio/sfx/footsteps/default/default_wander1.ogg"),
		preload("res://assets/audio/sfx/footsteps/default/default_wander2.ogg"),
		preload("res://assets/audio/sfx/footsteps/default/default_wander3.ogg"),
		preload("res://assets/audio/sfx/footsteps/default/default_wander4.ogg")
	],
	"plastic": [
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step1.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step2.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step3.wav"),
		preload("res://assets/audio/sfx/footsteps/plastic/plastic_step4.wav")
	],
	"metal": [
		preload("res://assets/audio/sfx/footsteps/metal/metal_wander1.ogg"),
		preload("res://assets/audio/sfx/footsteps/metal/metal_wander2.ogg"),
		preload("res://assets/audio/sfx/footsteps/metal/metal_wander3.ogg"),
		preload("res://assets/audio/sfx/footsteps/metal/metal_wander4.ogg")
	],
	"concrete": [
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_wander1.ogg"),
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_wander2.ogg"),
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_wander3.ogg"),
		preload("res://assets/audio/sfx/footsteps/concrete/concrete_wander4.ogg")
	],
	"squeakywood": [
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_wander1.ogg"),
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_wander2.ogg"),
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_wander3.ogg"),
		preload("res://assets/audio/sfx/footsteps/squeakywood/squeakywood_wander4.ogg")
	],
	"grass": [
		preload("res://assets/audio/sfx/footsteps/grass/grass_wander1.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_wander2.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_wander3.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_wander4.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_wander5.ogg"),
		preload("res://assets/audio/sfx/footsteps/grass/grass_wander6.ogg")
	]
}

const sfx_land_heavy := [
	preload("res://assets/audio/sfx/physics/land/landheavy1.ogg"),
	preload("res://assets/audio/sfx/physics/land/landheavy2.ogg")
]

const sfx_fracture := [
	preload("res://assets/audio/sfx/physics/land/fracture1.ogg"),
	preload("res://assets/audio/sfx/physics/land/fracture2.ogg"),
	preload("res://assets/audio/sfx/physics/land/fracture3.ogg")
]

const sfx_land_mid := preload("res://assets/audio/sfx/physics/land/landmedium1.ogg")
const sfx_land_small := preload("res://assets/audio/sfx/physics/land/landsmall1.ogg")

const sfx_deny = preload("res://assets/audio/sfx/ui/suit_denydevice.wav")

signal Death

func play_random_sfx(sound_list, volume: float=0, spatialize=false, bus: String="SFX"):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], spatialize, volume, bus)

func playsound(sound: AudioStream, spatialize: bool=false, volume: float=0.0, bus: String="SFX"):
	if spatialize:
		var plr = SteamAudioPlayer.new()

		plr.volume_db = volume
		plr.attenuation_model = 3
		plr.distance_attenuation = true
		plr.reflection = true
		plr.bus = bus

		get_tree().get_current_scene().add_child(plr)
		plr.global_position = global_position

		plr.call_deferred("play_stream", sound, 0.0, 0.0, randf_range(0.95, 1.05))
	else:
		var plr = AudioStreamPlayer.new()
		plr.stream = sound
		plr.volume_db = volume
		plr.bus = bus
		get_tree().current_scene.add_child(plr)
		plr.play()

func footstep_sound(type: String="step", volume: float=0.0):
	if footstepRay.is_colliding():
		var collider = footstepRay.get_collider()
		var material = "default"
		var sound_list

		if collider.has_meta("material_type"):
			material = collider.get_meta("material_type")
		
		if type == "impact":
			sound_list = sfx_foot_impact.get(material, sfx_foot_step.get(material, sfx_foot_impact["default"]))
		elif type == "step":
			sound_list = sfx_foot_step.get(material, sfx_foot_step["default"])
		elif type == "wander":
			sound_list = sfx_foot_wander.get(material, sfx_foot_wander["default"])

		play_random_sfx(sound_list, volume, false)

func _ready():
	default_height = $CollisionShape3D.position.y
	
	base_rhand_pos = right_hand_position.transform
	get_tree().current_scene.call_deferred("add_child", sprint_rhand_pos)
	sprint_rhand_pos.position = right_hand_position.position
	sprint_rhand_pos.rotation_degrees = right_hand_position.rotation_degrees + Vector3(0.0, 20.0, -30.0)
	ap_tinnitus.stream = preload("res://assets/audio/sfx/player/tinnitus.wav")
	ap_tinnitus.volume_linear = 0.0
	ap_tinnitus.autoplay = true
	ap_tinnitus.bus = "Tinnitus"
	get_tree().current_scene.call_deferred("add_child", ap_tinnitus)

	ap_wind.stream = preload("res://assets/audio/sfx/player/windLoop.ogg")
	ap_wind.volume_linear = 0.0
	ap_wind.autoplay = true
	ap_wind.bus = "SFX"
	get_tree().current_scene.call_deferred("add_child", ap_wind)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_camera_position = camera.position

func _unhandled_input(event):
	if is_input_enabled():
		if event is InputEventMouseMotion and mouse_look_enabled:
			if healthCtl.Limbs["Neck"].dislocationAmount > 0.0:
				healthCtl.Limbs["Neck"].pain += 0.005
			var mouse_sens = mouse_sensitivity if not Input.is_action_pressed("zoom") else mouse_sensitivity / 4
			look_rotation.x -= event.relative.x * (mouse_sens * healthCtl.consciousness)
			look_rotation.y -= event.relative.y * (mouse_sens * healthCtl.consciousness)
			look_rotation.y = clampf(look_rotation.y, -1.1, 1.5)
		if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	rotation.y = look_rotation.x

var fall_velocity: float = 0.0
func _physics_process(delta):
	var input_dir = Vector3.ZERO
	var forward = -transform.basis.z.normalized()
	var right = transform.basis.x.normalized()
	if is_input_enabled():
		if Input.is_action_pressed("move_forward"):
			input_dir += forward
		if Input.is_action_pressed("move_backward"):
			input_dir -= forward
		if Input.is_action_pressed("move_right"):
			input_dir += right
		if Input.is_action_pressed("move_left"):
			input_dir -= right

	var target_roll = 0.0
	if is_input_enabled():
		if is_on_floor():
			if Input.is_action_pressed("move_left"):
				target_roll = deg_to_rad(strafe_roll_amount)
			elif Input.is_action_pressed("move_right"):
				target_roll = -deg_to_rad(strafe_roll_amount)

	current_strafe_roll = lerp(current_strafe_roll, target_roll, delta * strafe_roll_speed) * healthCtl.stamina

	input_dir = input_dir.normalized()
	var sprinting = Input.is_action_pressed("sprint") and is_on_floor() and not crouching
	
	var speed = sprint_speed if sprinting else move_speed if not crouching else crouch_move_speed
	speed *= healthCtl.stamina
	speed *= 4.0 if Global.flashmode else 1.0
	var desired_velocity = input_dir * speed
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	

	var accel
	if input_dir.length() > 0:
		if is_on_floor():
			accel = acceleration
		else:
			accel = acceleration * 0.05
	else:
		if is_on_floor():
			accel = decceleration
		else:
			accel = decceleration * 0.05
	

	horizontal_velocity = horizontal_velocity.lerp(desired_velocity, accel * delta)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	
	var current_bobbing_speed = sprint_bobbing_speed if sprinting else bobbing_speed if not crouching else crouch_bobbing_speed
	var current_bobbing_amount = sprint_bobbing_amount if sprinting else bobbing_amount
	var current_footstep_interval = sprint_footstep_interval if sprinting else footstep_interval
	current_bobbing_speed *= healthCtl.stamina

	if not is_on_floor():
		velocity += gravity * delta
		fall_velocity = velocity.y
		if abs(fall_velocity) > 5:
			viewpunch_velocity += Vector3(
				randf_range(-25.0, 25.0),
				randf_range(-25.0, 25.0),
				randf_range(-25.0, 25.0)
			)
			healthCtl.adrenaline += 0.1 * delta
		viewpunch_velocity.x += abs(fall_velocity)
	else:
		velocity.y = 0.0
		fall_velocity = 0.0
		if is_input_enabled():
			if Input.is_action_just_pressed("jump"):
				healthCtl.physicalWork += 0.2 * (2.0 - healthCtl.stamina)
				var jump_height = jump_velocity * healthCtl.stamina
				jump_height *= 3.0 if Global.flashmode else 1.0
				velocity.y = jump_height
				viewpunch_velocity += jump_viewpunch
				footstep_sound("impact")
	crouching = Input.is_action_pressed("crouch")

	if healthCtl.is_leg_injured():
		crouching = true

	if is_input_enabled():
		if crouching:
			$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, crouch_height, 0.1)
		else:
			$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, default_height, 0.1)

	footstepRay.position.y = $CollisionShape3D.position.y - 1

	move_and_slide()

	var vel = get_real_velocity()
	is_moving = vel.length() > 0.3

	if is_moving:
		healthCtl.physicalWork += 0.0001 if not sprinting else 0.0015 * (1.5 - healthCtl.stamina)
		for limb in healthCtl.Limbs.values():
			if limb.isLeg and not limb.splinted:
				if limb.dislocationAmount > 0.0:
					limb.pain += 0.1 * delta
					limb.muscleHealth -= 0.01 * delta
					limb.dislocationAmount += 0.01 * delta
				if limb.fractureAmount > 0.0:
					limb.pain += 0.2 * delta
					limb.muscleHealth -= 0.01 * delta
					limb.fractureAmount += 0.001 * delta

	if not is_moving:
		current_strafe_roll = lerp(current_strafe_roll, target_roll, delta * 4.0)

	if was_moving and not is_moving:
		stop_timer = 0.0

	if not is_moving and not was_moving:
		stop_timer += delta
		if stop_timer > 0.05:
			var volume: float = 0.1 if crouching else 0.4
			footstep_sound("wander", linear_to_db(volume))
			viewpunch_velocity += step_viewpunch / 2
			stop_timer = -999

	was_moving = is_moving

	ap_wind.volume_linear = clampf(abs(velocity.length() / 16) - 0.3, 0.0, INF)

	if not was_on_floor and is_on_floor():
		viewpunch_velocity += land_viewpunch
		footstep_sound("impact")
		do_fall_damage()
		if abs(fall_velocity) > 10:
			play_random_sfx(sfx_land_heavy, 0, false)
		elif abs(fall_velocity) > 5:
			playsound(sfx_land_mid, false)
		else:
			playsound(sfx_land_small, false)

	if healthCtl.consciousness <= healthCtl.unconsciousThreshold:
		viewpunch_rotation = Vector3.ZERO
		viewpunch_velocity = Vector3.ZERO

	viewpunch_rotation += viewpunch_velocity * delta
	viewpunch_velocity = lerp(viewpunch_velocity, Vector3.ZERO, delta * viewpunch_damping)
	viewpunch_rotation = lerp(viewpunch_rotation, Vector3.ZERO, delta * viewpunch_damping)

	was_on_floor = is_on_floor()

	if not healthCtl.consciousness <= healthCtl.unconsciousThreshold:
		if is_on_floor() and input_dir.length() > 0:
			bobbing_time += delta * current_bobbing_speed
			var bob_offset = sin(bobbing_time) * current_bobbing_amount
			camera.position.y = base_camera_position.y + bob_offset
		else:
			camera.position.y = lerp(camera.position.y, base_camera_position.y, delta * 10.0)
			bobbing_time = 0.0


	if is_on_floor() and input_dir.length() > 0:
		var bob_value = sin(bobbing_time)

		if bob_value < 0.0 and last_bob_value >= 0.0 and footstep_cooldown <= 0.0:
			var volume: float = 0.1 if crouching else 0.4
			footstep_sound("step", linear_to_db(volume))
			viewpunch_velocity += step_viewpunch
			footstep_cooldown = current_footstep_interval
			step_side = not step_side
			if healthCtl.is_leg_injured():
				viewpunch_velocity += Vector3(0, 0, step_kick * 2) if step_side else Vector3(0, 0, -step_kick * 2)
			else:
				viewpunch_velocity += Vector3(0, 0, step_kick) if step_side else Vector3(0, 0, -step_kick)

		last_bob_value = bob_value
		footstep_cooldown -= delta
	else:
		last_bob_value = 0.0
		footstep_cooldown = 0.0

	ambient_time += delta * ambient_sway_speed

	# Ambient sway rotation
	var sway_pitch = deg_to_rad(sin(ambient_time) * ambient_pitch_amount * (2.0 - healthCtl.consciousness))
	var ambient_roll = deg_to_rad(cos(ambient_time * 0.5) * ambient_roll_amount * (2.0 - healthCtl.consciousness))

	var total_pitch = look_rotation.y + sway_pitch + deg_to_rad(viewpunch_rotation.x)
	var total_roll = ambient_roll + current_strafe_roll + deg_to_rad(viewpunch_rotation.z)

	if healthCtl.consciousness <= healthCtl.unconsciousThreshold:
		total_pitch = look_rotation.y

	var camera_rot = Vector3.ZERO
	camera_rot.x = total_pitch
	camera_rot.y = deg_to_rad(viewpunch_rotation.y)
	camera_rot.z = total_roll
	camera.rotation = camera_rot

	if position.y < -20:
		position = Vector3(3, 2, 0)
	
	if sprinting:
		right_hand_position.transform = lerp(right_hand_position.transform, sprint_rhand_pos.transform, 0.1)
	elif not inspecting:
		right_hand_position.transform = lerp(right_hand_position.transform, base_rhand_pos, 0.6)
	if left_hand:
		left_hand.global_transform = lerp(left_hand.global_transform, left_hand_position.global_transform, 0.8)

	if is_input_enabled():
		if Input.is_action_just_pressed("eject_mag"):
			if left_hand:
				left_hand.gravity_scale = 1.0
				left_hand.sleeping = false
				left_hand = null

	if inventory.items["RHand"]:
		inspecting = Input.is_action_pressed("inspect")

	if inspecting:
		var inspect_transform: Transform3D = base_rhand_pos
		inspect_transform.origin += Vector3(-0.1, 0.25, 0.1)
		inspect_transform.basis = Basis.from_euler(base_rhand_pos.basis.get_euler() + Vector3(0, 1, -0.1))
		right_hand_position.transform = lerp(right_hand_position.transform, inspect_transform, 0.2)
	else:
		right_hand_position.transform = lerp(right_hand_position.transform, base_rhand_pos, 0.2)

func _process(delta: float) -> void:
	hand_shakiness = lerp(hand_shakiness, 0.01, 0.0001)
	hand_shakiness = clampf(hand_shakiness, 0.0, 0.01)
	healthCtl.heartRate -= (0.01 - hand_shakiness) * 10
	
	if tinnitus > 2:
		tinnitus = 2
	ap_tinnitus.volume_linear = tinnitus * 2
	tinnitus = lerp(tinnitus, hearing_damage, 0.15 * delta)
	
	if hearing_damage > 0:
		hearing_damage -= 0.0000001
	
	var lowpass_hz = 20000 - (hearing_damage + tinnitus) * 5e5
	if "ear-pro" in equipment:
		lowpass_hz -= 19000
	if healthCtl.consciousness <= healthCtl.unconsciousThreshold:
		lowpass_hz -= 20000
	if lowpass_hz < 100.0:
		lowpass_hz = 100.0
	if lowpass_hz > AudioServer.get_bus_effect(1, 0).cutoff_hz:
		AudioServer.get_bus_effect(1, 0).cutoff_hz = lerp(AudioServer.get_bus_effect(1, 0).cutoff_hz, lowpass_hz, 0.01)
	else:
		AudioServer.get_bus_effect(1, 0).cutoff_hz = lowpass_hz

func damage_ears(amount: float):
	if Global.quiet_guns:
		return
	tinnitus += amount
	healthCtl.Limbs["Head"].pain += amount
	if not Global.no_recoil:
		viewpunch_velocity += Vector3(100.0, 0, 0)
	if tinnitus > 0.03:
		hearing_damage += amount / 20

func die():
	dead = true
	Death.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/death_screen.tscn")

var input_lock_reasons := {}

func set_input_lock(source: String, locked: bool):
	if locked:
		input_lock_reasons[source] = true
	else:
		input_lock_reasons.erase(source)

func is_input_enabled() -> bool:
	return input_lock_reasons.is_empty()

func fall_dmg(limb):
	var dislocated: bool = false
	var fractured: bool = false
	var injured: bool = false

	if abs(fall_velocity) > 20:
		healthCtl.brainHealth -= abs(fall_velocity + randf()) / 200
		Global.cause_of_death = "fall"
		injured = true
	if abs(fall_velocity) > 16:
		healthCtl.brainHealth -= abs(fall_velocity + randf()) / 600
		healthCtl.consciousness = 0.0
		Global.cause_of_death = "fall"
		injured = true
	if abs(fall_velocity) > 14:
		healthCtl.consciousness -= abs(fall_velocity) / 200
		viewpunch_velocity += Vector3(-300.0, 0, 0)
		Global.playerGUI.shock()
		if randf() > 0.5:
			limb.pain += randf_range(0.01, abs(fall_velocity / 50))
			limb.muscleHealth -= randf_range(abs(fall_velocity / 100), abs(fall_velocity / 50))
			limb.skinHealth -= randf_range(abs(fall_velocity / 100), abs(fall_velocity / 50))
			healthCtl.internalBleeding += randf_range(0.1, 1.0)
		if randf() > 0.85:
			limb.fractureAmount += abs(fall_velocity) / randf_range(38, 42)
			fractured = true
		if randf() > 0.75:
			healthCtl.internalBleeding += randf_range(0.5, 1.5)
			limb.dislocationAmount += abs(fall_velocity) / randf_range(48, 52)
			limb.muscleHealth -= randf_range(abs(fall_velocity / 100), abs(fall_velocity / 50))
			limb.skinHealth -= randf_range(abs(fall_velocity / 100), abs(fall_velocity / 50))
			limb.pain += randf_range(0.5, abs(fall_velocity) / 25)
			dislocated = true
		injured = true
	elif abs(fall_velocity) > 10:
		if randf() > 0.5:
			viewpunch_velocity += Vector3(-200.0, 0, 0)
			limb.muscleHealth -= randf_range(abs(fall_velocity / 125), abs(fall_velocity / 100))
			limb.skinHealth -= randf_range(abs(fall_velocity / 100), abs(fall_velocity / 50))
			limb.pain += randf_range(0.01, abs(fall_velocity / 100))
		injured = true

	return {
		"injured": injured,
		"dislocated": dislocated,
		"fractured": fractured
	}

func do_fall_damage():
	if Global.godmode:
		return

	var dislocated: bool = false
	var fractured: bool = false
	var injured: bool = false

	for limb in healthCtl.Limbs.values():
		if limb.isLeg:
			var data = fall_dmg(limb)
			injured = data["injured"] if not injured else true
			dislocated = data["dislocated"] if not dislocated else true
			fractured = data["fractured"] if not fractured else true
		elif randf() > 0.7:
			var data = fall_dmg(limb)
			injured = data["injured"] if not injured else true
			dislocated = data["dislocated"] if not dislocated else true
			fractured = data["fractured"] if not fractured else true

	if dislocated:
		playsound(preload("res://assets/audio/sfx/physics/land/dislocation.ogg"), false, 0.0, "Master")
	if fractured:
		play_random_sfx(sfx_fracture, 0.0, false, "Master")
	if injured:
		playsound(preload("res://assets/audio/bgs/harmSting.ogg"), false, -20, "Master")
