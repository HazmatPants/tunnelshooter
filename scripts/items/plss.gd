extends Node

const sfx_use := preload("res://assets/audio/sfx/ui/inventory/wear.ogg")

func _ready() -> void:
	owner.useTime = 2.0

func use():
	Global.player.healthCtl.lifesupport += 120.0
	owner.playsound(sfx_use)
	owner.queue_free()
