extends Node

const sfx_use := preload("res://assets/audio/sfx/items/pills.ogg")

func _ready() -> void:
	owner.useTime = 0.5

func use():
	Global.player.healthCtl.opioidAmount += 0.3
	owner.condition -= 0.0333
	owner.playsound(sfx_use)
