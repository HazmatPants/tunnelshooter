extends ColorRect

@onready var ap = $AudioStreamPlayer

var stat

var photopsia_timer: float = 0.0
var seizure_timer: float = 0.0
var lob_timer: float = 0.0
var seizure_time: float = 0.0

var seizuring: bool = false

var next_seizure_time: float = randf_range(120.0, 300.0)
var next_photopsia_time: float = randf_range(3.0, 10.0)
var next_lob_time: float = randf_range(30.0, 120.0)

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
		if photopsia_timer >= next_photopsia_time:
			if randf() > 0.75:
				photopsia()
			photopsia_timer = 0.0
		if seizure_timer >= next_seizure_time and not seizuring:
			if randf() > 0.8:
				seizuring = true
				seizure_time = randf_range(1.0, 8.0)
		if (next_seizure_time - seizure_timer < 5.0 and
		next_seizure_time - seizure_timer > 0.0):
			ap.volume_linear += 0.001
			ap.volume_linear = clampf(ap.volume_linear, 0.0, 1.0)
		else:
			ap.volume_linear = lerp(ap.volume_linear, 0.0, 0.1)
	if stat.brainHealth <= 0.5:
		lob_timer += delta
		if lob_timer >= next_lob_time:
			if randf() > 0.75:
				lobotomy()
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
	next_photopsia_time = randf_range(3.0, 10.0)
	if randf() > 0.8:
		Global.playerGUI.afterimage(randf() / 4, randf_range(1.0, 3.0), randf_range(1.0, 3.0), randf_range(1.0, 3.0))
		Global.playsound(preload("res://assets/audio/bgs/headhit.ogg"))
	else:
		Global.playerGUI.afterimage(randf() / 4)

	var flash = TextureRect.new()
	flash.texture = photopsia_textures[randi_range(0, photopsia_textures.size() - 1)]
	add_child(flash)
	flash.modulate = Color(randf(), randf(), randf(), randf())
	await get_tree().create_timer(randf_range(0.02, 0.05)).timeout
	flash.texture = photopsia_textures[randi_range(0, photopsia_textures.size() - 1)]
	flash.modulate = Color(randf(), randf(), randf(), randf())
	await get_tree().create_timer(randf_range(0.02, 0.25)).timeout
	flash.queue_free()

func lobotomy():
	lob_timer = 0.0
	Global.playerGUI.afterimage(randf() / 2, randf_range(2.0, 10.0), randf_range(5.0, 10.0), randf_range(5.0, 10.0))
	Global.playsound(preload("res://assets/audio/music/lobotomy.wav"), randf_range(0.9, 1.1))
	next_lob_time = randf_range(30.0, 120.0)
