extends HBoxContainer

var afflictionTscn = preload("res://scenes/affliction.tscn")

var afflictions := {}

signal resize

func _ready() -> void:
	await Global.initialized
	afflictions = Global.player.healthCtl.afflictions.duplicate(true)
	
	Global.player.healthCtl.affliction_added.connect(refresh_afflictions)

func _process(_delta: float) -> void:
	if not Global.is_initialized:
		return
	afflictions = Global.player.healthCtl.afflictions.duplicate(true)
	size.x = afflictions.size() * 64
	resize.emit()

func refresh_afflictions(new_afflictions: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	
	for affliction in new_afflictions:
		var affliction_new = afflictionTscn.instantiate()
		affliction_new.aff_name = affliction
		add_child(affliction_new)

	afflictions = new_afflictions.duplicate(true)
