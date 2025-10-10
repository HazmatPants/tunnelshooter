extends Node

const sfx_use := preload("res://assets/audio/sfx/ui/inventory/wear.ogg")

func _ready() -> void:
	owner.useTime = 0.8

func use():
	Global.player.equipment.append("ear-pro")
	owner.playsound(sfx_use)
	owner.queue_free()
