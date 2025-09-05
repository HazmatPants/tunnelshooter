extends Node3D

@export var maximum: int = 12
@export var ammo: int = 12

@onready var ammo_label: Label3D = $AmmoLabel

var inserted: bool = false

func _process(_delta: float) -> void:
	scale = Vector3(3, 3, 3)
	if ammo > maximum:
		ammo = maximum
	
	$Round.visible = ammo > 0
	
	ammo_label.text = str(ammo)
	
	if inserted or Global.player.left_hand != self:
		ammo_label.visible = false
		ammo_label.modulate.a = 0.0
	elif Global.player.left_hand == self:
		ammo_label.visible = true
		ammo_label.modulate.a = lerp(ammo_label.modulate.a, 0.4, 0.01)
