extends Node3D

@onready var area = $Area3D
@onready var launcher = $LauncherPivot

var reset_timer: float = 0.0

var bodies: Array = []

func _ready() -> void:
	area.body_entered.connect(_body_entered)
	area.body_exited.connect(_body_exited)

func _body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		bodies.append(body)
	if reset_timer <= 0.0 and launcher.rotation_degrees.x < 1.0:
		reset_timer = 1.0
		Global.playsound(preload("res://assets/audio/sfx/physics/launcher.wav"), 0, 1.0, global_position)
		for b in bodies:
			b.velocity += Vector3(0.0, 17.0, 13.0)
			if b == Global.player:
				b.viewpunch_velocity.x += 1000.0

func _body_exited(body: Node3D) -> void:
	bodies.erase(body)

func _process(delta: float) -> void:
	if reset_timer > 0.0:
		reset_timer -= delta
		launcher.rotation_degrees.x = lerp(launcher.rotation_degrees.x, 70.0, 0.7)
	else:
		launcher.rotation_degrees.x = lerp(launcher.rotation_degrees.x, 0.0, 0.1)
