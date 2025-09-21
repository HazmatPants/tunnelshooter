extends HBoxContainer

var afflictionTscn = preload("res://scenes/affliction.tscn")

var afflictions := {}

func _process(_delta: float) -> void:
	if afflictions != Global.player.healthCtl.afflictions:
		refresh_afflictions()

	size.x = Global.player.healthCtl.afflictions.size() * 64

func refresh_afflictions():
	for child in get_children():
		child.queue_free()
	
	for affliction in Global.player.healthCtl.afflictions:
		var affliction_new = afflictionTscn.instantiate()
		affliction_new.aff_name = affliction
		add_child(affliction_new)
