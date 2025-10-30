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

func _quitButton_pressed():
	get_tree().quit()

func _disclOkButton_pressed():
	$AudioStreamPlayer.play()
	Global.playsound(preload("res://assets/audio/sfx/ui/ui_popup.ogg"))
	$Main.show()
	$Disclaimer.hide()

func quit():
	get_tree().quit()

func _playButton_pressed(idx: int):
	match idx:
		0:
			Global.playsound(preload("res://assets/audio/sfx/ui/ui_tab.ogg"))
			$Label.text = "LOADING..."
			await get_tree().create_timer(0.05).timeout
			Global.is_initialized = false
			get_tree().change_scene_to_file("res://scenes/main.tscn")

func _cheatsButton_pressed(idx: int):

	var popup = cheatsButton.get_popup()
	popup.set_item_checked(idx, !popup.is_item_checked(idx))
	if popup.is_item_checked(idx):
		Global.playsound(preload("res://assets/audio/sfx/ui/ui_enable.ogg"))
	else:
		Global.playsound(preload("res://assets/audio/sfx/ui/ui_disable.ogg"))
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
