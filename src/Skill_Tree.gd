extends Node

# Constants for skill tree paths
const INFERNO = "Inferno"
const DEMON_KNIGHT = "Demon Knight"
const VAMPIRE_LORD = "Vampire Lord"

const GENERIC_UPGRADES = {
	"Damage": 10,  # Increase damage by 10
	"Speed": -5,   # Decrease speed by 5
	"Magic": 5,   # Increase magic by 5
	"Health": 200  # Increase current health by 200
}

# Define the structure of the skill tree
var skill_tree = {
	INFERNO: {1: "Fireball", 2: "Fire Rain", 3: "Meteor", 4: "Hell On Earth"},
	DEMON_KNIGHT: {1: "Counter", 2: "Shattering Strike", 3: "Guillotine", 4: "True Form"},
	VAMPIRE_LORD: {1: "Spell Placeholder 1", 2: "Spell Placeholder 2", 3: "Spell Placeholder 3", 4: "Spell Placeholder 4"}
}

var upgrade_available = false
var explanation_text = "You don't have any upgrades available. If you have any spells, you can switch them out for a spell of the same tier."

func _ready():
	if State.player_level < State.currentBattle:
		level_up()
	check_for_upgrades()
	$TextBoxes/Upgrade.text = "Current spell tier: %s" % State.tier_unlocked

# Function to handle leveling up, I'm not sure if this is how we want to do leveling
func level_up():
	State.player_level += 1
	# State.upgrade_points += 1   # For choosing a spell
	upgrade_available = true
	if int(State.player_level) % 2 == 0:
		State.tier_unlocked += 1
	# var level_label = get_node("Tree/HBoxContainer/Labels/Label%s" % State.player_level)

# Function to check and handle upgrades
func check_for_upgrades():
	if upgrade_available: # State.upgrade_points > 0:
		# This is a placeholder for the UI logic I haven't implment because im a bit confused on how to do it
		$TextBoxes/Explanation.text = "You have an upgrade available! Choose an upgrade from level %s." % State.player_level
		for upgrade in get_node("Tree/HBoxContainer/Tree Levels/Level %s" % State.player_level).get_children():
			upgrade.disabled = false
	else:
		$TextBoxes/Explanation.text = explanation_text

func get_upgrade():
	upgrade_available = false
	$TextBoxes/Explanation.text = explanation_text

# Function for the player to choose a spell from a specific path and tier
func _on_tier_pressed(path, tier):
	if path in [INFERNO, DEMON_KNIGHT, VAMPIRE_LORD] and tier <= State.tier_unlocked:
		var spell_name = skill_tree[path][tier]
		State.spells_unlocked[tier-1] = spell_name
		# State.upgrade_points -= 1
		get_upgrade()
		$TextBoxes/Upgrade.text = "You have chosen the \"%s\" spell from the \"%s\" path." % [spell_name.capitalize(), path.capitalize()]
		print(State.spells_unlocked)
	else:
		$TextBoxes/Upgrade.text = "An error has occurred!"

func _on_generic_pressed(upgrade_choice):
	if upgrade_available:
		match upgrade_choice:
			"Damage":
				State.damage += GENERIC_UPGRADES["Damage"]
				get_upgrade()
			"Speed":
				State.speed += GENERIC_UPGRADES["Speed"]
				get_upgrade()
			"Magic":
				State.magic += GENERIC_UPGRADES["Magic"]
				get_upgrade()
			"Health":
				State.current_health += GENERIC_UPGRADES["Health"]
				get_upgrade()
	else:
		$TextBoxes/Upgrade.text = "You can't choose that!"

func _on_back_pressed():
	get_tree().change_scene_to_file("res://MainScenes/campfire.tscn")
