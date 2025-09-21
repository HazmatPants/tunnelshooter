extends RigidBody3D

@onready var area = $Area3D

@onready var max_lifetime := 10.0
var lifetime := 0.0

var sfx_shell := [
	preload("res://assets/audio/sfx/physics/case/shell1.wav"),
	preload("res://assets/audio/sfx/physics/case/shell2.wav"),
	preload("res://assets/audio/sfx/physics/case/shell3.wav"),
	preload("res://assets/audio/sfx/physics/case/shell4.wav"),
	preload("res://assets/audio/sfx/physics/case/shell5.wav"),
]

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(_body):
	if abs(linear_velocity.length()) > 0.1:
		var ap = AudioStreamPlayer3D.new()
		ap.bus = "SFX"
		get_tree().current_scene.add_child(ap)
		ap.global_transform = global_transform
		ap.stream = sfx_shell[randi_range(0, sfx_shell.size() - 1)]
		ap.play()
