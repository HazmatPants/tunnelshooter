extends LineEdit

@onready var output = $CodeEdit

var cmd_history: Array[String] = []
var history_idx: int = 0

func _ready() -> void:
	visible = false

	text_submitted.connect(parse_command)
	user_print("this console is used to debug the game. be careful.\ntype 'help' for a list of commands.")

func _input(event: InputEvent) -> void:
	if not Global.console_enabled:
		return
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_QUOTELEFT:
				visible = !visible
				Global.player.set_input_lock("console", visible)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED

				call_deferred("grab_focus")
			KEY_UP:
				history_idx -= 1
				text = get_history()
			KEY_DOWN:
				history_idx += 1
				text = get_history()

func get_history():
	if cmd_history.is_empty():
		return ""
	if history_idx < 0:
		history_idx = 0
	if history_idx > cmd_history.size() - 1:
		history_idx = cmd_history.size() - 1
		return ""
	return cmd_history[history_idx]

func user_print(Text: String):
	output.text += Text + "\n"

func parse_command(commandString: String):
	text = ""
	var args = commandString.split(" ")
	user_print(">>> " + commandString)
	if args.size() > 0:
		match args[0]:
			"help":
				var help_string = ""
				help_string += "status: returns internal health status values\n"
				help_string += "getbodyvars: returns all variables in healthCtl Node\n"
				help_string += "	!! WARNING: contains values that may crash the game if changed incorrectly!\n"
				help_string += "getbodyvar <var>: gets a body variable's value\n"
				help_string += "setbodyvar <var> <value>: sets a body variable's value\n"
				help_string += "getlimbvars <limb> <var> <value>: sets a limb variable's value\n"
				help_string += "getlimbvar <limb> <var>: gets a limb variable's value\n"
				help_string += "setlimbvar <limb> <var> <value>: sets a limb variable's value\n"
				help_string += "clear: clears the dev console output\n"
				help_string += "godmode: toggles godmode (invincibility to damage)\n"
				help_string += "flashmode: toggles flashmode (super speed)\n"
				help_string += "fall <amount>: teleports you <amount> meters upwards\n"
				user_print(help_string)
			"status":
				var stat = Global.player.healthCtl
				var limbStat = {}
				for limb in stat.Limbs.keys():
					limbStat[limb] = {
						"pain": stat.Limbs[limb].pain,
						"muscle": stat.Limbs[limb].muscleHealth,
						"skin": stat.Limbs[limb].skinHealth
						}
				var limbStatString = ""

				for limb in limbStat.keys():
					limbStatString += limb + ":\n"
					for key in limbStat[limb].keys():
						limbStatString += "	" + key + ": " + str(limbStat[limb][key]) + "\n"

				user_print("Player Health Status
					Brain Health: %s
					Consciousness: %s
					Stamina: %s
					Heart Rate: %s
					Blood Vol: %s
					Bleed Rate: %s
					Blood O2: %s
					Work: %s
					
					Limb Status
					%s
					" % [
						stat.brainHealth,
						stat.consciousness,
						stat.stamina,
						stat.heartRate,
						stat.bloodVolume,
						stat.get_limb_total("bleedingRate"),
						stat.bloodOxygen,
						stat.physicalWork,
						limbStatString
					])
			"getbodyvars":
				var properties = Global.player.healthCtl.get_property_list()
				
				var varsString = ""
				
				for property in properties:
					if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
						varsString += property["name"] + ", "
				
				user_print(varsString)
			"getbodyvar":
				if args.size() < 2:
					user_print("missing target variable argument\nUsage: getbodyvar <var>")
					return
				var targetvar = args[1]
				var properties = Global.player.healthCtl.get_property_list()
				var exists := false
				for property in properties:
					if property.name == targetvar:
						exists = true
						break
				
				if not exists:
					user_print("Body variable '%s' does not exist" % targetvar)
				
				var targetvarval = Global.player.healthCtl.get(targetvar)
				user_print(str(targetvarval) + " (" + str(type_string(typeof(targetvarval))) + ")")
			"setbodyvar":
				if args.size() < 2:
					user_print("missing target variable argument\nUsage: setbodyvar <var> <value>")
					return
				var targetvar = args[1]
				if args.size() < 3:
					user_print("missing new value argument\nUsage: setbodyvar <var> <value>")
					return
				var new_val = args[2]
				
				var properties = Global.player.healthCtl.get_property_list()
				var exists := false
				for property in properties:
					if property.name == targetvar:
						exists = true
						break
				
				if not exists:
					user_print("Body variable '%s' does not exist" % targetvar)
					return
				
				Global.player.healthCtl.set(targetvar, new_val)
				user_print("Set '%s' = %s" % [targetvar, new_val])
			"getlimbvars":
				if args.size() < 2:
					user_print("missing target limb argument\nUsage: getlimbvars <limb>")
					return
				var targetlimb = args[1]
				var properties
				if Global.player.healthCtl.Limbs.has(targetlimb):
					properties = Global.player.healthCtl.Limbs[targetlimb].get_property_list()
				else:
					user_print("limb '%s' not found.\nValid limb names:\n%s" % [targetlimb, " ".join(Global.player.healthCtl.Limbs.keys())])
					return
				
				var varsString = ""
				
				for property in properties:
					if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
						varsString += property["name"] + ", "
				
				user_print(varsString)
			"getlimbvar":
				if args.size() < 2:
					user_print("missing target limb argument\nUsage: getlimbvar <limb> <var>")
					return
				var targetlimb = args[1]
				var properties
				if Global.player.healthCtl.Limbs.has(targetlimb):
					properties = Global.player.healthCtl.Limbs[targetlimb].get_property_list()
				else:
					user_print("limb '%s' not found.\nValid limb names:\n%s" % [targetlimb, " ".join(Global.player.healthCtl.Limbs.keys())])
					return
				if args.size() < 3:
					user_print("missing target variable argument\nUsage: getlimbvar <limb> <var>")
					return
				var targetvar = args[2]
				var exists := false
				for property in properties:
					if property.name == targetvar:
						exists = true
						break
				
				if not exists:
					user_print("Variable '%s' does not exist on limb '%s'" % [targetvar, targetlimb])
				
				var targetvarval = Global.player.healthCtl.Limbs[targetlimb].get(targetvar)
				user_print(str(targetvarval) + " (" + str(type_string(typeof(targetvarval))) + ")")
			"setlimbvar":
				if args.size() < 2:
					user_print("missing target limb argument\nUsage: setlimbvar <limb> <var> <value>")
					return
				var targetlimb = args[1]
				var properties
				if Global.player.healthCtl.Limbs.has(targetlimb):
					properties = Global.player.healthCtl.Limbs[targetlimb].get_property_list()
				else:
					user_print("limb '%s' not found.\nValid limb names:\n%s" % [targetlimb, " ".join(Global.player.healthCtl.Limbs.keys())])
					return
				if args.size() < 3:
					user_print("missing target variable argument\nUsage: setlimbvar <limb> <var> <value>")
					return
				var targetvar = args[2]
				if args.size() < 4:
					user_print("missing new value argument\nUsage: setlimbvar <limb> <var> <value>")
					return
				var new_val = args[3]
				
				var exists := false
				for property in properties:
					if property.name == targetvar:
						exists = true
						break
				
				if not exists:
					user_print("Limb variable '%s' does not exist" % targetvar)
					return
				
				Global.player.healthCtl.Limbs[targetlimb].set(targetvar, new_val)
				user_print("Set '%s' for '%s' = %s" % [targetvar, targetlimb, new_val])
			"clear":
				output.text = ""
			"heal":
				var stat = Global.player.healthCtl
				stat.consciousness = 1.0
				stat.brainHealth = 1.0
				stat.bloodOxygen = 1.0
				stat.bloodVolume = 5000.0
				for limb in stat.Limbs.keys():
					stat.Limbs[limb].pain = 0.0
					stat.Limbs[limb].bleedingRate = 0.0
					stat.Limbs[limb].muscleHealth = 1.0
					stat.Limbs[limb].skinHealth = 1.0

				for organ in stat.organs.keys():
					stat.organs[organ] = true
			"afflictions":
				var stat = Global.player.healthCtl
				var aff_string := ""
				for affliction in stat.afflictions.keys():
					aff_string += "name: %s, intensity: %s\n" % [affliction, stat.afflictions[affliction]["intensity"]]
				user_print(aff_string)
			"godmode":
				Global.godmode = !Global.godmode
				user_print("godmode is now ON" if Global.godmode else "godmode is now OFF")
			"flashmode":
				Global.flashmode = !Global.flashmode
				user_print("flashmode is now ON" if Global.flashmode else "flashmode is now OFF")
			"fall":
				var amount = 10
				if args.size() > 1:
					amount = args[1]
				Global.player.global_position.y += abs(float(amount))
			_:
				user_print("Command not valid")
				return

	if commandString != cmd_history.back():
		cmd_history.append(commandString)
		history_idx = cmd_history.size()
