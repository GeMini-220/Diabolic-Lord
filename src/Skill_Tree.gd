extends Node

# Constants for skill tree paths
const INFERNO = "Inferno"
const DEMON_KNIGHT = "Demon Knight"
const VAMPIRE_LORD = "Vampire Lord"

var GENERIC_UPGRADES = {
	"Damage": 8,  # Increase damage by 8
	"Speed": -5,   # Decrease speed by 5
	"Magic": 5,   # Increase magic by 5
	"Health": 200  # Increase current health by 200
}

# Define the structure of the skill tree
var skill_tree = {
	INFERNO: {1: "Fireball", 2: "Fire Rain", 3: "Meteor", 4: "Hell On Earth"},
	DEMON_KNIGHT: {1: "Counter", 2: "Shattering Strike", 3: "Guillotine", 4: "True Form"},
	VAMPIRE_LORD: {1: "Blood Siphon", 2: "Red Rush", 3: "Noble Charm", 4: "Vampiric Frenzy"}
}

var upgrade_available = false
var explanation_text = "You don't have any upgrades available. If you have any spells, you can switch them out for a spell of the same tier."

func _ready():
	if State.player_level < State.currentBattle:
		level_up()
	check_for_upgrades()
	$TextBoxes/Upgrade.text = "Current level: %s\nCurrent spell tier: %s" % [State.player_level, State.tier_unlocked]

# Function to handle leveling up
func level_up():
	State.player_level = State.currentBattle
	upgrade_available = true
	State.tier_unlocked = floor(State.player_level / 2)
	# var level_label = get_node("Tree/HBoxContainer/Labels/Label%s" % State.player_level)

# Function to check and handle upgrades
func check_for_upgrades():
	for level in get_node("Tree/PanelContainer/HBoxContainer/Tree Levels").get_children():
		if int(level.name.get_slice(" ", 1)) <= State.player_level:
			for upgrade in level.get_children():
				upgrade.disabled = false
	if upgrade_available:
		$TextBoxes/Explanation.text = "You have an upgrade available! Choose an upgrade from level %s." % State.player_level
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
		$TextBoxes/Upgrade.text = "You have chosen the \"%s\" spell from the \"%s\" path as your Tier %s spell." % [spell_name.capitalize(), path.capitalize(), tier]
		print(State.spells_unlocked)
	else:
		$TextBoxes/Upgrade.text = "An error has occurred!"

func _on_generic_pressed(upgrade_choice):
	if upgrade_available:
		match upgrade_choice:
			"Damage":
				State.damage += GENERIC_UPGRADES["Damage"]
				get_upgrade()
				$TextBoxes/Upgrade.text = "You've increased your %s!" % upgrade_choice
			"Speed":
				State.speed += GENERIC_UPGRADES["Speed"]
				GENERIC_UPGRADES["Speed"] += 1 # ensures the player gains 1 turn per round for every speed upgrade
				get_upgrade()
				$TextBoxes/Upgrade.text = "You've increased your %s!" % upgrade_choice
			"Magic":
				State.magic += GENERIC_UPGRADES["Magic"]
				get_upgrade()
				$TextBoxes/Upgrade.text = "You've increased your %s!" % upgrade_choice
			"Health":
				State.current_health += GENERIC_UPGRADES["Health"]
				get_upgrade()
				$TextBoxes/Upgrade.text = "You've increased your %s!" % upgrade_choice
	else:
		$TextBoxes/Upgrade.text = "You can't choose that!"

func _on_back_pressed():
	#get_tree().change_scene_to_file("res://MainScenes/campfire.tscn")
	State.save_player_data()
	self.visible = false
