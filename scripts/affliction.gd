extends Control

@onready var BG: TextureRect = $BG

var base_pos := Vector2.ZERO

var aff_icons := {
	"cardiacArrest": preload("res://assets/textures/ui/afflictions/cardiacarrest.png"),
	"brainDead": preload("res://assets/textures/ui/afflictions/braindead.png"),
	"bleeding": preload("res://assets/textures/ui/afflictions/bleeding.png"),
	"heartPierced": preload("res://assets/textures/ui/afflictions/heartpierced.png"),
	"lungCollapsed": preload("res://assets/textures/ui/afflictions/collapsed_lung.png"),
	"respiratoryFailure": preload("res://assets/textures/ui/afflictions/respiratoryfailure.png"),
	"hypovolemia": preload("res://assets/textures/ui/afflictions/hypovolemia.png"),
	"headache": preload("res://assets/textures/ui/afflictions/headache.png"),
	"incapacitated": preload("res://assets/textures/ui/afflictions/incapacitated.png"),
	"hearingDamage": preload("res://assets/textures/ui/afflictions/hearingDamage.png"),
	"brainDamage": preload("res://assets/textures/ui/afflictions/braindamage.png")
}

var aff_names := {
	"cardiacArrest": "Cardiac Arrest",
	"brainDead": "Brain Dead",
	"bleeding1": "Minor Bleeding",
	"bleeding2": "Bleeding",
	"bleeding3": "Heavy Bleeding",
	"heartPierced": "Heart Pierced",
	"lungCollapsed": "Collapsed Lung",
	"respiratoryFailure": "Respiratory Failure",
	"hypovolemia": "Hypovolemia",
	"headache1": "Headache",
	"headache2": "Severe Headache",
	"incapacitated": "Incapacitated",
	"hearingDamage1": "Tinnitus",
	"hearingDamage2": "Hearing Damage",
	"hearingDamage3": "Severe Hearing Damageh",
	"brainDamage": "Brain Damage"
}

var aff_descs := {
	"cardiacArrest": "Heart has stopped beating. Death imminent.",
	"brainDead": "Brain no longer functioning; Deceased.",
	"bleeding1": "Losing a little blood. Shouldn't be lethal.",
	"bleeding2": "Losing blood. May be lethal without treatment",
	"bleeding3": "Quickly losing blood. Will be lethal without treatment",
	"heartPierced": "A bullet penetrated your heart.",
	"lungCollapsed": "A bullet penetrated one of your lungs.",
	"respiratoryFailure": "Your lungs are not working.",
	"hypovolemia": "You have lost a significant amount of blood.",
	"headache1": "Your head hurts.",
	"headache2": "Your head is throbbing in agonizing pain.",
	"incapacitated": "You're unable to move.",
	"hearingDamage1": "Your ears are ringing.",
	"hearingDamage2": "You can't hear higher frequencies very well.",
	"hearingDamage3": "You can barely hear anything.",
	"brainDamage": "..."
}

var aff_name: String = ""

func _ready() -> void:
	get_parent().resize.connect(_set_base_pos)
	if aff_name in aff_icons:
		$Icon.texture = aff_icons[aff_name]

func _process(_delta: float) -> void:
	if Global.player.healthCtl.afflictions.has(aff_name):
		var intensity = Global.player.healthCtl.afflictions[aff_name]["intensity"]
		var tooltip_desc := ""
		var tooltip_title := ""
		if aff_name == "bleeding":
			if intensity > 0.25:
				tooltip_title = aff_names["bleeding3"]
				tooltip_desc = aff_descs["bleeding3"]
			elif intensity > 0.25:
				tooltip_title = aff_names["bleeding2"]
				tooltip_desc = aff_descs["bleeding2"]
			else:
				tooltip_title = aff_names["bleeding1"]
				tooltip_desc = aff_descs["bleeding1"]
		elif aff_name == "headache":
			if intensity > 0.5:
				tooltip_title = aff_names["headache2"]
				tooltip_desc = aff_descs["headache2"]
			else:
				tooltip_title = aff_names["headache1"]
				tooltip_desc = aff_descs["headache1"]
		elif aff_name == "hearingDamage":
			if intensity > 0.6:
				tooltip_title = aff_names["hearingDamage3"]
				tooltip_desc = aff_descs["hearingDamage3"]
			elif intensity > 0.3:
				tooltip_title = aff_names["hearingDamage2"]
				tooltip_desc = aff_descs["hearingDamage2"]
			else:
				tooltip_title = aff_names["hearingDamage1"]
				tooltip_desc = aff_descs["hearingDamage1"]
		else:
			tooltip_title = aff_names[aff_name]
			tooltip_desc = aff_descs[aff_name]

		if Rect2(Vector2(), BG.size).has_point(get_local_mouse_position()):
			Global.playerGUI.tooltip.request_tooltip(tooltip_title, tooltip_desc)

		if intensity > 0.5:
			position = base_pos + Vector2(
				0, 
				randf_range(-1, 1)
				) * intensity

		var color = Color(
			1.0, 
			1.0 - intensity,
			1.0 - intensity,
			1.0)
		BG.modulate = color
	else:
		queue_free()

func _set_base_pos():
	base_pos.x = position.x
