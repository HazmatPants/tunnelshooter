extends Control

@onready var health_gui = owner.get_node("HealthGUI")
@onready var tooltip_progress = owner.get_node("Tooltip/Panel/VBoxContainer/TooltipProgress")

var pain: float = 0.0
var muscleHealth: float = 1.0
var skinHealth: float = 1.0
var dislocationAmount: float = 0.0
var fractureAmount: float = 0.0
var base_pos

var center: CenterContainer

const sfx_gore := [
	preload("res://assets/audio/sfx/player/gore1.ogg"),
	preload("res://assets/audio/sfx/player/gore2.ogg"),
	preload("res://assets/audio/sfx/player/gore3.ogg"),
	preload("res://assets/audio/sfx/player/gore4.ogg"),
	preload("res://assets/audio/sfx/player/gore5.ogg")
]

func _ready() -> void:
	pivot_offset = size / 2
	base_pos = position

	center = CenterContainer.new()
	call_deferred("add_child", center)
	center.size = size

var was_colliding: bool = false
var is_colliding: bool = false

var last_disloc_amount: float = 0.0
var disloc_angle: float = 0.0
func _process(delta: float) -> void:
	position = base_pos + Vector2(
		randf_range(-pain, pain),
		randf_range(-pain, pain)
	)
	var damage = clamp(muscleHealth, 0.0, 1.0)
	var color = Color(1.0, damage, damage, 1.0)
	if muscleHealth <= 0.01:
		color = Color.BLACK
	self_modulate = lerp(self_modulate, color, 0.1)
	is_colliding = Rect2(Vector2(), size).has_point(get_local_mouse_position())
	if is_colliding:
		if Input.is_action_pressed("lmb") and dislocationAmount > 0.0 and not Global.player.healthCtl.get_limb_all("pain").values().max() > 0.75:
			tooltip_progress.value += 0.333 * delta
			tooltip_progress.custom_minimum_size.y = lerp(tooltip_progress.custom_minimum_size.y, 5.0, 0.1)
			rotation_degrees = lerp(disloc_angle, 0.0, tooltip_progress.value)
			if tooltip_progress.value >= 1.0:
				tooltip_progress.value = 0.0
				Global.player.healthCtl.Limbs[name].pain += randf_range(0.25, 0.6)
				Global.playerGUI.shock()
				Global.player.viewpunch_velocity += Vector3(-300.0, 0, 0)
				Global.play_random_sfx(sfx_gore)
				if randf() > 0.5:
					Global.player.healthCtl.Limbs[name].dislocationAmount = 0.0
				else:
					Global.player.healthCtl.Limbs[name].dislocationAmount += randf()
					Global.playsound(preload("res://assets/audio/sfx/physics/land/dislocation.ogg"))
		else:
			rotation_degrees = lerp(rotation_degrees, disloc_angle, 0.1)
			tooltip_progress.value -= 0.5 * delta
			tooltip_progress.custom_minimum_size.y = lerp(tooltip_progress.custom_minimum_size.y, 0.0, 0.1)

	if not was_colliding and is_colliding:
		owner.get_node("HealthGUI").hovered_limb = name
		self_modulate.a -= 0.5

	if dislocationAmount > last_disloc_amount:
		if roundi(randf()):
			disloc_angle = randf_range(5, 10)
			rotation_degrees = disloc_angle
		else:
			disloc_angle = randf_range(-5, -10)
			rotation_degrees = disloc_angle
	if is_zero_approx(dislocationAmount):
		rotation_degrees = 0.0
		disloc_angle = 0.0

	was_colliding = is_colliding
	last_disloc_amount = dislocationAmount
