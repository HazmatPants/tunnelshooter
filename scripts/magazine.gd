extends RigidBody3D

@export var maximum: int = 12
@export var ammo: int = 12

@onready var ammo_label: Label3D = $AmmoLabel

var inserted: bool = false
var fade_timer: float = 0.0

func _process(delta: float) -> void:
	scale = Vector3(3, 3, 3)
	if ammo > maximum:
		ammo = maximum
	
	$Round.visible = ammo > 0
	
	ammo_label.text = str(ammo)
	
	if not inserted and fade_timer < 1.0:
		fade_timer += delta
	
	if inserted or Global.player.left_hand != self:
		fade_timer = 0.0
		ammo_label.visible = false
		ammo_label.modulate.a = 0.0
	elif Global.player.left_hand == self and fade_timer >= 1.0:
		ammo_label.visible = true
		ammo_label.modulate.a = lerp(ammo_label.modulate.a, 1.0, 0.1)
