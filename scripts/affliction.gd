extends Control

var BG_lethal := preload("res://assets/textures/ui/afflictions/affliction_bg_lethal.png")
var BG_normal := preload("res://assets/textures/ui/afflictions/affliction_bg.png")

var aff_icons := {
	"cardiacArrest": preload("res://assets/textures/ui/afflictions/cardiacarrest.png"),
	"brainDead": preload("res://assets/textures/ui/afflictions/braindead.png"),
	"bleeding": preload("res://assets/textures/ui/afflictions/bleeding.png"),
	"heartPierced": preload("res://assets/textures/ui/afflictions/heartpierced.png"),
	"lungCollapsed": preload("res://assets/textures/ui/afflictions/collapsed_lung.png"),
	"respiratoryFailure": preload("res://assets/textures/ui/afflictions/respiratoryfailure.png")
}

var aff_names := {
	"cardiacArrest": "Cardiac Arrest",
	"brainDead": "Brain Dead",
	"bleeding": "Bleeding",
	"heartPierced": "Heart Pierced",
	"lungCollapsed": "Collapsed Lung",
	"respiratoryFailure": "Respiratory Failure"
}

var aff_descs := {
	"cardiacArrest": "Heart not beating.",
	"brainDead": "Brain no longer functioning; Deceased.",
	"bleeding": "Losing blood.",
	"heartPierced": "A bullet penetrated your heart.",
	"lungCollapsed": "A bullet penetrated one of your lungs.",
	"respiratoryFailure": "Your respiratory system is not working."
}

var aff_name: String = ""

func _ready() -> void:
	if aff_name in aff_icons:
		$Icon.texture = aff_icons[aff_name]

func _process(_delta: float) -> void:
	if Rect2(Vector2(), $BG.size).has_point(get_local_mouse_position()):
		Global.playerGUI.tooltip.request_tooltip(aff_names[aff_name], aff_descs[aff_name])
	$BG.texture = BG_lethal if Global.player.healthCtl.afflictions[aff_name]["intensity"] >= 1 else BG_normal
