extends Control

@onready var health_gui = owner.get_node("HealthGUI")
@onready var tooltip_progress = owner.get_node("Tooltip/Panel/VBoxContainer/TooltipProgress")

var pain: float = 0.0
var muscleHealth: float = 1.0
var skinHealth: float = 1.0
var dislocationAmount: float = 0.0
var fractureAmount: float = 0.0

var splinted: bool = false

var base_pos

var center: CenterContainer

const sfx_gore := [
	preload("res://assets/audio/sfx/player/gore1.ogg"),
	preload("res://assets/audio/sfx/player/gore2.ogg"),
	preload("res://assets/audio/sfx/player/gore3.ogg"),
	preload("res://assets/audio/sfx/player/gore4.ogg"),
	preload("res://assets/audio/sfx/player/gore5.ogg")
]

var stylebox = StyleBoxFlat.new()

func _ready() -> void:
	pivot_offset = size / 2
	base_pos = position

	center = CenterContainer.new()
	call_deferred("add_child", center)
	center.size = size
	stylebox.bg_color = Color.BLACK
	stylebox.border_color = Color.WHITE
	stylebox.set_border_width_all(2)
	add_theme_stylebox_override("panel", stylebox)

var was_colliding: bool = false
var is_colliding: bool = false

var last_disloc_amount: float = 0.0
var disloc_angle: float = 0.0
func _process(delta: float) -> void:
	position = base_pos + Vector2(
		randf_range(-pain, pain),
		randf_range(-pain, pain)
	)
	var muscle_color = Color(1.0 - muscleHealth, 0.0, 0.0, 1.0)
	if muscleHealth <= 0.0:
		muscle_color = Color.BLACK
	stylebox.bg_color = lerp(stylebox.bg_color, muscle_color, 0.1)

	var skin_color = Color(1.0, skinHealth, skinHealth, 1.0)
	if muscleHealth <= 0.0:
		skin_color = Color.BLACK
	stylebox.border_color = lerp(stylebox.border_color, skin_color, 0.1)

	is_colliding = Rect2(Vector2(), size).has_point(get_local_mouse_position())
	if is_colliding:
		if Input.is_action_just_pressed("lmb") and splinted:
			Global.player.healthCtl.Limbs[name].splinted = false
			var splint = preload("res://scenes/items/splint.tscn").instantiate()
			Global.playerScene.add_child(splint)
			splint.global_position = Global.player.global_position
			Global.playsound(preload("res://assets/audio/sfx/ui/inventory/wear.ogg"))
		if Input.is_action_pressed("lmb") and dislocationAmount > 0.0 and not Global.player.healthCtl.get_limb_all("pain").values().max() > 0.75:
			tooltip_progress.value += 0.333 * delta
			tooltip_progress.custom_minimum_size.y = lerp(tooltip_progress.custom_minimum_size.y, 5.0, 0.1)
			rotation_degrees = lerp(disloc_angle, 0.0, tooltip_progress.value)
			Global.player.healthCtl.Limbs[name].pain += 0.1 * delta
			if tooltip_progress.value >= 1.0:
				tooltip_progress.value = 0.0
				Global.playerGUI.shock()
				Global.player.viewpunch_velocity += Vector3(-300.0, 0, 0)
				Global.play_random_sfx(sfx_gore)
				if randf() > 0.5:
					Global.player.healthCtl.Limbs[name].pain -= 0.1
					Global.player.healthCtl.Limbs[name].dislocationAmount = 0.0
				else:
					if name == "Neck":
						Global.player.healthCtl.consciousness = 0.0
						Global.player.healthCtl.Limbs[name].pain = 1.0
						Global.player.healthCtl.brainHealth -= randf_range(0.0, 0.1)
					Global.player.healthCtl.Limbs[name].pain += randf_range(0.25, 0.6)
					Global.player.healthCtl.Limbs[name].dislocationAmount += randf()
					Global.playsound(preload("res://assets/audio/sfx/physics/land/dislocation.ogg"))
		else:
			rotation_degrees = lerp(rotation_degrees, disloc_angle, 0.1)
			tooltip_progress.value -= 0.5 * delta
			tooltip_progress.custom_minimum_size.y = lerp(tooltip_progress.custom_minimum_size.y, 0.0, 0.1)

	if not was_colliding and is_colliding:
		owner.get_node("HealthGUI").hovered_limb = name
		stylebox.border_color.a -= 0.5

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
