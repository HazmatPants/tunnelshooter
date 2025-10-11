extends Node

const sfx_use := preload("res://assets/audio/sfx/items/bandage.ogg")

func _ready() -> void:
	owner.isLimbSpecific = true
	owner.useTime = 0.33

func use():
	owner.playsound(sfx_use)

func useTick(delta: float, limb: String):
	Global.player.healthCtl.Limbs[limb].bleedingRate -= 1.0 * delta
	Global.player.healthCtl.Limbs[limb].skinHealth += 0.025 * delta
	owner.condition -= 0.1 * delta
