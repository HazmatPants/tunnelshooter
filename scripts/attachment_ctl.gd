extends Node

@onready var muzzlePos = $"../SS320/Muzzle"
@onready var opticPos = $"../SS320/Optic"
@onready var underbarrelPos = $"../SS320/Underbarrel"

@export var attachments: Dictionary[String, PackedScene] = {
	"muzzle": null,
	"optic": null,
	"underbarrel": null
}

var attachmentNames: Dictionary[String, String] = {
	"muzzle": "",
	"optic": "",
	"underbarrel": ""
}

var attachmentsPos: Dictionary[String, Node3D] = {}

func update_attachments():
	for attachment in attachments:
		if attachments[attachment] != null:
			var new_att = attachments[attachment].instantiate()
			attachmentNames[attachment] = new_att.name
			attachmentsPos[attachment].add_child(new_att)

func _ready() -> void:
	attachmentsPos = {
		"muzzle": muzzlePos,
		"optic": opticPos,
		"underbarrel": underbarrelPos
	}
	update_attachments()
