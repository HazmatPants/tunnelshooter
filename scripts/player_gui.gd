extends CanvasLayer

@onready var hint_label: Label = $HintText
@onready var hearing_damage_icon: TextureRect = $HearingDamageIcon
@onready var mp: AudioStreamPlayer = $MusicPlayer
@onready var mp2: AudioStreamPlayer = $MusicPlayer2
@onready var tooltip: Control = $Tooltip

var hint_queue: Array[String] = []
var hint_tween: Tween = null
var is_showing: bool = false
var current_hint: String = ""

var hearing_damage_icon_base_pos

var bgm_dying = preload("res://assets/audio/music/dying.wav")
var bgm_death = preload("res://assets/audio/music/death.wav")

func _ready() -> void:
	hearing_damage_icon_base_pos = hearing_damage_icon.position
	
	Global.player.Death.connect(_death)
	
	$Blackout.visible = true

func show_hint(text: String) -> void:
	if text == current_hint:
		if hint_tween and hint_tween.is_running():
			hint_tween.kill()

		hint_label.modulate.a = 1.0
		hint_tween = create_tween()
		hint_tween.tween_interval(3.0)
		hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.5)
		hint_tween.finished.connect(_display_next_hint)
		return

	if not hint_queue.is_empty() and text == hint_queue.back():
		return

	hint_queue.append(text)

	if not is_showing:
		_display_next_hint()

func _display_next_hint() -> void:
	if hint_queue.is_empty():
		is_showing = false
		current_hint = ""
		return

	is_showing = true
	current_hint = hint_queue.pop_front()
	_start_hint_tween(current_hint)

func _start_hint_tween(text: String) -> void:
	hint_label.text = text
	hint_label.modulate.a = 0.0

	hint_tween = create_tween()
	hint_tween.tween_interval(1.0)
	hint_tween.tween_property(hint_label, "modulate:a", 1.0, 0.5)
	hint_tween.tween_interval(3.0)
	hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.5)
	hint_tween.finished.connect(_display_next_hint)

var time = 0
var last_brainHealth: float = 0
func _process(_delta: float) -> void:
	var alpha = clamp(Global.player.tinnitus * 100, Global.player.hearing_damage / 10, 1.0)
	var damage = clamp(Global.player.hearing_damage * 100, 0.0, 1.0)
	
	var color = Color(1.0, 1.0 - damage, 1.0 - damage, alpha)
	hearing_damage_icon.modulate = color

	hearing_damage_icon.position = hearing_damage_icon_base_pos + Vector2(
		randf_range(-1, 1), 
		randf_range(-1, 1)
		) * (Global.player.tinnitus * 50)

	$tinnitus.text = "Tinnitus: " + str(Global.player.tinnitus)
	$hearingdamage.text = "Damage: " + str(Global.player.hearing_damage)
	
	var painImageSine = 2.0 - Global.player.healthCtl.get_limb_total("pain")
	painImageSine += (sin((PI * time) / 30) * 1 / 2 * PI)
	painImageSine += 10
	time += 1
	$Pain/Pain.scale = Vector2(1.0, 1.0) * painImageSine

	$Blackout.modulate.a = 1.0 - Global.player.healthCtl.consciousness
	if Global.player.healthCtl.brainHealth < last_brainHealth:
		if $Blackout.visible and not Global.player.dead: # dying
			$Blackout/TextureProgressBar.modulate = Color(1, 0, 0, $Blackout/TextureProgressBar.modulate.a)
			$Blackout/TextureProgressBar.value = Global.player.healthCtl.brainHealth
			$Blackout/Label.text = "!!"
			mp.volume_linear = lerp(mp.volume_linear, 1.0, 0.05)
			$Blackout/TextureProgressBar.max_value = 1
			if not mp.playing:
				mp.stream = bgm_dying
				mp.play()
	elif not Global.player.dead: # unconscious
		$Blackout/TextureProgressBar.modulate = Color(1, 1, 1, $Blackout/TextureProgressBar.modulate.a)
		$Blackout/TextureProgressBar.value = Global.player.healthCtl.consciousness
		$Blackout/TextureProgressBar.max_value = Global.player.healthCtl.unconsciousThreshold
		$Blackout/Label.text = "..."
		mp.volume_linear = lerp(mp.volume_linear, 0.0, 0.05)
	else: # dead
		$Blackout/TextureProgressBar.value = 0
		mp.volume_linear = lerp(mp.volume_linear, 0.0, 0.05)

	if Global.player.healthCtl.consciousness <= 0.15:
		$Blackout/TextureProgressBar.visible = true
		$Blackout/TextureProgressBar.modulate.a = lerp($Blackout/TextureProgressBar.modulate.a, 1.0, 0.05)
		$Blackout/Label.modulate.a = lerp($Blackout/Label.modulate.a, 1.0, 0.05)
	else:
		$Blackout/TextureProgressBar.visible = false
		$Blackout/TextureProgressBar.modulate.a = 0.0
		$Blackout/Label.modulate.a = 0.0
	
	last_brainHealth = Global.player.healthCtl.brainHealth

func _death():
	$Blackout/Label.text = ""
	mp2.stream = bgm_death
	mp2.play()
