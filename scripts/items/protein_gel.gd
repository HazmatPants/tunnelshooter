extends Node

const sfx_use := preload("res://assets/audio/sfx/items/goo.ogg")

func _ready() -> void:
	owner.useOverTime = false
	owner.isLimbSpecific = true
	owner.useTime = 1.0

func use(limb: String):
	owner.playsound(sfx_use)
	Global.player.healthCtl.Limbs[limb].muscleHealMult += 50.0
	owner.condition -= 0.1
