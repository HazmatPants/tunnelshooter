extends RigidBody3D

@onready var anim: AnimationPlayer = $AnimationPlayer

var condition: float = 1.0

func _ready() -> void:
	add_to_group(&"items")

func _process(_delta: float) -> void:
	if condition <= 0.0:
		queue_free()

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
