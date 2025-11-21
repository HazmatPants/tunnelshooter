extends Node

const sfx_use := preload("res://assets/audio/sfx/ui/inventory/wear.ogg")

func _ready() -> void:
	owner.useOverTime = false
	owner.isLimbSpecific = true
	owner.useTime = 2.0

func use(limb: String):
	owner.playsound(sfx_use)
	Global.player.healthCtl.Limbs[limb].splinted = true
	owner.queue_free()
