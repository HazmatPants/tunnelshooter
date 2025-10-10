extends Control

var pain: float = 0.0
var muscleHealth: float = 1.0
var skinHealth: float = 1.0
var dislocated: bool = false
var base_pos

var limb_icon: TextureRect
var center: CenterContainer

const sfx_gore := [
	preload("res://assets/audio/sfx/player/gore1.ogg"),
	preload("res://assets/audio/sfx/player/gore2.ogg"),
	preload("res://assets/audio/sfx/player/gore3.ogg"),
	preload("res://assets/audio/sfx/player/gore4.ogg"),
	preload("res://assets/audio/sfx/player/gore5.ogg")
]

func _ready() -> void:
	base_pos = position

	limb_icon = TextureRect.new()
	center = CenterContainer.new()
	call_deferred("add_child", center)
	center.size = size
	center.call_deferred("add_child", limb_icon)
	limb_icon.custom_minimum_size = Vector2(24, 24)
	limb_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	position.x = base_pos.x + randf_range(-0.25, 0.25) * pain
	position.y = base_pos.y + randf_range(-0.25, 0.25) * pain
	var damage = clamp(muscleHealth, 0.0, 1.0)
	
	var color = Color(1.0, damage, damage, 1.0)
	var bleedingRate = Global.player.healthCtl.Limbs[name].bleedingRate
	var bleedcolor = Color(1.0, 1000 - bleedingRate, 1000 - bleedingRate, 1.0)
	modulate = color
	if dislocated:
		limb_icon.modulate = Color.RED
		limb_icon.texture = preload("res://assets/textures/ui/afflictions/dislocation.png")
	else:
		limb_icon.texture = null
	if bleedingRate > 0.0:
		limb_icon.modulate = bleedcolor
		limb_icon.texture = preload("res://assets/textures/ui/blood.png")
	else:
		limb_icon.texture = null
	if Rect2(Vector2(), size).has_point(get_local_mouse_position()):
		if Input.is_action_just_pressed("lmb") and dislocated and not Global.player.healthCtl.get_limb_all("pain").values().max() > 0.9:
			Global.player.healthCtl.Limbs[name].pain += randf()
			if randf() > 0.5:
				Global.player.healthCtl.Limbs[name].dislocated = false
				Global.play_random_sfx(sfx_gore)
			else:
				Global.playsound(preload("res://assets/audio/sfx/physics/land/dislocation.ogg"))
