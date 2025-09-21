extends Control

var BG_lethal := preload("res://assets/textures/ui/afflictions/affliction_bg_lethal.png")
var BG_normal := preload("res://assets/textures/ui/afflictions/affliction_bg.png")

var aff_icons := {
	"cardiacArrest": preload("res://assets/textures/ui/afflictions/cardiacarrest.png"),
	"brainDead": preload("res://assets/textures/ui/afflictions/braindead.png"),
	"bleeding": preload("res://assets/textures/ui/afflictions/bleeding.png")
}

var aff_names := {
	"cardiacArrest": "Cardiac Arrest",
	"brainDead": "Brain Dead",
	"bleeding": "Bleeding"
}

var aff_descs := {
	"cardiacArrest": "Heart not beating.",
	"brainDead": "Brain no longer functioning; Deceased.",
	"bleeding": "Losing blood."
}

var aff_name: String = ""

func _ready() -> void:
	if aff_name in aff_icons:
		$Icon.texture = aff_icons[aff_name]

func _process(_delta: float) -> void:
	$BG.texture = BG_lethal if Global.player.healthCtl.afflictions[aff_name]["intensity"] >= 0.5 else BG_normal
	if Rect2(Vector2(), $BG.size).has_point(get_local_mouse_position()):
		Global.playerGUI.tooltip.request_tooltip(aff_names[aff_name], aff_descs[aff_name])
