extends Node

# Constants for time units
const TU = 100

# Player (Demon Lord) data
var player_health : int = 9000
var player_mana : int = 150
var player_phase : int = 1

# Enemy data
var enemy_health : int = 400
var enemy_speed : int = 25

# Function to handle player's turn
func player_turn():
	print("Player's turn")
	# Implement player's turn logic here
	cast_blizzard()
	check_game_state()

# Function to handle enemy's turn
func enemy_turn():
	print("Enemy's turn")
	
	# Implement enemy's turn logic here
	fighter_attack()
	check_game_state()

# Function to check for victory or defeat conditions
func check_game_state():
	if player_health <= 0:
		print("Game over - Player defeated")
	elif enemy_health <= 0:
		print("Victory - Enemy defeated")
	else:
		# Continue the game
		if player_phase == 1:
			player_turn()
		else:
			enemy_turn()

# Function to cast Blizzard spell
func cast_blizzard():
	print("Player casts Blizzard")
	# Implement Blizzard spell logic here
	# Update enemy_health, player_mana, etc.

# Function to handle Fighter's attack
func fighter_attack():
	print("Enemy Fighter attacks")
	# Implement Fighter's attack logic here
	
	# Update player_health, enemy_speed, etc.

# Function to simulate the game flow
