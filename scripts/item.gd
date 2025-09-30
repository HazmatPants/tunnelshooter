extends RigidBody3D

func _ready() -> void:
	add_to_group(&"items")

func use():
	$Function.call("use")
	playsound($Function.sfx_use)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.play()
	await ap.finished
	ap.queue_free()
