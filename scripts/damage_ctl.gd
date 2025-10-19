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

var bloodstream := {
	
}

var lifesupport: float = 0.0
var bloodOxygen: float = 1.0
var internalBleeding: float = 0.0
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
var stimAmount: float = 0.0
var bloodClotSpeed: float = 0.003
const oxygenUseRate: float = 0.15
const brainOxygenThreshold: float = 0.10
const conscOxygenTheshold: float = 0.90
const conscStaminaThreshold: float = 0.30
const unconsciousThreshold: float = 0.05

var beatTimer: float = 0.0

const sfx_heartBeatAmbient = preload("res://assets/audio/sfx/player/heart_amb.wav")
const sfx_heartBeatAmbientHeavy = preload("res://assets/audio/sfx/player/heart_thump_heavy.ogg")

signal HeartBeat
signal affliction_added
signal affliction_changed

var initialized: bool = false

func _ready() -> void:
	await Global.initialized
	Global.request_ready()
	initialized = true

func _process(delta: float) -> void:
	if not initialized:
		return
	if not "cardiacArrest" in afflictions:
		beatTimer += delta
		var beatInterval = 60.0 / heartRate
		if beatTimer >= beatInterval:
			HeartBeat.emit()
			if not consciousness <= unconsciousThreshold:
				if heartRate >= 110:
					playsound(sfx_heartBeatAmbientHeavy, lerp(-20, 15, max(1.0 - min(stamina, bloodOxygen), heartRate / 480)))
				elif heartRate <= 60:
					playsound(sfx_heartBeatAmbientHeavy, lerp(-20, 15, max(1.0 - min(stamina, bloodOxygen), 1.0 - heartRate / 120)))
				else:
					playsound(sfx_heartBeatAmbient, lerp(-20, 15, 1.0 - min(stamina, bloodOxygen)))
			var bloodFraction = bloodVolume / 5000.0
			if organs["RLung"] and organs["LLung"]:
				bloodOxygen += 0.025 * bloodFraction
			elif organs["RLung"] or organs["LLung"]:
				bloodOxygen += 0.015 * bloodFraction
			beatTimer -= beatInterval
	else:
		beatTimer = 0.0
		heartRate = 0
		Limbs["Thorax"].pain += 0.0001

	var total_pain = get_limb_total("pain")

	targetHR = restHR + (physicalWork + adrenaline) * (maxHR - restHR) * 1.3
	targetHR += total_pain
	targetHR -= stimAmount * 120
	targetHR -= opioidAmount * 10

	targetHR = clamp(targetHR, 0.0, maxHR)
	var targetBR = (targetHR + adrenaline * 10) * 0.4
	if bloodOxygen < 0.8:
		targetHR += (0.8 - bloodOxygen) * 60.0
	if stamina < 0.5:
		targetHR += (0.5 - stamina) * 60.0

	if heartRate > 200:
		consciousness -= 1 * delta

	if bloodstream.has("KCl"):
		targetHR = 0
		bloodOxygen -= 0.02 * delta
		for limb in Limbs.values():
			limb.muscleHealth -= 0.001 * delta
			limb.pain += 0.001 * delta

	if bloodstream.has("ChloralHydrate"):
		consciousness -= bloodstream["ChloralHydrate"]["amount"] * delta
		bloodstream["ChloralHydrate"]["amount"] -= 0.01 * delta

	heartRate = lerp(heartRate, targetHR, 0.0025)
	breathingRate = lerp(breathingRate, targetBR, 0.0025)

	if lifesupport > 0.0:
		var plss_sfx
		lifesupport -= delta
		bloodOxygen += 0.01
		set_affliction("lifeSupport", 1.0 - lifesupport / 120)
		if not has_node("PLSSSFX"):
			plss_sfx = AudioStreamPlayer.new()
			plss_sfx.name = "PLSSSFX"
			plss_sfx.volume_linear = 0.1
			plss_sfx.autoplay = true
			plss_sfx.stream = preload("res://assets/audio/sfx/items/plss_loop.ogg")
			add_child(plss_sfx)
		else:
			plss_sfx = get_node("PLSSSFX")
	else:
		if has_node("PLSSSFX"):
			get_node("PLSSSFX").queue_free()
		afflictions.erase("lifeSupport")

	bloodOxygen -= physicalWork * oxygenUseRate * delta
	bloodOxygen = clamp(bloodOxygen, 0.0, bloodVolume / 5000.0 if lifesupport <= 0.0 else 1.0)

	var bloodLossRate = get_limb_total("bleedingRate") + internalBleeding
	bloodVolume -= bloodLossRate * delta
	bloodVolume = clamp(bloodVolume, 0.0, 5000.0)

	physicalWork = lerp(physicalWork, 0.05, 0.015)
	physicalWork = clamp(physicalWork, 0.0, 1.0)
	
	stamina -= physicalWork / 250
	stamina -= (total_pain / 16) / 100
	stamina += stimAmount * delta

	if physicalWork < 0.1:
		stamina += (1.0 - stamina) * 0.3 * delta

	stamina = clamp(stamina, 0.0001, min(consciousness, 1.0))

	adrenaline = lerp(adrenaline, 0.0, 0.0005)

	adrenaline = clamp(adrenaline, 0.0, 1.0)

	consciousness -= clampf((conscOxygenTheshold - bloodOxygen) * 0.15 * delta, 0.0, INF)
	consciousness -= (total_pain / 16) / 400

	consciousness += 0.01 * (1.0 + (adrenaline * 10)) * delta

	consciousness = clamp(consciousness, 0.0, min(bloodOxygen, brainHealth, 5.0 - opioidAmount, 1.0))
	if stimAmount > 0.0:
		consciousness += stimAmount * 2

	consciousness = clamp(consciousness, 0.0, 1.0)

	if consciousness <= unconsciousThreshold:
		Engine.time_scale = 10.0
		Global.player.set_input_lock("unconscious", true)
	else:
		Engine.time_scale = 1.0
		Global.player.set_input_lock("unconscious", false)

	if bloodOxygen < brainOxygenThreshold:
		brainHealth -= (brainOxygenThreshold - bloodOxygen) * 0.05 * delta

	bloodClotSpeed = lerp(bloodClotSpeed, 0.003, 0.025 * delta)

	internalBleeding -= bloodClotSpeed * delta

	if bloodVolume <= 2500:
		brainHealth -= (2500 - bloodVolume) * 0.00002 * delta

	brainHealth = clamp(brainHealth, 0.0, 1.0)

	if brainHealth <= 0.15:
		set_affliction("cardiacArrest", 1.0)

	if heartRate <= 10.0:
		set_affliction("cardiacArrest", 1.0)
		Global.cause_of_death = "cardiacarrest"
		if afflictions.has("bradycardia"):
			afflictions.erase("bradycardia")

	if brainHealth <= 0.0:
		add_affliction("brainDead", 1.0)

	if bloodLossRate > 0.0:
		set_affliction("bleeding", bloodLossRate / 16)

	if internalBleeding > 0.0:
		set_affliction("internalBleeding", internalBleeding / 100)
	else:
		afflictions.erase("internalBleeding")

	if bloodVolume < 4700:
		set_affliction("hypovolemia", (4700 - bloodVolume) / 1000)
		Global.cause_of_death = "bloodloss"
	else:
		afflictions.erase("hypovolemia")

	if Limbs["Head"].pain > 0.05:
		set_affliction("headache", Limbs["Head"].pain)
	else:
		afflictions.erase("headache")

	if stamina <= 0.05:
		set_affliction("incapacitated", 1.0)
	else:
		afflictions.erase("incapacitated")

	if heartRate <= 55 and heartRate > 10:
		set_affliction("bradycardia", 1.0 - heartRate / 55)
	else:
		afflictions.erase("bradycardia")

	if Global.player.tinnitus > 0.0:
		set_affliction("hearingDamage", Global.player.tinnitus * 10)
	else:
		afflictions.erase("hearingDamage")

	if brainHealth < 0.9:
		set_affliction("brainDamage", 1.0 - brainHealth)
	else:
		afflictions.erase("brainDamage")

	if afflictions.has("bleeding"):
		if bloodLossRate < 0.001:
			afflictions.erase("bleeding")

	Global.player.viewpunch_velocity += Vector3(
		randf_range(-total_pain, total_pain),
		randf_range(-total_pain, total_pain),
		randf_range(-total_pain, total_pain)
	) * 4

	opioidAmount -= 0.005 * delta
	stimAmount -= 0.005 * delta
	stimAmount = clampf(stimAmount, 0.0, 1.0)

	if opioidAmount > 2.8:
		set_affliction("respiratoryFailure", 1.0)
		Global.cause_of_death = "opioidoverdose"
		organs["LLung"] = false
		organs["RLung"] = false
	else:
		afflictions.erase("respiratoryFailure")
		organs["LLung"] = true
		organs["RLung"] = true

	if brainHealth <= 0.0 and not Global.player.dead:
		Global.player.die()
	
	var max_disloc_amount = get_limb_all("dislocationAmount").values().max()
	if max_disloc_amount > 0.0:
		set_affliction("dislocation", max_disloc_amount)
	else:
		afflictions.erase("dislocation")

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

func get_limb_total(value: String) -> float:
	var total: float = 0.0
	for limb in Limbs.values():
		if limb is Dictionary:
			for limbSection in limb.values():
				total += limbSection.get(value)
		else:
			total += limb.get(value)

	return total

func get_limb_all(value: String) -> Dictionary:
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
		afflictions[aff_name]["intensity"] += intensity
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

func add_to_blood(liq_name: String, amount: float=0.1):
	if bloodstream.has(liq_name):
		bloodstream[liq_name]["amount"] += amount
	else:
		bloodstream[liq_name] = {
			"amount": amount
		}

func is_leg_dislocated() -> bool:
	for limb in Limbs.values():
		if limb.dislocationAmount > 0.0 and limb.isLeg:
			return true
		else:
			continue
	return false
