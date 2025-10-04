extends Node

const sfx_use := preload("res://assets/audio/sfx/items/syringe.ogg")

func _ready() -> void:
	owner.useTime = 1.0

func use():
	Global.player.healthCtl.Limbs["LUpperArm"].pain += 0.1
	Global.player.healthCtl.Limbs["LUpperArm"].muscleHealth -= 0.05
	owner.playsound(sfx_use)

func useTick(delta: float):
	Global.player.healthCtl.opioidAmount += 1.5 * delta
	owner.condition -= 0.1 * delta
