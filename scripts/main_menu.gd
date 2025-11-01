extends Control

@onready var playButton: MenuButton = $Main/VBoxContainer/PlayButton
@onready var cheatsButton: MenuButton = $Main/VBoxContainer/CheatsButton

@onready var disclOkButton: Button = $Disclaimer/VBoxContainer/OkButton
@onready var disclNoButton: Button = $Disclaimer/VBoxContainer/NoButton

func _ready() -> void:
	Global.playsound(preload("res://assets/audio/sfx/ui/ui_tab.ogg"))
	playButton.get_popup().index_pressed.connect(_playButton_pressed)
	cheatsButton.get_popup().index_pressed.connect(_cheatsButton_pressed)
	cheatsButton.about_to_popup.connect(_click)
	playButton.about_to_popup.connect(_click)
	disclOkButton.pressed.connect(_disclOkButton_pressed)
	disclNoButton.pressed.connect(quit)
	$Main/VBoxContainer/QuitButton.pressed.connect(quit)
	if Global.settings.get_value("Misc", "accepted_disclaimer", false):
		_disclOkButton_pressed()

	var popup = cheatsButton.get_popup()

	for idx in Global.settings.get_section_keys("Dev_Tools"):
		popup.set_item_checked(int(idx), Global.settings.get_value("Dev_Tools", idx, false))

		apply_dev_tool(int(idx))

func _quitButton_pressed():
	get_tree().quit()

func _disclOkButton_pressed():
	$AudioStreamPlayer.play()
	Global.playsound(preload("res://assets/audio/sfx/ui/ui_popup.ogg"))
	$Main.show()
	$Disclaimer.hide()
	Global.set_setting("Misc", "accepted_disclaimer", true)

func quit():
	get_tree().quit()

func _playButton_pressed(idx: int):
	match idx:
		0:
			Global.playsound(preload("res://assets/audio/sfx/ui/ui_tab.ogg"))
			$Main/Label.text = "LOADING..."
			await get_tree().create_timer(0.05).timeout
			Global.is_initialized = false
			get_tree().change_scene_to_file("res://scenes/main.tscn")

func _cheatsButton_pressed(idx: int):
	var popup = cheatsButton.get_popup()
	popup.set_item_checked(idx, !popup.is_item_checked(idx))
	
	Global.set_setting("Dev_Tools", str(idx), popup.is_item_checked(idx))
	
	if popup.is_item_checked(idx):
		Global.playsound(preload("res://assets/audio/sfx/ui/ui_enable.ogg"))
	else:
		Global.playsound(preload("res://assets/audio/sfx/ui/ui_disable.ogg"))

	apply_dev_tool(idx)

func apply_dev_tool(idx: int):
	var popup = cheatsButton.get_popup()

	match idx:
		0:
			Global.godmode = popup.is_item_checked(idx)
		1:
			Global.infinite_ammo = popup.is_item_checked(idx)
		2:
			Global.console_enabled = popup.is_item_checked(idx)
		3:
			Global.quiet_guns = popup.is_item_checked(idx)
		4:
			Global.hand_shake_enabled = !popup.is_item_checked(idx)
		5:
			Global.no_recoil = popup.is_item_checked(idx)

func _click():
	Global.playsound(preload("res://assets/audio/sfx/ui/ui_popup.ogg"))
