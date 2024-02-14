extends Node

# Constants for skill tree paths
const INFERNO = "Inferno"
const DEMON_KNIGHT = "Demon Knight"
const VAMPIRE_LORD = "Vampire Lord"

# Define the structure of the skill tree
var skill_tree = {
	INFERNO: {1: "Spell Placeholder 1", 2: "Spell Placeholder 2", 3: "Spell Placeholder 3", 4: "Spell Placeholder 4"},
	DEMON_KNIGHT: {1: "Spell Placeholder 1", 2: "Spell Placeholder 2", 3: "Spell Placeholder 3", 4: "Spell Placeholder 4"},
	VAMPIRE_LORD: {1: "Spell Placeholder 1", 2: "Spell Placeholder 2", 3: "Spell Placeholder 3", 4: "Spell Placeholder 4"}
}

# Player progression, keeps track of all variables
var player_level = 1
var upgrade_points = 0
var tier_unlocked = 1
var spells_unlocked = {
	INFERNO: [],
	DEMON_KNIGHT: [],
	VAMPIRE_LORD: []
}

# Function to handle leveling up, I'm not sure if this is how we want to do leveling
func level_up():
	player_level += 1
	upgrade_points += 1
	if player_level % 2 == 0:
		tier_unlocked += 1
	check_for_upgrades()

# Function to check and handle upgrades
func check_for_upgrades():
	if upgrade_points > 0:
		# This is a placeholder for the UI logic I haven't implment because im a bit confused on how to do it
		print("Player has upgrade points to spend. Current unlocked tier: ", tier_unlocked)

# Function for the player to choose a spell from a specific path and tier
func choose_spell(path, tier):
	if path in [INFERNO, DEMON_KNIGHT, VAMPIRE_LORD] and tier == tier_unlocked and upgrade_points > 0:
		var spell_name = skill_tree[path][tier]
		spells_unlocked[path].append(spell_name)
		upgrade_points -= 1
		print("Player has chosen spell: ", spell_name, " from path: ", path)
	else:
		print("Invalid tier selected or no upgrade points left.")

# Call this function after each battle, 
func battle_completed():
	level_up()
