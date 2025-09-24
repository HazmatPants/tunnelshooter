extends Control

@onready var Limbs: Dictionary = { # GUI limbs
	"Head": $Body/Head,
	"Neck": $Body/Neck,
	"Thorax": $Body/Thorax,
	"Abdomen": $Body/Abdomen,
	"LUpperArm": $Body/LUpperArm,
	"LForearm": $Body/LForearm,
	"LHand": $Body/LHand,
	"RUpperArm": $Body/RUpperArm,
	"RForearm": $Body/RForearm,
	"RHand": $Body/RHand,
	"LThigh": $Body/LThigh,
	"LCrus": $Body/LCrus,
	"LFoot": $Body/LFoot,
	"RThigh": $Body/RThigh,
	"RCrus": $Body/RCrus,
	"RFoot": $Body/RFoot,
}

@onready var PhysicalLimbs: Dictionary = { # real node3d Limbs
	"Head": Global.player.get_node("Head"),
	"Neck": Global.player.get_node("Neck"),
	"Thorax": Global.player.get_node("Thorax"),
	"Abdomen": Global.player.get_node("Abdomen"),
	"LUpperArm": Global.player.get_node("LArm/LUpperArm"),
	"LForearm": Global.player.get_node("LArm/LUpperArm/LForearmPivot/LForearm"),
	"LHand": Global.player.get_node("LArm/LUpperArm/LForearmPivot/LForearm/LHandPivot/LHand"),
	"RUpperArm": Global.player.get_node("RArm/RUpperArm"),
	"RForearm": Global.player.get_node("RArm/RUpperArm/RForearmPivot/RForearm"),
	"RHand": Global.player.get_node("RArm/RUpperArm/RForearmPivot/RForearm/RHandPivot/RHand"),
	"LThigh": Global.player.get_node("LLeg/LThigh"),
	"LCrus": Global.player.get_node("LLeg/LThigh/LCrusPivot/LCrus"),
	"LFoot": Global.player.get_node("LLeg/LThigh/LCrusPivot/LCrus/LFootPivot/LFoot"),
	"RThigh": Global.player.get_node("RLeg/RThigh"),
	"RCrus": Global.player.get_node("RLeg/RThigh/RCrusPivot/RCrus"),
	"RFoot": Global.player.get_node("RLeg/RThigh/RCrusPivot/RCrus/RFootPivot/RFoot"),
}

var LimbDisplayNames: Dictionary = {
	"Head": "Head",
	"Neck": "Neck",
	"Thorax": "Thorax",
	"Abdomen": "Abdomen",
	"LUpperArm": "Left Upper Arm",
	"LForearm":"Left Forearm",
	"LHand": "Left Hand",
	"RUpperArm": "Right Upper Arm",
	"RForearm": "Right Forearm",
	"RHand": "Right Hand",
	"LThigh": "Left Thigh",
	"LCrus": "Left Crus",
	"LFoot": "Left Foot",
	"RThigh": "Right Thigh",
	"RCrus": "Right Crus",
	"RFoot": "Right Foot",
}

@onready var Heart = $Body/Thorax/Heart
@onready var healthCtl = Global.player.healthCtl

const sfx_heartBeat = preload("res://assets/audio/sfx/player/heart_thump.ogg")
const sfx_ECG = preload("res://assets/audio/sfx/player/ECG.wav")
const sfx_ECG_loop = preload("res://assets/audio/sfx/player/ECG_loop.wav")
const sfx_menu_open = preload("res://assets/audio/sfx/ui/health_menu_open.ogg")
const sfx_menu_close = preload("res://assets/audio/sfx/ui/health_menu_close.ogg")

var ap_ecg = AudioStreamPlayer.new()
var limbposs = {}

func _ready() -> void:
	visible = false
	ap_ecg.volume_db = -45
	ap_ecg.stream = sfx_ECG
	healthCtl.HeartBeat.connect(_HeartBeat)
	get_tree().current_scene.call_deferred("add_child", ap_ecg)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("healthmenu"):
		if not visible:
			if Global.player.is_input_enabled():
				visible = true
				Global.player.set_input_lock("healthmenu", true)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				playsound(sfx_menu_open)
				if healthCtl.heartRate < 1:
					ap_ecg.stream = sfx_ECG_loop
					ap_ecg.play()
		elif visible:
			if Global.player.input_lock_reasons.has("healthmenu") and Global.player.input_lock_reasons.size() < 2:
				visible = false
				Global.player.set_input_lock("healthmenu", false)
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				playsound(sfx_menu_close)
				ap_ecg.playing = false

	if visible:
		handle_tooltips()

		lung_anim(delta)
		scale.x = lerp(scale.x, 1.0, 0.4)
		if scale.x > 0.9:
			scale.y = lerp(scale.y, 1.0, 0.4)
		Heart.scale = lerp(Heart.scale, Vector2(1.0, 1.0), 0.2)
		if healthCtl.heartRate < 1:
			$Panel/ECG/Gradient.position.x += 2
			$Panel/ECG.texture = preload("res://assets/textures/ui/ecg_flat.png")
			if $Panel/ECG/Gradient.position.x > 60:
				$Panel/ECG/Gradient.position.x = -120
		else:
			$Panel/ECG/Gradient.position.x += 3 * healthCtl.heartRate / 60
			$Panel/ECG.texture = preload("res://assets/textures/ui/ecg.png")
		if healthCtl.heartRate > 1:
			$Panel/ECG.scale.y = healthCtl.bloodOxygen
		Heart.get_theme_stylebox("panel").skew = Heart.get_theme_stylebox("panel").skew.lerp(Vector2.ZERO, 0.2)
		$Panel/VBoxContainer/Brain/VBoxContainer/ConsciousnessLabel.text = "Conc: " + str(int(round(healthCtl.consciousness * 100))) + "%"
		$Panel/VBoxContainer/Brain/VBoxContainer/BrainHealthLabel.text = "Int: " + str(int(round(healthCtl.brainHealth * 100))) + "%"
		$Panel/VBoxContainer/Heart/BPMLabel.text = str(int(round(healthCtl.heartRate))) + " BPM"
		$Panel/VBoxContainer/Blood/VBoxContainer/SPO2Label.text = "SPO2: " + str(int(round(healthCtl.bloodOxygen * 100))) + "%"
		$Panel/VBoxContainer/WorkLabel.text = "Work: " + str(int(round(healthCtl.physicalWork * 100))) + "%"
		$Panel/VBoxContainer/StaminaLabel.text = "Stamina: " + str(int(round(healthCtl.stamina * 100))) + "%"
		$Panel/VBoxContainer/Blood/VBoxContainer/BloodVolumeLabel.text = str(snapped(healthCtl.bloodVolume / 1000, 0.01)) + " L"
		$Panel/VBoxContainer/PainLabel.text = "Pain: " + str(int(round(healthCtl.get_limb_all("pain").values().max() * 100))) + "%"
		var bleedRate = healthCtl.get_limb_total("bleedingRate")
		if bleedRate > 0:
			$Panel/VBoxContainer/Blood/VBoxContainer/BleedingRateLabel.text = str(snapped((healthCtl.get_limb_total("bleedingRate") / 1000) * 60, 0.01)) + " L/m"
		else:
			$Panel/VBoxContainer/Blood/VBoxContainer/BleedingRateLabel.text = ""

		update_limbs()

	else:
		scale = Vector2(0.0, 0.1)

func _HeartBeat():
	Heart.scale = Vector2(1.2, 1.2)
	Heart.get_theme_stylebox("panel").skew = Vector2(0, randf_range(-0.25, 0.25))
	$Panel/ECG/Gradient.position.x = -120
	if visible and not healthCtl.consciousness <= healthCtl.unconsciousThreshold:
		playsound(sfx_heartBeat)
		ap_ecg.play()

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.play()
	await ap.finished
	ap.queue_free()

var breathing_cycle: bool = false # true = breathing in
var breathe_timer: float = 0.0
func lung_anim(delta):
	if healthCtl.organs["LLung"]:
		$Body/Thorax/LLung.scale = lerp($Body/Thorax/LLung.scale,
			Vector2(1.0, 1.0) if breathing_cycle else Vector2(0.7, 0.7), 0.01)
	else:
		$Body/Thorax/LLung.modulate = lerp($Body/Thorax/LLung.modulate, Color(1, 0.5, 0.5), 0.05)
	if healthCtl.organs["RLung"]:
		$Body/Thorax/RLung.scale = lerp($Body/Thorax/LLung.scale,
			Vector2(1.0, 1.0) if breathing_cycle else Vector2(0.7, 0.7), 0.01)
	else:
		$Body/Thorax/RLung.modulate = lerp($Body/Thorax/RLung.modulate, Color(1, 0.5, 0.5), 0.05)

	breathe_timer += delta
	if breathe_timer > 60.0 / healthCtl.breathingRate:
		breathing_cycle = !breathing_cycle
		breathe_timer = 0.0

func check_tooltip(node: Control, tt_title: String, tt_desc: String=""):
	if node.get_global_rect().has_point(get_local_mouse_position()):
		Global.playerGUI.tooltip.request_tooltip(tt_title, tt_desc)

func limb_tooltip(limb: Control):
	check_tooltip(limb, LimbDisplayNames[limb.name], 
	"Muscle Health: %s%%\nSkin Health: %s%%\nBlood Loss Rate: %s L/m\nPain: %s%%" % 
	[str(int(round(PhysicalLimbs[limb.name].muscleHealth * 100))), str(int(round(PhysicalLimbs[limb.name].skinHealth * 100))), str(snapped((PhysicalLimbs[limb.name].bleedingRate / 1000) * 60, 0.01)), str(int(round(PhysicalLimbs[limb.name].pain * 100)))])

func handle_tooltips():
	check_tooltip($Panel/VBoxContainer/Brain/VBoxContainer/BrainHealthLabel, "Brain Integrity (%)")
	check_tooltip($Panel/VBoxContainer/Brain/VBoxContainer/ConsciousnessLabel, "Consciousness (%)")
	check_tooltip($Panel/VBoxContainer/Heart/BPMLabel, "Heart Rate (Beats/min)")
	check_tooltip($Panel/VBoxContainer/Blood/VBoxContainer/BloodVolumeLabel, "Blood Volume (Liters)")
	check_tooltip($Panel/VBoxContainer/Blood/VBoxContainer/SPO2Label, "Blood Oxygen (%)")
	check_tooltip($Panel/VBoxContainer/Blood/VBoxContainer/BleedingRateLabel, "Total Blood Loss Rate (Liters/min)")
	check_tooltip($Panel/VBoxContainer/WorkLabel, "Physical Work (%)")
	check_tooltip($Panel/VBoxContainer/StaminaLabel, "Stamina (%)")
	check_tooltip($Panel/ECG, "Electrocardiogram (ECG)")
	check_tooltip($Body/Thorax/Heart, "Heart")
	check_tooltip($Body/Thorax/LLung, "Left Lung")
	check_tooltip($Body/Thorax/RLung, "Right Lung")
	check_tooltip($Panel/VBoxContainer/PainLabel, "Max Pain (%)")

	limb_tooltip($Body/Head)
	limb_tooltip($Body/Neck)
	if (
		not $Body/Thorax/Heart.get_global_rect().has_point(get_local_mouse_position()) and 
		not $Body/Thorax/LLung.get_global_rect().has_point(get_local_mouse_position()) and
		not $Body/Thorax/RLung.get_global_rect().has_point(get_local_mouse_position())
	):
		limb_tooltip($Body/Thorax)
	limb_tooltip($Body/Abdomen)
	limb_tooltip($Body/LUpperArm)
	limb_tooltip($Body/LForearm)
	limb_tooltip($Body/LHand)
	limb_tooltip($Body/RUpperArm)
	limb_tooltip($Body/RForearm)
	limb_tooltip($Body/RHand)
	limb_tooltip($Body/LThigh)
	limb_tooltip($Body/LCrus)
	limb_tooltip($Body/LFoot)
	limb_tooltip($Body/RThigh)
	limb_tooltip($Body/RCrus)
	limb_tooltip($Body/RFoot)

func update_limbs():
	for limb in Limbs.keys():
		Limbs[limb].pain = PhysicalLimbs[limb].pain
		Limbs[limb].muscleHealth = PhysicalLimbs[limb].muscleHealth
		Limbs[limb].skinHealth = PhysicalLimbs[limb].skinHealth 
