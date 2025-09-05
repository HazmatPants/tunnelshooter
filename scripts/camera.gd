extends Camera3D

@export var base_fov := 85.0
@export var zoom_fov := 40.0
@export var zoom_speed := 10.0

@onready var player = get_parent()

func _ready() -> void:
	fov = base_fov

func _process(delta: float) -> void:
	if player.input_enabled:
		if Input.is_action_pressed("zoom"):
			fov = lerp(fov, zoom_fov, zoom_speed * delta)
		else:
			fov = lerp(fov, base_fov, zoom_speed * delta)
