extends Control

@onready var deceasedLabel = $DeceasedLabel
@onready var causeLabel = $CauseLabel

var cause_of_death: String = "unknown"
var end: bool = false

func _ready() -> void:
	Engine.time_scale = 1.0
	await get_tree().scene_changed

	Global.playsound(preload("res://assets/audio/music/death.wav"))

	deceasedLabel.text = "Deceased"
	deceasedLabel.modulate = Color(1.0, 0.0, 0.0, 0.0)
	deceasedLabel.position.y = 200
	causeLabel.modulate = Color(1.0, 0.0, 0.0, 0.0)
	cause_of_death = Global.cause_of_death
	causeLabel.text = "Cause of death: " + death_cause_msg()

	await get_tree().create_timer(2.0).timeout

	anim()

func anim() -> void:
	var tween = create_tween()
	tween.tween_property(deceasedLabel, "modulate:a", 1.0, 1.0)
	await get_tree().create_timer(2.0).timeout
	end = true
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()

func _process(_delta: float) -> void:
	if not end:
		return

	deceasedLabel.scale = lerp(deceasedLabel.scale, Vector2(4.0, 4.0), 0.05)
	causeLabel.modulate.a = lerp(causeLabel.modulate.a, 1.0, 0.05)

func death_cause_msg() -> String:
	if cause_of_death == "bloodloss":
		return "Blood loss"
	if cause_of_death == "cardiacarrest":
		return "Cardiac arrest"
	if cause_of_death == "fall":
		return "Falling"
	if cause_of_death == "opioidoverdose":
		return "Opiate overdose"
	if cause_of_death == "headshot":
		return "Bullet punctured brain"
	return "Unknown"
