extends CharacterBody3D

@export var move_speed := 4.0
@export var sprint_speed := 7.0
@export var acceleration := 8.0
@export var decceleration := 8.0
@export var mouse_sensitivity := 0.004
@export var jump_velocity := 4.5
@export var gravity := Vector3.DOWN * 9.8

@export var crouch_height: float = 0.4
@export var crouch_move_speed := 2.0
@export var crouch_bobbing_speed := 8.0

var crouching := false
var default_height

var mouse_look_enabled := true

var look_rotation: Vector2 = Vector2.ZERO

@onready var camera: Camera3D = $Head/Camera3D
@onready var interactray: RayCast3D = $Head/Camera3D/InteractRay
@onready var footstepRay: RayCast3D = $FootstepRay
@onready var grab_position: Node3D = $Head/Camera3D/GrabPoint
@onready var right_hand_position: Node3D = $Head/Camera3D/RHandPosition
@onready var left_hand_position: Node3D = $Head/Camera3D/LHandPosition
@onready var holster_position: Node3D = $HolsterPosition
@onready var healthCtl: Node = $HealthCtl
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
var tinnitus: float = 0.0
var hearing_damage: float = 0.0

var dead: bool = false

@export var equipment := [
	"ear-pro"
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
	]
}

const sfx_deny = preload("res://assets/audio/sfx/ui/suit_denydevice.wav")

signal Death

func play_random_sfx(sound_list, volume: float=0, spatialize=true):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], spatialize, volume)

func playsound(sound: AudioStream, spatialize: bool=true, volume: float=0.0):
	if spatialize:
		var plr = SteamAudioPlayer.new()

		plr.volume_db = volume
		plr.attenuation_model = 3
		plr.distance_attenuation = true
		plr.reflection = true
		plr.bus = "SFX"

		get_tree().get_current_scene().add_child(plr)
		plr.global_position = global_position

		plr.call_deferred("play_stream", sound, 0.0, 0.0, randf_range(0.95, 1.05))
	else:
		var plr = AudioStreamPlayer.new()
		plr.stream = sound
		plr.volume_db = volume
		plr.bus = "SFX"
		plr.pitch_scale = randf_range(0.95, 1.05)
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

		play_random_sfx(sound_list, volume)

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
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_camera_position = camera.position

func _unhandled_input(event):
	if is_input_enabled():
		if event is InputEventMouseMotion and mouse_look_enabled:
			var mouse_sens = mouse_sensitivity if not Input.is_action_pressed("zoom") else mouse_sensitivity / 4
			look_rotation.x -= event.relative.x * mouse_sens
			look_rotation.y -= event.relative.y * mouse_sens
			look_rotation.y = clampf(look_rotation.y, -1.1, 1.5)
		if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	rotation.y = look_rotation.x
	camera.rotation.x = look_rotation.y

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

	current_strafe_roll = lerp(current_strafe_roll, target_roll, delta * strafe_roll_speed)

	input_dir = input_dir.normalized()
	var sprinting = Input.is_action_pressed("sprint") and is_on_floor() and not crouching
	
	var speed = sprint_speed if sprinting else move_speed if not crouching else crouch_move_speed
	speed *= healthCtl.stamina
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

	# Apply smoothed XZ back to velocity
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	
	var current_bobbing_speed = sprint_bobbing_speed if sprinting else bobbing_speed if not crouching else crouch_bobbing_speed
	var current_bobbing_amount = sprint_bobbing_amount if sprinting else bobbing_amount
	var current_footstep_interval = sprint_footstep_interval if sprinting else footstep_interval
	current_bobbing_speed *= healthCtl.stamina

	if not is_on_floor():
		velocity += gravity * delta
	else:
		velocity.y = 0
		if is_input_enabled():
			if Input.is_action_just_pressed("jump"):
				healthCtl.physicalWork += 0.2 * (2.0 - healthCtl.stamina)
				var jump_height = jump_velocity * healthCtl.stamina
				velocity.y = jump_height
				viewpunch_velocity += jump_viewpunch
				footstep_sound("impact")
	if is_input_enabled():
		if Input.is_action_pressed("crouch"):
			crouching = true
			$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, crouch_height, 0.1)
		else:
			crouching = false
			$CollisionShape3D.position.y = lerp($CollisionShape3D.position.y, default_height, 0.1)
	
	move_and_slide()

	var vel = get_real_velocity()
	is_moving = vel.length() > 0.3
	
	
	if is_moving:
		healthCtl.physicalWork += 0.0001 if not sprinting else 0.001 * (1.5 - healthCtl.stamina)

	if not is_moving:
		current_strafe_roll = lerp(current_strafe_roll, target_roll, delta * 4.0)

	if was_moving and not is_moving:
		stop_timer = 0.0

	if not is_moving and not was_moving:
		stop_timer += delta
		if stop_timer > 0.05:
			var volume: float = -1 if crouching else 0
			footstep_sound("wander", volume)
			viewpunch_velocity += step_viewpunch / 2
			stop_timer = -999  # prevent multiple plays

	was_moving = is_moving

	# Landing detection
	if not was_on_floor and is_on_floor():
		viewpunch_velocity += land_viewpunch
		footstep_sound("impact")

	viewpunch_rotation += viewpunch_velocity * delta
	viewpunch_velocity = lerp(viewpunch_velocity, Vector3.ZERO, delta * viewpunch_damping)
	viewpunch_rotation = lerp(viewpunch_rotation, Vector3.ZERO, delta * viewpunch_damping)

	was_on_floor = is_on_floor()

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
			var volume: float = -1 if crouching else 0
			footstep_sound("step", volume)
			viewpunch_velocity += step_viewpunch
			footstep_cooldown = current_footstep_interval
			step_side = not step_side
			viewpunch_velocity += Vector3(0, 0, step_kick) if step_side else Vector3(0, 0, -step_kick)

		last_bob_value = bob_value
		footstep_cooldown -= delta
	else:
		last_bob_value = 0.0
		footstep_cooldown = 0.0

	ambient_time += delta * ambient_sway_speed

	# Ambient sway rotation
	var sway_pitch = deg_to_rad(sin(ambient_time) * ambient_pitch_amount)
	var ambient_roll = deg_to_rad(cos(ambient_time * 0.5) * ambient_roll_amount)

	var total_pitch = look_rotation.y + sway_pitch + deg_to_rad(viewpunch_rotation.x)
	var total_roll = ambient_roll + current_strafe_roll + deg_to_rad(viewpunch_rotation.z)

	var camera_rot = Vector3.ZERO
	camera_rot.x = total_pitch
	camera_rot.y = deg_to_rad(viewpunch_rotation.y)
	camera_rot.z = total_roll
	camera.rotation = camera_rot

	if position.y < -20:
		position = Vector3(3, 2, 0)
	
	if sprinting:
		right_hand_position.transform = lerp(right_hand_position.transform, sprint_rhand_pos.transform, 0.1)
	else:
		right_hand_position.transform = lerp(right_hand_position.transform, base_rhand_pos, 0.6)
	if left_hand:
		left_hand.global_transform = lerp(left_hand.global_transform, left_hand_position.global_transform, 0.8)

	if is_input_enabled():
		if Input.is_action_just_pressed("eject_mag"):
			if left_hand:
				left_hand.gravity_scale = 1.0
				left_hand.sleeping = false
				left_hand = null
		if Input.is_action_just_pressed("inspect"):
			inspecting = !inspecting


func _process(delta: float) -> void:
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
	tinnitus += amount
	if tinnitus > 0.03:
		hearing_damage += amount / 20

func die():
	dead = true
	Death.emit()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

var input_lock_reasons := {}

func set_input_lock(source: String, locked: bool):
	if locked:
		input_lock_reasons[source] = true
	else:
		input_lock_reasons.erase(source)

func is_input_enabled() -> bool:
	return input_lock_reasons.is_empty()
