extends Node

# Constants for skill tree paths
const INFERNO = "Inferno"
const DEMON_KNIGHT = "Demon Knight"
const VAMPIRE_LORD = "Vampire Lord"

var GENERIC_UPGRADES = {
	"Damage": 8,  # Increase damage by 8
	"Speed": -5,   # Decrease speed by 5
	"Magic": 5,   # Increase magic by 5
	"Health": 111  # Increase max and current health by 111
}

# Define the structure of the skill tree
var skill_tree = {
	INFERNO: {1: "Fireball", 2: "Fire Rain", 3: "Meteor", 4: "Hell on Earth"},
	DEMON_KNIGHT: {1: "Shattering Strike", 2: "Counter", 3: "Guillotine", 4: "True Form"},
	VAMPIRE_LORD: {1: "Blood Siphon", 2: "Red Rush", 3: "Noble Charm", 4: "Vampiric Frenzy"}
}

var grp1 = ButtonGroup.new()
var grp2 = ButtonGroup.new()
var grp3 = ButtonGroup.new()
var grp4 = ButtonGroup.new()
var grp5 = ButtonGroup.new()
var grp6 = ButtonGroup.new()
var grp7 = ButtonGroup.new()
var grp8 = ButtonGroup.new()
var grp9 = ButtonGroup.new()
var button_groups = {1: grp1, 2: grp2, 3: grp3, 4: grp4, 5: grp5, 6: grp6, 7: grp7, 8: grp8, 9: grp9}

var upgrade_available = false
var explanation_text = "You don't have any upgrades available. If you have any spells, you can switch them out for a spell of the same tier."

var sprite_frames = preload("res://Image/skilltree/btn_anim.tres")

func _ready():
	if State.player_level < State.currentBattle:
		level_up()
	$TextBoxes/Upgrade.text = "Current level: %s\nCurrent spell tier: %s" % [State.player_level, State.tier_unlocked]

# Function to handle leveling up
func level_up():
	State.player_level = State.currentBattle
	upgrade_available = true
	State.tier_unlocked = floor(State.player_level / 2)

# Function to check and handle upgrades
func check_for_upgrades():
	print(State.spells_unlocked)
	print(State.generic_unlocked)
	print(upgrade_available)
	if upgrade_available:
		$TextBoxes/Explanation.text = "You have an upgrade available! Choose an upgrade from level %s." % State.player_level
	else:
		$TextBoxes/Explanation.text = explanation_text
	for level in get_node("Tree/PanelContainer/HBoxContainer/Tree Levels").get_children():
		var level_num = int(level.name.get_slice(" ", 1))
		var current_generic = State.generic_unlocked[ceil(level_num / 2.0) - 1]
		for button in level.get_children():
			button.button_group = button_groups[level_num]
			button.button_pressed = button.name in State.spells_unlocked or button.name == current_generic
			button.disabled = level_num > State.player_level or (level_num % 2 == 1 and current_generic != '' and button.name != current_generic)
			if button.disabled == false and level_num == State.player_level:
				await animate_button(button, "unlock")

func get_upgrade(button_name, level):
	var is_tier = !(level % 2)
	var the_tier = (level / 2) - 1
	upgrade_available = is_tier and State.spells_unlocked[the_tier] != ''
	if !upgrade_available:
		$TextBoxes/Explanation.text = explanation_text
	
	var button = get_node("Tree/PanelContainer/HBoxContainer/Tree Levels/Level %s/%s" % [level, button_name])
	animate_button(button, "burn")

func animate_button(button, anim):
	var btn_anim = AnimatedSprite2D.new()
	btn_anim.sprite_frames = sprite_frames
	btn_anim.centered = false
	button.add_child(btn_anim)
	btn_anim.play(anim)
	await btn_anim.animation_finished
	btn_anim.queue_free()

# Function for the player to choose a spell from a specific path and tier
func _on_tier_pressed(path, tier):
	if path in [INFERNO, DEMON_KNIGHT, VAMPIRE_LORD] and tier <= State.tier_unlocked:
		var spell_name = skill_tree[path][tier]
		get_upgrade(spell_name, tier * 2)
		State.spells_unlocked[tier-1] = spell_name
		# State.upgrade_points -= 1
		$TextBoxes/Upgrade.text = "You have chosen the \"%s\" spell from the \"%s\" path as your Tier %s spell." % [spell_name.capitalize(), path.capitalize(), tier]
		print(State.spells_unlocked)
	else:
		$TextBoxes/Upgrade.text = "An error has occurred!"

func _on_generic_pressed(upgrade_choice, level):
	var num_upgrade = State.generic_unlocked[ceil(level / 2.0)-1]
	if upgrade_available and num_upgrade != upgrade_choice:
		State.generic_unlocked[ceil(level / 2.0)-1] = upgrade_choice
		match upgrade_choice:
			"Damage":
				State.damage += GENERIC_UPGRADES["Damage"]
			"Speed":
				State.speed += GENERIC_UPGRADES["Speed"]
				GENERIC_UPGRADES["Speed"] += 1 # ensures the player gains 1 turn per round for every speed upgrade
			"Magic":
				State.magic += GENERIC_UPGRADES["Magic"]
			"Health":
				State.max_health += GENERIC_UPGRADES["Health"]
				State.current_health += GENERIC_UPGRADES["Health"]
		get_upgrade(upgrade_choice, level)
		$TextBoxes/Upgrade.text = "You've increased your %s!" % upgrade_choice
		for upgrade in get_node("Tree/PanelContainer/HBoxContainer/Tree Levels/Level %s" % level).get_children():
			upgrade.disabled = upgrade.name != upgrade_choice
	else:
		$TextBoxes/Upgrade.text = "You can't choose that!"
	
	#State.generic_unlocked[ceil(level / 2)] = upgrade_choice
	#for upgrade in State.generic_unlocked:
		#match upgrade:
			#"Damage":
				#State.damage += GENERIC_UPGRADES["Damage"]
			#"Speed":
				#State.speed += GENERIC_UPGRADES["Speed"]
				#GENERIC_UPGRADES["Speed"] += 1 # ensures the player gains 1 turn per round for every speed upgrade
			#"Magic":
				#State.magic += GENERIC_UPGRADES["Magic"]
			#"Health":
				#State.current_health = min(State.max_health, State.current_health + GENERIC_UPGRADES["Health"])
	#get_upgrade()
	#$TextBoxes/Upgrade.text = "You've increased your %s!" % upgrade_choice

func _on_back_pressed():
	#get_tree().change_scene_to_file("res://MainScenes/campfire.tscn")
	State.save_player_data()
	self.visible = false
