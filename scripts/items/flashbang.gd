extends Node

const sfx_spool := preload("res://assets/audio/sfx/weapons/grenade/spool.ogg")
const sfx_pin := preload("res://assets/audio/sfx/weapons/grenade/pin.ogg")
const sfx_explode := preload("res://assets/audio/sfx/weapons/explosive/plastic_explosive_1.wav")

@onready var ray: RayCast3D = $"../RayCast3D"
@onready var onscreen: VisibleOnScreenNotifier3D = $"../VisibleOnScreenNotifier3D"

var flash = preload("res://scenes/muzzleflash.tscn")

var used: bool = false

func _ready() -> void:
	owner.useTime = 1.4

func use():
	owner.playsound(sfx_pin)
	used = true

func _process(_delta: float) -> void:
	var target = Global.player.get_node("Head").global_transform.origin
	var target_basis: Basis
	target_basis = Transform3D().looking_at(target - owner.global_transform.origin).basis

	ray.global_transform.basis = target_basis
	if Input.is_action_just_released("lmb") and used and Global.player.inventory.items["RHand"] == owner:
		throw()

func throw():
	Global.player.inventory.items["RHand"] = null
	owner.gravity_scale = 1.0
	$"../CollisionShape3D".disabled = false
	owner.anim.stop()
	owner.anim.current_animation = "used"
	var direction = Global.player.camera.global_transform.basis.z * -1.0
	owner.apply_central_impulse(direction * 20)
	owner.playsound(sfx_spool)
	await get_tree().create_timer(2.0).timeout
	owner.playsound(sfx_explode, 10)
	var Flash = flash.instantiate()
	Flash.light_energy = 300
	Flash.omni_range = 100.0
	get_tree().current_scene.add_child(Flash)
	Flash.global_position = owner.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	if (
	onscreen.is_on_screen() and 
	ray.is_colliding() and 
	ray.get_collider().owner == Global.player
	):
		Global.playerGUI.afterimage()
	Global.player.damage_ears(0.4)
	owner.queue_free()
