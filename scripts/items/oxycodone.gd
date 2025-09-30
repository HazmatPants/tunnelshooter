extends Node

const sfx_use := preload("res://assets/audio/sfx/items/pills.ogg")

func use():
	Global.player.healthCtl.opioidAmount += 0.15
	owner.condition -= 0.0333
