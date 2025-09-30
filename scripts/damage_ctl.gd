extends Node

@onready var Limbs: Dictionary = {
	"Head": $"../Head",
	"Neck": $"../Neck",
	"Thorax": $"../Thorax",
	"Abdomen": $"../Abdomen",
	"LUpperArm": $"../LArm/LUpperArm",
	"LForearm": $"../LArm/LUpperArm/LForearmPivot/LForearm",
	"LHand": $"../LArm/LUpperArm/LForearmPivot/LForearm/LHandPivot/LHand",
	"RUpperArm": $"../RArm/RUpperArm",
	"RForearm": $"../RArm/RUpperArm/RForearmPivot/RForearm",
	"RHand": $"../RArm/RUpperArm/RForearmPivot/RForearm/RHandPivot/RHand",
	"LThigh": $"../LLeg/LThigh",
	"LCrus": $"../LLeg/LThigh/LCrusPivot/LCrus",
	"LFoot": $"../LLeg/LThigh/LCrusPivot/LCrus/LFootPivot/LFoot",
	"RThigh": $"../RLeg/RThigh",
	"RCrus": $"../RLeg/RThigh/RCrusPivot/RCrus",
	"RFoot": $"../RLeg/RThigh/RCrusPivot/RCrus/RFootPivot/RFoot",
}

var afflictions: Dictionary = {
	#"cardiacArrest": {"intensity": 1.0}
}

var organs: Dictionary = { # true = lung working
	"Heart": true,
	"LLung": true,
	"RLung": true
}

var bloodOxygen: float = 1.0
var brainHealth: float = 1.0
var consciousness: float = 1.0
var bloodVolume: float = 5000 # ml
var adrenaline: float = 0.0
var physicalWork: float = 0.05
var stamina: float = 1.0
var heartRate: float = 80.0 # bpm
var maxHR: float = 200
var restHR: float = 80
var targetHR: float = 80
var breathingRate: float = 90
var maxBR: float = 200
var restBR: float = 10
var opioidAmount: float = 0.0
const oxygenUseRate: float = 0.15
const brainOxygenThreshold: float = 0.10
const conscOxygenTheshold: float = 0.90
const conscStaminaThreshold: float = 0.30
const unconsciousThreshold: float = 0.25

var beatTimer: float = 0.0

const sfx_heartBeatAmbient = preload("res://assets/audio/sfx/player/heart_amb.wav")

signal HeartBeat
signal affliction_added
signal affliction_changed

func _process(delta: float) -> void:
	if not "cardiacArrest" in afflictions:
		beatTimer += delta
		var beatInterval = 60.0 / heartRate
		if beatTimer >= beatInterval:
			HeartBeat.emit()
			if not consciousness <= unconsciousThreshold:
				playsound(sfx_heartBeatAmbient, lerp(-20, 15, 1.0 - min(stamina, bloodOxygen)))
			var bloodFraction = bloodVolume / 5000.0
			bloodOxygen += 0.025 * bloodFraction
			beatTimer -= beatInterval
	else:
		beatTimer = 0.0
		heartRate = 0
		Limbs["Thorax"].pain += 0.0001

	targetHR = restHR + (physicalWork + adrenaline) * (maxHR - restHR) * 1.3
	targetHR += (get_limb_total("pain") / 16) * 60
	targetHR = clamp(targetHR, 0.0, maxHR)
	var targetBR = (targetHR + adrenaline * 10) * 0.4
	if bloodOxygen < 0.8:
		targetHR += (0.8 - bloodOxygen) * 60.0
	if stamina < 0.5:
		targetHR += (0.5 - stamina) * 60.0

	heartRate = lerp(heartRate, targetHR, 0.0025)
	breathingRate = lerp(breathingRate, targetBR, 0.0025)

	bloodOxygen -= physicalWork * oxygenUseRate * delta
	bloodOxygen = clamp(bloodOxygen, 0.0, bloodVolume / 5000.0)

	var bloodLossRate = get_limb_total("bleedingRate")
	bloodVolume -= bloodLossRate * delta
	bloodVolume = clamp(bloodVolume, 0.0, 5000.0)

	physicalWork = lerp(physicalWork, 0.05, 0.015)
	physicalWork = clamp(physicalWork, 0.0, 1.0)
	
	stamina -= physicalWork / 250

	physicalWork += adrenaline / 100

	if physicalWork < 0.1:
		stamina += (1.0 - stamina) * 0.3 * delta

	stamina = clamp(stamina, 0.0001, min(consciousness, 1.0))

	adrenaline = lerp(adrenaline, 0.0, 0.0025)

	if heartRate < 40:
		adrenaline += 0.001

	adrenaline = clamp(adrenaline, 0.0, 1.0)

	consciousness -= (conscOxygenTheshold - bloodOxygen) * 0.15 * delta

	consciousness = clamp(consciousness, 0.0, min(bloodOxygen, brainHealth, 1.0))
	if consciousness <= unconsciousThreshold:
		Engine.time_scale = 5.0
		Global.player.set_input_lock("unconscious", true)
	else:
		Engine.time_scale = 1.0
		Global.player.set_input_lock("unconscious", false)

	if bloodOxygen < brainOxygenThreshold:
		brainHealth -= (brainOxygenThreshold - bloodOxygen) * 0.05 * delta

	if bloodVolume <= 2500:
		brainHealth -= (2500 - bloodVolume) * 0.00002 * delta

	brainHealth = clamp(brainHealth, 0.0, 1.0)

	if brainHealth <= 0.15:
		add_affliction("cardiacArrest", 1.0)

	if heartRate <= 0.0:
		add_affliction("cardiacArrest", 1.0)

	if brainHealth <= 0.0:
		add_affliction("brainDead", 1.0)

	if bloodLossRate > 0.0:
		set_affliction("bleeding", bloodLossRate / 16)

	if bloodVolume < 4500:
		set_affliction("hypovolemia", (4500 - bloodVolume) / 5000)

	if Limbs["Head"].pain > 0.05:
		set_affliction("headache", Limbs["Head"].pain)
	else:
		afflictions.erase("headache")

	if stamina <= 0.05:
		set_affliction("incapacitated", 1.0)
	else:
		afflictions.erase("incapacitated")

	if Global.player.hearing_damage > 0.0:
		set_affliction("hearingDamage", Global.player.hearing_damage * 100)
	else:
		afflictions.erase("hearingDamage")

	if brainHealth < 0.9:
		set_affliction("brainDamage", 1.0 - brainHealth)
	else:
		afflictions.erase("brainDamage")

	if afflictions.has("bleeding"):
		if bloodLossRate < 0.001:
			afflictions.erase("bleeding")

	if brainHealth <= 0.0 and not Global.player.dead:
		Global.player.die()

	for affliction in afflictions.keys():
		afflictions[affliction]["intensity"] = clampf(afflictions[affliction]["intensity"], 0.0, 1.0)
		if afflictions[affliction]["intensity"] <= 0.0:
			afflictions.erase(affliction)

func playsound(stream: AudioStream, volume: float=0):
	var ap = AudioStreamPlayer.new()
	ap.volume_db = volume
	get_tree().current_scene.add_child(ap)
	ap.stream = stream
	ap.play()
	await ap.finished
	ap.queue_free()

func get_limb_total(value: String):
	var total: float = 0.0
	for limb in Limbs.values():
		if limb is Dictionary:
			for limbSection in limb.values():
				total += limbSection.get(value)
		else:
			total += limb.get(value)

	return total

func get_limb_all(value: String):
	var total: Dictionary = {}
	for limb in Limbs.values():
		if limb is Dictionary:
			for limbSection in limb.values():
				total[limbSection] = limbSection.get(value)
		else:
			total[limb] = limb.get(value)

	return total

func add_affliction(aff_name: String, intensity: float=1):
	if afflictions.has(aff_name):
		afflictions[aff_name]["intensity"] = afflictions[aff_name]["intensity"] + intensity
		affliction_changed.emit(afflictions)
	else:
		afflictions[aff_name] = {
			"intensity": intensity
		}
		affliction_added.emit(afflictions)

func set_affliction(aff_name: String, intensity: float=1):
	if afflictions.has(aff_name):
		afflictions[aff_name]["intensity"] = intensity
		affliction_changed.emit(afflictions)
	else:
		afflictions[aff_name] = {
			"intensity": intensity
		}
		affliction_added.emit(afflictions)
