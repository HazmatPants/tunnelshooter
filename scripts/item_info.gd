extends Control

@onready var Title := $VBoxContainer/Title
@onready var Description := $VBoxContainer/Description

var item_names := {
	"BloodBag": "Blood Bag",
	"KCl": "Potassium Chloride",
	
	"SS320" : "SS-320",
}

var item_descs := {
	"Oxycodone": "An opioid analgesic (painkiller) used to treat moderate pain. Low overdose risk.",
	"Procoagulant": "A serum that promotes blood clotting, slowing down bleeding across the body.",
	"Adrenaline": "Quickly increases heart rate and awareness.",
	"BloodBag": "Holds 750 ml of blood.",
	"Morphine": "A strong opioid analgesic (painkiller) used to treat severe pain. Moderate overdose risk (90%).",
	"Methamphetamine": "A powerful stimulant that suppresses fatigue and pain.",
	"KCl": "Induces cardiac arrest, ultimately resulting in death.",
	"Fentanyl": "A VERY potent opioid analgesic (painkiller), 100 times stronger than morphine. Extreme overdose risk (20%).",
	"Naloxone": "An opioid antagonist, used to treat the effects of overdose and withdrawal.",

	"SS320": "A semi-automatic striker-fired handgun.",

}

var timer: float = 0.0
func _process(delta: float) -> void:
	if Global.player.inspecting and Global.player.inventory.items["RHand"]:
		timer += delta
		if timer > 0.5:
			if Global.player.inventory.items["RHand"].name in item_names:
				Title.text = item_names[Global.player.inventory.items["RHand"].name]
			else:
				Title.text = Global.player.inventory.items["RHand"].name
			Description.text = item_descs[Global.player.inventory.items["RHand"].name] + "\n\n%s%% Condition" % str(int(Global.player.inventory.items["RHand"].condition * 100.0))
			modulate.a = lerp(modulate.a, 1.0, 0.2)
	else:
		timer = 0.0
		modulate.a = lerp(modulate.a, 0.0, 0.4)
