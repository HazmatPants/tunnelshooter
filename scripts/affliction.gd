extends Control

var BG_lethal := preload("res://assets/textures/ui/afflictions/affliction_bg_lethal.png")
var BG_normal := preload("res://assets/textures/ui/afflictions/affliction_bg.png")

var aff_icons := {
	"cardiacArrest": preload("res://assets/textures/ui/afflictions/cardiacarrest.png"),
	"brainDead": preload("res://assets/textures/ui/afflictions/braindead.png"),
	"bleeding": preload("res://assets/textures/ui/afflictions/bleeding.png"),
	"heartPierced": preload("res://assets/textures/ui/afflictions/heartpierced.png"),
	"lungCollapsed": preload("res://assets/textures/ui/afflictions/collapsed_lung.png"),
	"respiratoryFailure": preload("res://assets/textures/ui/afflictions/respiratoryfailure.png"),
	"hypovolemia": preload("res://assets/textures/ui/afflictions/hypovolemia.png")
}

var aff_names := {
	"cardiacArrest": "Cardiac Arrest",
	"brainDead": "Brain Dead",
	"bleeding1": "Bleeding",
	"bleeding2": "Heavy Bleeding",
	"heartPierced": "Heart Pierced",
	"lungCollapsed": "Collapsed Lung",
	"respiratoryFailure": "Respiratory Failure",
	"hypovolemia": "Hypovolemia"
}

var aff_descs := {
	"cardiacArrest": "Heart has stopped beating. Death imminent.",
	"brainDead": "Brain no longer functioning; Deceased.",
	"bleeding1": "Losing a little blood. Shouldn't be lethal.",
	"bleeding2": "Losing blood. May be lethal without treatment",
	"heartPierced": "A bullet penetrated your heart.",
	"lungCollapsed": "A bullet penetrated one of your lungs.",
	"respiratoryFailure": "Your lungs are not working.",
	"hypovolemia": "You have lost a significant amount of blood."
}

var aff_name: String = ""

func _ready() -> void:
	$BG.texture = BG_normal
	if aff_name in aff_icons:
		$Icon.texture = aff_icons[aff_name]

func _process(_delta: float) -> void:
	var intensity = Global.player.healthCtl.afflictions[aff_name]["intensity"]
	if Global.player.healthCtl.afflictions.has(aff_name):
		if aff_name.begins_with("bleeding"):
			if Rect2(Vector2(), $BG.size).has_point(get_local_mouse_position()):
				if intensity > 0.1:
					Global.playerGUI.tooltip.request_tooltip(aff_names["bleeding2"], aff_descs["bleeding2"])
				else:
					Global.playerGUI.tooltip.request_tooltip(aff_names["bleeding1"], aff_descs["bleeding1"])
		else:
			if Rect2(Vector2(), $BG.size).has_point(get_local_mouse_position()):
				Global.playerGUI.tooltip.request_tooltip(aff_names[aff_name], aff_descs[aff_name])
			call_deferred("_update_texture")
	else:
		queue_free()

func _update_texture():
	var intensity = Global.player.healthCtl.afflictions[aff_name]["intensity"]
	$BG.texture = BG_lethal if intensity >= 0.5 else BG_normal
