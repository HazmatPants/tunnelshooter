extends ColorRect

@onready var stat = Global.player.healthCtl

var photopsia_timer: float = 0.0

const photopsia_textures := [
	preload("res://assets/textures/ui/braindamage/photopsia/flash1.png"),
	preload("res://assets/textures/ui/braindamage/photopsia/flash2.png"),
	preload("res://assets/textures/ui/braindamage/photopsia/flash3.png")
]

func _process(delta: float) -> void:
	if stat.brainHealth <= 0.75:
		photopsia_timer += delta
		if photopsia_timer > randf_range(3.0, 10.0):
			if randf() > 0.75:
				photopsia()
			photopsia_timer = 0.0

func photopsia():
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
