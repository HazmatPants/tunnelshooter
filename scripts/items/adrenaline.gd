extends Node

const sfx_use := preload("res://assets/audio/sfx/items/syringe.ogg")

func use():
	Global.player.healthCtl.adrenaline += 0.5
	
	await get_tree().create_timer(1.5).timeout
	owner.condition = 0.0
