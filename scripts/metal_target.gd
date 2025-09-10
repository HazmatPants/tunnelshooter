extends Node3D

@onready var pivot := $Pivot

@export var reset_time: float = 5.0

var is_hit: bool = false
var reset_timer: float = 0.0

const sfx_hit := [
	preload("res://assets/audio/sfx/physics/metal_target/metal_hit_tonal_1.wav"),
	preload("res://assets/audio/sfx/physics/metal_target/metal_hit_tonal_2.wav"),
	preload("res://assets/audio/sfx/physics/metal_target/metal_hit_tonal_3.wav"),
	preload("res://assets/audio/sfx/physics/metal_target/metal_hit_tonal_4.wav"),
	preload("res://assets/audio/sfx/physics/metal_target/metal_hit_tonal_5.wav")
]

func hit(_bullet: Node3D):
	is_hit = true
	play_random_sfx(sfx_hit, 16)
	$CollisionShape3D.disabled = true

func _process(delta: float) -> void:
	if is_hit:
		pivot.rotation_degrees.x = lerp(pivot.rotation_degrees.x, -90.0, 0.2)
		reset_timer += delta
	else:
		pivot.rotation_degrees.x = lerp(pivot.rotation_degrees.x, 0.0, 0.1)
	
	if reset_timer >= reset_time:
		is_hit = false
		reset_timer = 0.0
		$CollisionShape3D.disabled = false

func play_random_sfx(sound_list, volume: float=0):
	var idx = randi() % sound_list.size()
	playsound(sound_list[idx], volume)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer3D.new()
	ap.max_db = volume
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.global_transform = global_transform
	ap.stream = stream
	ap.bus = "SFX"
	ap.play()
	await ap.finished
	ap.queue_free()
