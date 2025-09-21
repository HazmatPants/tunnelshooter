extends Camera3D

@export var base_fov := 85.0
@export var zoom_fov := 20.0
@export var zoom_speed := 10.0

@onready var player = owner

func _ready() -> void:
	fov = base_fov

func _process(delta: float) -> void:
	if player.is_input_enabled():
		if Input.is_action_pressed("zoom") and player.is_input_enabled():
			fov = lerp(fov, zoom_fov, zoom_speed * delta)
		else:
			fov = lerp(fov, base_fov, zoom_speed * delta)
