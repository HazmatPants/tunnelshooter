extends OmniLight3D

func _ready() -> void:
	light_color = Color(1, 1, 1, 1)
	

func _process(_delta: float) -> void:
	light_energy = lerp(light_energy, 0.0, 0.5)
	
	if light_energy <= 0:
		queue_free()
