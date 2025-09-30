extends Control

@onready var Title := $VBoxContainer/Title
@onready var Description := $VBoxContainer/Description

var item_descs := {
	"Oxycodone": "An opioid analgesic (painkiller) used to treat moderate to severe pain.",
	"Procoagulant": "A serum that promotes blood clotting, slowing down bleeding across the body.",
	"Adrenaline": "Quickly increases heart rate and awareness."
}

var timer: float = 0.0
func _process(delta: float) -> void:
	if Global.player.inspecting and Global.player.inventory.items["RHand"]:
		timer += delta
		if timer > 0.5:
			Title.text = Global.player.inventory.items["RHand"].name
			Description.text = item_descs[Global.player.inventory.items["RHand"].name]
			modulate.a = lerp(modulate.a, 1.0, 0.2)
	else:
		timer = 0.0
		modulate.a = lerp(modulate.a, 0.0, 0.4)
