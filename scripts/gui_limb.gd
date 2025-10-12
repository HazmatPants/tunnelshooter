extends Control

@onready var health_gui = owner.get_node("HealthGUI")

var pain: float = 0.0
var muscleHealth: float = 1.0
var skinHealth: float = 1.0
var dislocationAmount: float = 0.0
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

var was_colliding: bool = false
var is_colliding: bool = false
func _process(_delta: float) -> void:
	position.x = base_pos.x + randf_range(-0.25, 0.25) * pain
	position.y = base_pos.y + randf_range(-0.25, 0.25) * pain
	var damage = clamp(muscleHealth, 0.0, 1.0)
	var color = Color(1.0, damage, damage, 1.0)
	modulate = lerp(modulate, color, 0.1)
	if dislocationAmount > 0.0:
		limb_icon.modulate = Color(1.0, 1.0 - dislocationAmount, 1.0 - dislocationAmount)
		limb_icon.texture = preload("res://assets/textures/ui/afflictions/dislocation.png")
	else:
		limb_icon.texture = null
	is_colliding = Rect2(Vector2(), size).has_point(get_local_mouse_position())
	if is_colliding:
		if Input.is_action_just_pressed("lmb") and dislocationAmount > 0.0 and not Global.player.healthCtl.get_limb_all("pain").values().max() > 0.9:
			Global.player.healthCtl.Limbs[name].pain += randf()
			if randf() > 0.6:
				Global.player.healthCtl.Limbs[name].dislocationAmount = 0.0
				Global.play_random_sfx(sfx_gore)
			else:
				Global.playsound(preload("res://assets/audio/sfx/physics/land/dislocation.ogg"))
				Global.playerGUI.shock()
	if not was_colliding and is_colliding:
		owner.get_node("HealthGUI").hovered_limb = name
		modulate.a -= 0.5

	was_colliding = is_colliding
