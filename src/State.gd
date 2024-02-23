extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	pass

var current_health
var max_health
var damage
var speed
var magic
var currentBattle
var household_passive_active = false

# Player progression variables
var player_level
var tier_unlocked
var spells_unlocked
var generic_unlocked

# SAVE/ LOAD information
var FILE_PATH = "user://player_save_data.save"
var PASSKEY = "YouCanDoBetter"
#Prepare the player data by collecting these variables into a dictionary.
# Modified to include player progression data
func get_player_save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"damage": damage,
		"speed": speed,
		"magic": magic,
		"currentBattle": currentBattle,
		"household_passive_active": household_passive_active,
		"player_level": player_level,
		"tier_unlocked": tier_unlocked,
		"spells_unlocked": spells_unlocked,
		"generic_unlocked": generic_unlocked,
		
	}

# Modified to include default values for the new progression variables
func initialize_player_data() -> void:
	var new_player_data = {
		"current_health": 666,
		"max_health": 666,
		"damage": 300,
		"speed": 10, #25,
		"magic": 25,
		"currentBattle": 0,
		"player_level": 1,
		"tier_unlocked": 0,
		"spells_unlocked": ['', '', '', ''],
		"generic_unlocked": ['', '', '', '', ''],
	}
	apply_player_data(new_player_data)

#Saving: Call save_player_data() at appropriate moments, such as after completing a level or during specific autosave points.
func save_player_data() -> void:
	var player_data = get_player_save_data()  # Get the player's current state
	var json_data = JSON.stringify(player_data)  # Convert dictionary to JSON string using JSON.stringify()
	var file = FileAccess.open_encrypted_with_pass(FILE_PATH, FileAccess.WRITE, PASSKEY)
	if file:
		file.store_string(json_data)  # Store JSON string in the encrypted file
		file.close()
		print("Player data saved successfully.")
	else:
		print("Failed to save player data.")

#Loading: Call load_player_data() when the game starts, when a new level is loaded, or when the player loads a saved game.
func load_player_data() -> void:
	var file = FileAccess.open_encrypted_with_pass(FILE_PATH, FileAccess.READ, PASSKEY)
	if file:
		var json_string = file.get_as_text()  # Read the encrypted file content as text
		file.close()  # Always close the file after you're done
		
		var json = JSON.new()
		var result = json.parse(json_string)  # Parse the JSON string back into a Dictionary
		
		if result == 0:
			var player_data = json.data  # The parsed Dictionary
			print("Player data loaded successfully.")
			apply_player_data(player_data)
		else:
			print("Failed to parse player data: ", result)
	else:
		print("Failed to open encrypted player data file.")

# Modified to apply the loaded or initialized player progression data
#After loading, you'll want to apply this data back to your player's variables:
func apply_player_data(player_data: Dictionary) -> void:
	current_health = player_data["current_health"]
	max_health = player_data["max_health"]
	damage = player_data["damage"]
	speed = player_data["speed"]
	magic = player_data["magic"]
	currentBattle = player_data["currentBattle"]
	player_level = player_data["player_level"]
	tier_unlocked = player_data["tier_unlocked"]
	spells_unlocked = player_data["spells_unlocked"]
	generic_unlocked = player_data["generic_unlocked"]
	# Update any other player state or UI elements as necessary
