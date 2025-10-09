extends Node

const sfx_use := preload("res://assets/audio/sfx/items/pills.ogg")

func _ready() -> void:
	owner.useTime = 0.5

func use():
	Global.player.hand_shakiness -= 0.005
	owner.condition -= 0.1
