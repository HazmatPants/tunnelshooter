extends Control

@onready var Title := $VBoxContainer/Title
@onready var Description := $VBoxContainer/Description

var item_names := {
	"Oxycodone": "Oxycodone",
	"Procoagulant": "Procoagulant",
	"Adrenaline": "Adrenaline",
	"BloodBag": "Blood Bag",
	"Morphine": "Morphine",
	"Methamphetamine": "Methamphetamine"
}

var item_descs := {
	"Oxycodone": "An opioid analgesic (painkiller) used to treat moderate to severe pain.",
	"Procoagulant": "A serum that promotes blood clotting, slowing down bleeding across the body.",
	"Adrenaline": "Quickly increases heart rate and awareness.",
	"BloodBag": "Holds 750 ml of blood.",
	"Morphine": "A very strong opioid analgesic (painkiller) used to treat severe pain. High overdose risk.",
	"Methamphetamine": "A powerful stimulant that suppresses fatigue and pain."
}

var timer: float = 0.0
func _process(delta: float) -> void:
	if Global.player.inspecting and Global.player.inventory.items["RHand"]:
		timer += delta
		if timer > 0.5:
			Title.text = item_names[Global.player.inventory.items["RHand"].name]
			Description.text = item_descs[Global.player.inventory.items["RHand"].name] + "\n\n%s%% Left" % str(int(Global.player.inventory.items["RHand"].condition * 100.0))
			modulate.a = lerp(modulate.a, 1.0, 0.2)
	else:
		timer = 0.0
		modulate.a = lerp(modulate.a, 0.0, 0.4)
