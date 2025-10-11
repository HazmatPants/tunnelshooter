extends Node

const sfx_use := preload("res://assets/audio/sfx/ui/inventory/wear.ogg")

func _ready() -> void:
	owner.isLimbSpecific = true
	owner.useTime = 1.0

func use():
	owner.playsound(sfx_use)

func useTick(delta: float, limb: String):
	Global.player.healthCtl.Limbs[limb].muscleHealMult += 1.0 * delta
	Global.player.healthCtl.Limbs[limb].pain -= 0.1 * delta
	owner.condition -= 0.01 * delta

func _process(delta: float) -> void:
	owner.condition += 0.005 * delta
