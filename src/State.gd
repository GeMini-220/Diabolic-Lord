extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	pass
var Characters ={
	"player1":{"name":"player1", "damage":1, "speed":25, "HP":10, "Max_HP":10, "alive":true},
	
	"player2":{"name":"player2","damage":2, "speed":40, "HP":20, "Max_HP":20, "alive":true},
	
	"player3":{"name":"player3","damage":3, "speed":70, "HP":30, "Max_HP":30, "alive":true},
	
	"Boss":{"name":"Boss","damage":30, "speed":80, "HP":100, "Max_HP":100, "alive":true}
}
var current_health = 666
var max_health = 666
var damage = 10
var speed = 25



# SAVE/ LOAD information
var FILE_PATH = "user://player_save_data.save"
var PASSKEY = "YouCanDoBetter"
#Prepare the player data by collecting these variables into a dictionary.
func get_player_save_data() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"damage": damage,
		"speed": speed
	}

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
		
		if result.error == 0:
			var player_data = result.result  # The parsed Dictionary
			print("Player data loaded successfully.")
			apply_player_data(player_data)
		else:
			print("Failed to parse player data: ", result.error)
	else:
		print("Failed to open encrypted player data file.")

#After loading, you'll want to apply this data back to your player's variables:
func apply_player_data(player_data: Dictionary) -> void:
	current_health = player_data["current_health"]
	max_health = player_data["max_health"]
	damage = player_data["damage"]
	speed = player_data["speed"]
	# Update any other player state or UI elements as necessary

