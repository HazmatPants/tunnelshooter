extends CanvasLayer

@onready var hint_label: Label = $HintText
@onready var pickup_text: Label = $PickupText
@onready var mp: AudioStreamPlayer = $MusicPlayer
@onready var tooltip: Control = $Tooltip
@onready var shockOverlay: TextureRect = $Shock
@onready var afterimageOverlay: TextureRect = $afterimage

var hint_queue: Array[String] = []
var hint_tween: Tween = null
var is_showing: bool = false
var current_hint: String = ""

var bgm_dying = preload("res://assets/audio/music/dying.wav")

func _ready() -> void:
	await Global.initialized
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
func _process(delta: float) -> void:
	if not Global.is_initialized:
		return
	var total_pain = Global.player.healthCtl.get_limb_all("pain").values().max()
	var painImageSine = 2.0 - total_pain
	painImageSine += (sin((PI * time) / 30) * 2 / 2 * PI)
	time += 1
	$Pain/Pain.scale = $Pain/Pain.scale.lerp(Vector2(1.3, 1.3) * painImageSine * 2, 0.01)
	$Pain/Pain.modulate.a = total_pain
	$Pain/Pain.scale = $Pain/Pain.scale.clamp(Vector2(0.5, 0.5), Vector2(INF, INF))

	$Blackout.modulate.a = lerp($Blackout.modulate.a, 1.0 - Global.player.healthCtl.consciousness, 0.1)
	if Global.player.healthCtl.brainHealth < last_brainHealth and $Blackout.modulate.a > 0.9:
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

	if shockOverlay.modulate.a > 0.0:
		shockOverlay.modulate.a -= 1.0 * delta

	if afterimageOverlay.modulate.a > 0.0:
		afterimageOverlay.modulate.a -= 0.025 * delta

func _death():
	$Blackout/Label.text = ""

func shock():
	shockOverlay.modulate.a = 1.0

func afterimage(alpha=1.0):
	var image = get_viewport().get_texture().get_image()
	image.adjust_bcs(7.0, 1.0, 2.0)
	afterimageOverlay.texture = ImageTexture.create_from_image(image)
	afterimageOverlay.modulate.a = alpha
