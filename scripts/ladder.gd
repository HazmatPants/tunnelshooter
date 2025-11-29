extends Node3D

@onready var area := $Area3D

@export var end_position: Node3D
@export var start: bool = false

var is_on_ladder: bool = false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func interact():
	if not Global.player.is_on_ladder:
		Global.player.global_position = $PlayerPos.global_position
		Global.play_random_sfx(Global.player.sfx_ladder)
		is_on_ladder = true

func _on_body_entered(body: Node3D):
	if body == Global.player:
		if start:
			Global.play_random_sfx(Global.player.sfx_ladder)
			Global.player.global_position.y += 0.1
		if not Global.player.ladders.has(self):
			Global.player.ladders.append(self)
		is_on_ladder = true

func _on_body_exited(body: Node3D):
	if body == Global.player:
		is_on_ladder = false
		Global.player.ladders.erase(self)
		if end_position and body.global_position.y > global_position.y:
			body.global_position = end_position.global_position

func _process(_delta: float) -> void:
	if is_on_ladder:
		Global.player.velocity = Vector3.ZERO
		if Global.player.is_on_floor():
			Global.player.ladders.erase(self)
			is_on_ladder = false
		if Input.is_action_pressed("jump"):
			Global.player.ladders.erase(self)
			is_on_ladder = false
