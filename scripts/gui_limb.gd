extends Control

var pain: float = 0.0
var muscleHealth: float = 1.0
var skinHealth: float = 1.0
var base_pos

func _ready() -> void:
	base_pos = position

func _process(_delta: float) -> void:
	position.x = base_pos.x + randf_range(-0.25, 0.25) * pain
	position.y = base_pos.y + randf_range(-0.25, 0.25) * pain
	var damage = clamp(muscleHealth, 0.0, 1.0)
	
	var color = Color(1.0, damage, damage, 1.0)
	modulate = color
