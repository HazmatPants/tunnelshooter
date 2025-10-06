extends RigidBody3D

@export var useOverTime:bool = false
@export var useTime: float = 1.0

@onready var fnc: Node = $Function
@onready var anim: AnimationPlayer = $AnimationPlayer

var condition: float = 1.0

var plunger_base_transform: Transform3D
var liquid_base_transform: Transform3D

func _ready() -> void:
	if has_node("Mesh/Plunger"):
		plunger_base_transform = $Mesh/Plunger.transform
	if has_node("Mesh/Liquid"):
		liquid_base_transform = $Mesh/Liquid.transform

	add_to_group(&"items")

func _process(_delta: float) -> void:
	if useOverTime:
		if has_node("Mesh/Plunger"):
			var plunger_target_transform = plunger_base_transform
			plunger_target_transform.origin.y -= 1.4
			$Mesh/Plunger.transform = lerp(plunger_target_transform, plunger_base_transform, condition)
		if has_node("Mesh/Liquid"):
			var liquid_target_transform = liquid_base_transform
			liquid_target_transform.origin.y -= 0.8
			liquid_target_transform.basis = Basis.from_scale(Vector3(liquid_target_transform.basis.get_scale().x, 0.001, liquid_target_transform.basis.get_scale().z))
			if has_node("Mesh/LiquidDrainPos"):
				liquid_target_transform.origin= $Mesh/LiquidDrainPos.transform.origin
			$Mesh/Liquid.transform = lerp(liquid_target_transform, liquid_base_transform, condition)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.play()
	await ap.finished
	ap.queue_free()
