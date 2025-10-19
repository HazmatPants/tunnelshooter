extends ColorRect

@onready var ap = $AudioStreamPlayer

var stat

var photopsia_timer: float = 0.0
var seizure_timer: float = 0.0
var seizure_time: float = 0.0

var seizuring: bool = false

var next_seizure_time: float = 5.0

var actions = [
	"crouch",
	"jump",
	"lmb",
	"move_forward",
	"move_backward",
	"move_left",
	"move_right"
]

const photopsia_textures := [
	preload("res://assets/textures/ui/braindamage/photopsia/flash1.png"),
	preload("res://assets/textures/ui/braindamage/photopsia/flash2.png"),
	preload("res://assets/textures/ui/braindamage/photopsia/flash3.png")
]

func _ready() -> void:
	seizure_time = randf_range(1.0, 20.0)
	next_seizure_time = 15.0
	await Global.initialized
	ap.volume_linear = 0.0
	stat = Global.player.healthCtl

var was_seizuring: bool = false
func _process(delta: float) -> void:
	if not Global.is_initialized:
		return
	if stat.brainHealth <= 0.75:
		photopsia_timer += delta
		seizure_timer += delta
		if photopsia_timer >= randf_range(3.0, 10.0):
			if randf() > 0.75:
				photopsia()
			photopsia_timer = 0.0
		if seizure_timer >= next_seizure_time:
			if randf() > 0.8:
				seizuring = true
				seizure_time = randf_range(3.0, 8.0)
		if (next_seizure_time - seizure_timer < 5.0 and
		next_seizure_time - seizure_timer > 0.0):
			ap.volume_linear += 0.001
			ap.volume_linear = clampf(ap.volume_linear, 0.0, 1.0)
		else:
			ap.volume_linear = lerp(ap.volume_linear, 0.0, 0.1)
	if seizuring:
		if stat.consciousness > stat.unconsciousThreshold:
			seizure_time -= delta
			Global.player.viewpunch_velocity += Vector3(
				randf_range(-10.0, 10.0),
				randf_range(-10.0, 10.0),
				randf_range(-10.0, 10.0)
			) * randf_range(0.1, 10.0)
			AudioServer.get_bus_effect(0, 0).drive = randf_range(0.0, 0.8)
			if randf() > 0.5:
				Global.playerGUI.afterimage(randf() / 10)
				var action = actions[randi_range(0, actions.size() - 1)]
				Input.action_press(action)
				await get_tree().create_timer(randf()).timeout
				Input.action_release(action)
				await get_tree().create_timer(randf()).timeout
		else:
			seizure_time = 0.0
	if seizure_time <= 0.0:
		seizuring = false
	if was_seizuring and not seizuring:
		seizure_timer = 0.0
		next_seizure_time = randf_range(120.0, 300.0)
		AudioServer.get_bus_effect(0, 0).drive = 0.0

	was_seizuring = seizuring

func photopsia():
	Global.playerGUI.afterimage(randf() / 4)
	var viewSize := DisplayServer.window_get_size()
	var flash = TextureRect.new()
	flash.texture = photopsia_textures[randi_range(0, photopsia_textures.size() - 1)]
	add_child(flash)
	flash.position.x = randi_range(0, viewSize.x)
	flash.position.y = randi_range(0, viewSize.y)
	flash.rotation_degrees = randf_range(0, 360)
	flash.modulate = Color(randf(), randf(), randf(), randf())
	await get_tree().create_timer(randf_range(0.02, 0.05)).timeout
	flash.texture = photopsia_textures[randi_range(0, photopsia_textures.size() - 1)]
	flash.position.x = randi_range(0, viewSize.x)
	flash.position.y = randi_range(0, viewSize.y)
	flash.rotation_degrees = randf_range(0, 360)
	flash.modulate = Color(randf(), randf(), randf(), randf())
	await get_tree().create_timer(randf_range(0.02, 0.25)).timeout
	flash.queue_free()
