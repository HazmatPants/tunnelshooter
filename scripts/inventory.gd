extends Node

var frontRay: RayCast3D
var itemUseProgress: TextureProgressBar
var itemConditionProgress: TextureProgressBar 

var hovered_item

var items := {
	"LHand": null,
	"RHand": null
}

const sfx_pickup := preload("res://assets/audio/sfx/ui/inventory/pickup.wav")

var initialized: bool = false

func _ready() -> void:
	await Global.initialized
	initialized = true
	itemUseProgress = Global.playerGUI.get_node("ItemUseProgress") 
	itemConditionProgress = Global.playerGUI.get_node("ItemConditionProgress") 

var using := false
var used := false
var depleted := false
func _process(delta: float) -> void:
	if not initialized:
		return
	frontRay = Global.player.frontRay
	if frontRay:
		if frontRay.is_colliding():
			var collider: Node = frontRay.get_collider()
			if collider and collider.is_in_group(&"items") and not items["RHand"] == collider and not items["LHand"] == collider:
				hovered_item = collider
				Global.playerGUI.pickup_text.text = hovered_item.name
				if Input.is_action_just_pressed("interact"):
					if items["RHand"] == null:
						items["RHand"] = collider
						items["RHand"].get_node("CollisionShape3D").disabled = true
						collider.gravity_scale = 0.0
						Global.playerGUI.pickup_text.text = ""
						hovered_item = null
						playsound(sfx_pickup)
			elif hovered_item:
				Global.playerGUI.pickup_text.text = ""
				hovered_item = null
	if Input.is_action_just_pressed("drop"):
		if items["RHand"]:
			items["RHand"].gravity_scale = 1.0
			items["RHand"].get_node("CollisionShape3D").disabled = false
			var direction = Global.player.camera.global_transform.basis.z * -1.0
			if Global.player.camera.rotation_degrees.x > 0:
				items["RHand"].apply_central_impulse(direction * 6)
			else:
				items["RHand"].apply_central_impulse(direction)
			items["RHand"] = null
	if items["RHand"]:
		items["RHand"].global_transform = lerp(items["RHand"].global_transform, Global.player.right_hand_position.global_transform, 0.5)
		if items["RHand"].has_meta("IsGun"):
			return
	if Input.is_action_just_pressed("lmb") and items["RHand"]:
		if items["RHand"].useOverTime:
			items["RHand"].anim.current_animation = "useStart"
		else:
			items["RHand"].anim.current_animation = "use"
		itemUseProgress.max_value = items["RHand"].useTime

	if Input.is_action_just_released("lmb"):
		if items["RHand"]:
			if not used and not using:
				items["RHand"].anim.stop()
			if using and not depleted:
				using = false
				items["RHand"].anim.current_animation = "useEnd"
			used = false

	if Input.is_action_pressed("lmb"):
		if items["RHand"]:
			if not used:
				itemUseProgress.modulate.a = lerp(itemUseProgress.modulate.a, 1.0, 0.1)
				itemUseProgress.value += delta
				if itemUseProgress.value >= itemUseProgress.max_value:
					if items["RHand"].useOverTime:
						using = true
					used = true
					items["RHand"].fnc.call("use")
					itemUseProgress.value = 0.0
			if using:
				itemConditionProgress.value = items["RHand"].condition
				itemConditionProgress.position = Vector2(10, 640)
				if items["RHand"].condition > 0.0:
					items["RHand"].fnc.useTick(delta)
				elif not depleted:
					depleted = true
					items["RHand"].anim.current_animation = "useDeplete"
					await items["RHand"].anim.animation_finished
					depleted = false
					using = false
					used = false
					items["RHand"].queue_free()
				itemUseProgress.value = 0.0
				itemUseProgress.modulate.a = lerp(itemUseProgress.modulate.a, 0.0, 0.1)
				itemConditionProgress.modulate.a = lerp(itemConditionProgress.modulate.a, 1.0, 0.1)
		if depleted:
			itemConditionProgress.modulate.a = lerp(itemConditionProgress.modulate.a, 0.0, 0.1)
	else:
		if items["RHand"] and Global.player.inspecting:
			itemConditionProgress.position = Vector2(766, 518)
			itemConditionProgress.value = items["RHand"].condition
			itemConditionProgress.modulate.a = Global.playerGUI.get_node("ItemInfo").modulate.a
		itemUseProgress.value = 0.0
		itemUseProgress.modulate.a = lerp(itemUseProgress.modulate.a, 0.0, 0.1)
		itemConditionProgress.modulate.a = lerp(itemConditionProgress.modulate.a, 0.0, 0.1)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.play()
	await ap.finished
	ap.queue_free()
