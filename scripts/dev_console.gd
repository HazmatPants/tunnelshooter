extends LineEdit

@onready var output = $CodeEdit

func _ready() -> void:
	visible = false
	
	text_submitted.connect(parse_command)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("console"):
		visible = !visible
		Global.player.set_input_lock("console", visible)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible else Input.MOUSE_MODE_CAPTURED
		text = ""
		grab_focus()

func user_print(Text: String):
	output.text += Text + "\n"

func parse_command(commandString: String):
	text = ""
	var args = commandString.split(" ")
	user_print(">>> " + commandString)
	if args.size() > 0:
		match args[0]:
			"help":
				user_print("
				status: returns internal health status values
				getbodyvars: returns all variables in healthCtl Node 
					!! WARNING: contains values that may crash the game if changed incorrectly!
				getbodyvar <var>: gets a variable's value
				setbodyvar <var> <value>: sets a variable's value
				clear: clears the dev console output
				")
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
			_:
				user_print("Command not valid")
