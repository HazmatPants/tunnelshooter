extends Control

@onready var title = $Panel/VBoxContainer/Title
@onready var description = $Panel/VBoxContainer/Description

var titleText := ""
var descText := ""

var active_this_frame := false

func _process(_delta: float) -> void:
	position = lerp(position, get_global_mouse_position() + Vector2(16, 0), 0.1)
	if not active_this_frame:
		modulate.a = lerp(modulate.a, 0.0, 0.25)
		return
	active_this_frame = false
	title.text = titleText
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	description.text = descText
	description.autowrap_mode = TextServer.AUTOWRAP_WORD
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	$Panel/VBoxContainer.reset_size()
	$Panel/VBoxContainer.custom_minimum_size.x = min($Panel/VBoxContainer/Title.size.x, $Panel/VBoxContainer/Description.size.x)
	$Panel.set_size($Panel/VBoxContainer.size)

	modulate.a = lerp(modulate.a, 1.0, 0.25)

func request_tooltip(Title: String, Desc: String=""):
	titleText = Title
	if not Desc == "":
		descText = Desc
		$Panel/VBoxContainer/Separator.visible = true
		description.visible = true
	else:
		$Panel/VBoxContainer/Separator.visible = false
		description.visible = false
	active_this_frame = true
