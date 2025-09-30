extends Node

@onready var frontRay: RayCast3D
@onready var itemUseProgress := Global.playerGUI.get_node("ItemUseProgress") 

var hovered_item

var items := {
	"LHand": null,
	"RHand": null
}

const sfx_pickup := preload("res://assets/audio/sfx/ui/inventory/pickup.wav")

func _process(delta: float) -> void:
	frontRay = Global.player.frontRay
	if frontRay:
		if frontRay.is_colliding():
			var collider: Node = frontRay.get_collider()
			if collider.is_in_group(&"items") and not items["RHand"] == collider and not items["LHand"] == collider:
				hovered_item = collider
				Global.playerGUI.pickup_text.text = hovered_item.name
				if Input.is_action_just_pressed("interact"):
					if items["RHand"] == null:
						items["RHand"] = collider
						collider.gravity_scale = 0.0
					elif items["LHand"] == null:
						items["LHand"] = collider
						collider.gravity_scale = 0.0
					Global.playerGUI.pickup_text.text = ""
					hovered_item = null
					playsound(sfx_pickup)
			elif hovered_item:
				Global.playerGUI.pickup_text.text = ""
				hovered_item = null
	if items["RHand"]:
		items["RHand"].global_transform = lerp(items["RHand"].global_transform, Global.player.right_hand_position.global_transform, 0.5)
	if Input.is_action_just_pressed("lmb"):
		if items["RHand"]:
			if Global.player.inspecting:
				items["RHand"].gravity_scale = 1.0
				var direction = Global.player.camera.global_transform.basis.z * -1.0
				if Global.player.camera.rotation_degrees.x > 0:
					items["RHand"].apply_central_impulse(direction * 6)
				else:
					items["RHand"].apply_central_impulse(direction)
				items["RHand"] = null

	if Input.is_action_pressed("lmb"):
		if items["RHand"]:
			itemUseProgress.modulate.a = lerp(itemUseProgress.modulate.a, 1.0, 0.1)
			itemUseProgress.value += delta
			if itemUseProgress.value >= 1.0:
				items["RHand"].call("use")
				itemUseProgress.value = 0.0
	else:
		itemUseProgress.value = 0.0
		itemUseProgress.modulate.a = lerp(itemUseProgress.modulate.a, 0.0, 0.1)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.play()
	await ap.finished
	ap.queue_free()
