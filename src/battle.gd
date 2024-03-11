extends Control

signal textbox_closed
signal action_taken
signal target_selected


var enemies
var num_current_enemies
var all_characters
var is_defending = false
var countering_turn = 0
var game_over = false
var second_phase = false
var target = null
var stunned = false
var Boss_damage = State.damage
var Boss_magic = State.magic
var Boss_speed = State.speed
var guillotine_upperbound = 0.25
var Boss_lifesteal = 0
var true_form = 0
var shattering_strike_cd = 0
var counter_cd = 0
var guillotine_cd = 0
var true_form_cd = 6 # initial cd
var noble_charm_cd = 0
var vampiric_frenzy_active = false
var vampiric_frenzy_cd = 0
var fire_rain_cd = 0
var meteor_cd = 0
var hell_on_earth_cd = 0
var hell_on_earth_active = false
var is_flying = false
var red_rush_target = null
var red_rush_damage = 0
var red_rush_cd = 0
var hex_duration = 0
var hex_damage = 0
var redirect_active = false
var redirect_target = null
var infernal_affliction_active = false
var user_name = State.user_name

@onready var screen_fade = $ScreenFade
@onready var screen_fade_anim = $ScreenFade/ScreenFadeAnimPlayer
@export var characters = {}
@onready var fly_away = $DemonLord/FlyAway
@onready var enemy_container = $EnemyContainer


func fill_battle_with_enemies():
	var screen_resolution = get_tree().root.content_scale_size # Example: (1152, 648)
	num_current_enemies = len(enemies)
	var max_enemies_per_row = 4
	var left_buffer = 60

	# Calculate the horizontal and vertical spacing based on the desired number of rows and columns
	var horizontal_spacing = (screen_resolution.x - left_buffer) / (max_enemies_per_row + 2)
	var vertical_spacing = screen_resolution.y / 3  # Dividing by 3 gives us space for two rows at the top

	for i in range(num_current_enemies):
		enemies[i].get_ready()  # Call any setup procedures necessary for the enemy
		# Calculate the position for each enemy
		var x_position = (i % max_enemies_per_row) * horizontal_spacing + horizontal_spacing / 3 + left_buffer # Start slightly to the right

		# Determine the row index (0 for the bottom row, 1 for the top row)
		var row_index = i / max_enemies_per_row
		var y_position = 0
		if row_index >= 1:  # If the index is 1 or higher, place in the top row
			y_position = vertical_spacing * 1.25  # The top row position
		else:  # Otherwise, place in the bottom row
			y_position = vertical_spacing + vertical_spacing  # The bottom row position

		# Set the enemy's position to these calculated coordinates
		enemies[i].position = Vector2(x_position, y_position)



func start_fade_in():
	screen_fade_anim.play("fade_in")
	await screen_fade_anim.animation_finished


func start_fade_out(next_scene_path: String):
	screen_fade.visible = true
	screen_fade_anim.play("fade_out")
	await screen_fade_anim.animation_finished
	get_tree().change_scene_to_file(next_scene_path)


func _ready():

	set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
	State.currentBattle += 1
	$DemonLord.play("idle")
	$BGMusic.play()

	randomize()
	enemies = choose_random_enemies()
	all_characters = enemies.duplicate()
	all_characters.append($DemonLord)


	fill_battle_with_enemies()
#	var screen_resolution = get_tree().root.content_scale_size # (1152, 648)
#	for i in len(enemies):
#		enemies[i].get_ready()
#		enemies[i].position = Vector2(screen_resolution.x / (num_current_enemies + 1) * (i + 1), screen_resolution.y / 2)
		# temporary alignment of enemies
	#Enable/Disable buttons based on if skill is obtained
	ready_spells()
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	$TierSpellsPanel.hide()
	display_text("Summoned by your loyal cultists, you, the Demon Lord, have awoken!")
	await self.textbox_closed
	display_text("These %s adventurers wish to return you to your eternal slumber." % num_current_enemies)
	await self.textbox_closed
	display_text("This is their final battle!")
	await self.textbox_closed
	await process()


func choose_random_enemies():
	for e in $CurrentEnemies.get_children():
		e.queue_free()
	if 1 <= State.currentBattle and State.currentBattle <= 3:
		num_current_enemies = 3
	elif 4 <= State.currentBattle and State.currentBattle <= 6:
		num_current_enemies = 4
	elif 7 <= State.currentBattle and State.currentBattle <= 9:
		num_current_enemies = 5
	else:
		num_current_enemies = 8
	var enemy_types = $Enemies.get_children() # at least 1 enemy for each type
	while num_current_enemies > enemy_types.size(): # free spots
		enemy_types.append($Enemies.get_children()[randi() % $Enemies.get_children().size()])
	var enemy_dict = {}
	for i in $Enemies.get_children():
		for j in i.get_children():
			enemy_dict[j.name] = []
	for i in enemy_types:
		var enemies_of_type = i.get_children()
		var new_enemy = enemies_of_type[randi() % enemies_of_type.size()].duplicate()
		enemy_dict[new_enemy.name].append(new_enemy)
	for i in enemy_dict:
		if enemy_dict[i].size() > 1:
			for j in enemy_dict[i].size():
				enemy_dict[i][j].name = "%s %s" % [i, j + 1] # rename
		for j in enemy_dict[i].size():
			$CurrentEnemies.add_child(enemy_dict[i][j])
	return $CurrentEnemies.get_children()

func update_tooltip():
	$SpellsPanel/Spells/Attack.tooltip_text = "Basic attack, deals %s damage to one target." % floor(Boss_damage)
	$SpellsPanel/Spells/dreadforge.tooltip_text = "Increases your damage by %s%% for the remainder of the battle." % Boss_magic
	$SpellsPanel/Spells/InfernalAffliction.tooltip_text = "Traps one target in a ring of fire, which deals %s damage on each of its turns." % floor(Boss_damage / 3)
	var tier_spells_defs = {
		"Fireball": "Hurl a fireball at that enemy, dealing damage on impact.",
		"Fire Rain": "Select 2 enemies. Those enemies are applied 3 stacks of Scorched Earth.",
		"Meteor": "Deal Heavy Damage to 3 random enemies.",
		"Hell on Earth": "Scorched Earth is now applied every turn, with increasing damage every turn.",
		"Shattering Strike": "Deals %s damage to one target and stun them for %s turn." % [floor(Boss_damage * 0.75), 1 + true_form],
		"Counter": "Guard for %s turn. Return 2x the pre-mitigation damage dealt to you." % (1 + true_form),
		"Guillotine": "Deals %s damage to one target. If the target is below %s%% hp, they take double damage from this ability. If they die, recast on a random target." % [floor(Boss_damage), guillotine_upperbound * 100],
		"True Form": "All your stats by 50%% for the rest of the fight. Gain 20%% lifesteal. Shattering Strike and Counter buff/debuff increases by 1 turn. Guillotine %s%% -> 35%%." % (guillotine_upperbound * 100),
		"Blood Siphon": "Choose an enemy. They take damage while you heal the damage taken.",
		"Red Rush": "Choose a target. Fly up into the air, causing all attacks to miss, then dive bomb one enemy, dealing massive damage.",
		"Noble Charm": "Choose 1 enemy. For the next 3 turns, they attack their allies.",
		"Vampiric Frenzy": "For 5 turns, all your attacks and skills heal you for the full amount and do 20% more damage. Enemies you damage have a 50% chance to become charmed.",
	}
	for i in range(4):
		var spell = get_node("TierSpellsPanel/TierSpells/%s" % str(i+1))
		if spell.text in tier_spells_defs:
			spell.tooltip_text = tier_spells_defs[spell.text]
		else:
			spell.tooltip_text = "Not yet unlocked."

func set_health(progress_bar, health, max_health):
	progress_bar.value = health
	progress_bar.max_value = max_health
	progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]

func check_win():
	for enemy in enemies:
		if enemy.dead == false:
			return false
	game_over = true
	display_text("You won!")
	await self.textbox_closed
	#get_tree().quit()

func enemy_turn(enemy):

	# Apply "Scorched Earth" DOT effect if it's active before any actions are taken
	if hell_on_earth_active:
		enemy.DOT *= 1.2

	if enemy.has_debuff("Scorched Earth") and enemy.DOT > 0:
		$ScorchedEarthSound.play()
		enemy.took_damage(enemy.DOT)
		display_text("%s takes %d damage from the Scorched Earth." % [enemy.name, enemy.DOT])
		await self.textbox_closed

		await take_lifesteal(enemy.DOT)

		if enemy.dead:
			if enemy.name == "Artificer":
				if enemy == redirect_target:
					redirect_target = null #in case artificer dies while mid redirect due to scorched earth
			display_text("The %s gave in to the flames and has perished, only a pile of ash remains." % enemy.name)
			await self.textbox_closed
			enemies.erase(enemy)  # Make sure to remove the enemy properly from your enemy list
			await check_win()  # Check if this death has resulted in a win condition
			if game_over:
				end_game()  # Exit the function early since the enemy is dead and cannot take further actions

	enemy.reduce_debuff_duration()  # Reduce the DOT duration

	# Check if the enemy is charmed and the charm effect should trigger this turn
	if enemy.has_debuff("noble_charm"):
		$VL_NC_Sound.play()
		display_text("%s is under the charms influence and ready to serve" % enemy.name)
		await self.textbox_closed
		var ally = select_random_ally(enemy)
		if ally:
			var damage = calculate_damage(enemy, ally)
			ally.took_damage(damage)
			display_text("%s attacks %s for %d damage." % [enemy.name, ally.name, damage])
			await self.textbox_closed
			if ally.dead:
				display_text("The %s killed the %s!" % [enemy.name, ally.name])
				await self.textbox_closed
				enemies.erase(ally)  # Remove the dead ally from the enemies list
				# Ensure target is set to null if it was the dead ally
				if target == ally:
					target = null
			enemy.reduce_debuff_duration("noble_charm")
		else:
			# If no allies left, enemy attacks itself
			var damage = calculate_damage(enemy, enemy)
			enemy.took_damage(damage)
			display_text("%s is charmed and attacks themselves for %d damage." % [enemy.name, damage])
			await self.textbox_closed
			if enemy.dead:
				display_text("%s killed themselves under the charm's influence!" % enemy.name)
				await self.textbox_closed
				enemies.erase(enemy)
				# If the current target was the enemy itself, clear it
				if target == enemy:
					target = null
				await check_win()
				return
		# Check if charm effect wears off
		if noble_charm_cd <= 0:
			display_text("The %s shakes off the effects of Noble Charm." % enemy.name)
			await self.textbox_closed
	else:
		# Proceed with the normal turn actions
		await enemy.turn()
		if enemy.DOT > 0:
			await enemy.took_damage(enemy.DOT)
		if enemy.dead:
			display_text("The %s burned to death!" % enemy.name)
			await self.textbox_closed
			enemies.erase(enemy)
			target = null
			await check_win()
			return
		else:
			if enemy.stunned_turn > 0:
				enemy.stunned_turn -= 1
				display_text("The %s is stunned! Their turn will be skipped." % enemy.name)
				await self.textbox_closed
				return
			match enemy.current_action:
				"attack":
					await enemy_attack(enemy)
				"heal":
					await enemy_heal(enemy)
				"help":
					await enemy_help(enemy)
				"block":
					await enemy_block(enemy)
				"rally":
					await enemy_rally(enemy)
				"stun":
					await enemy_stun(enemy)
				# "shield":
				#     await enemy_shield(enemy)
				"hide":
					await enemy_hide(enemy)
				"hex":
					await enemy_hex(enemy)
				"redirect":
					await enemy_redirect(enemy)

#this is for a charmed enemy to select a random enemy that is not them selves
func select_random_ally(charmed_enemy):
	var potential_allies = []
	# Fill potential_allies with enemies that are alive and not the charmed enemy
	for enemy in enemies:
		if enemy != charmed_enemy and not enemy.dead:
			potential_allies.append(enemy)

	# If there are no potential allies left, return null
	if potential_allies.size() == 0:
		return null

	# Select a random index from the potential_allies array
	var random_index = randi() % potential_allies.size()
	return potential_allies[random_index]
 # Return the randomly selected ally

#self explanitory useful for enemy on enemy attacks
func calculate_damage(attacker, _target) -> int:
	var final_damage = floor(randf_range(0.5 + attacker.modifier, 1.5 + attacker.modifier) * attacker.damage)
	final_damage = max(final_damage, 0)
	return final_damage


func enemy_attack(enemy):
	if is_flying == true:
		display_text("%s attempts to attack the Vampire Lord, but misses as he is soaring high above!" % enemy.name)
		await self.textbox_closed
		return
	if enemy.is_hiding:
		display_text("The %s reveals themselves!" % enemy.name)
		await self.textbox_closed
		await enemy.play_animation_player("reveal")
		enemy.modifier += 1
		enemy.is_hiding = false
	display_text("The %s attacks!" % enemy.name)
	await self.textbox_closed
	await enemy.play_animation("attack")

	var final_damage = floor(randf_range(0.5 + enemy.modifier, 1.5 + enemy.modifier) * enemy.damage)
	if is_defending:
		is_defending = false
		$AnimationPlayer.play("mini_shake")
		display_text("Your minion took the attack for you!")
		await self.textbox_closed
	else:
		State.current_health = max(0, State.current_health - final_damage)
		set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)

		$AnimationPlayer.play("shake")
		display_text("The %s dealt %d damage!" % [enemy.name, final_damage])
		await self.textbox_closed

	if State.current_health != 0 and countering_turn > 0:
		var countering_damage = final_damage * 2

		countering_turn -= 1
		$DemonLord/EffectAnimation.play("counter trigger")
		$dk_spell_2_counter.play()
		await enemy.took_damage(countering_damage, "counter")
		display_text("You countered the attack!")
		await self.textbox_closed

		display_text("You dealt %d damage to the %s!" % [countering_damage, enemy.name])
		await self.textbox_closed

		await take_lifesteal(countering_damage)

		if enemy.dead:
			display_text("You killed the %s!" % enemy.name)
			await self.textbox_closed
			enemies.erase(enemy)
			await check_win()

	if State.current_health == 0:
		game_over = true
		$AnimationPlayer.play("enemy_damaged")
		display_text("You died!")
		await self.textbox_closed
		#get_tree().quit()
	elif State.current_health <= State.max_health / 2 and not second_phase:
		second_phase = true
		Boss_damage *= 1.5
		display_text("Under half of your health, you've reached your second phase!")
		await self.textbox_closed
		display_text("Your damage has increased!")
		await self.textbox_closed

	enemy.modifier = 0

func enemy_heal(enemy):
	var lowest_health = 100
	var heal_target
	for ally in enemies:
		if (not ally.dead) and (ally.current_health < ally.health) and (ally.current_health <= lowest_health):
			lowest_health = ally.current_health
			heal_target = ally
	if heal_target == null:
		await enemy_attack(enemy)
	else:
		display_text("The %s is healing the %s!" % [enemy.name, heal_target.name])
		await self.textbox_closed

		await enemy.play_animation("attack")

		var healing = floor(randf_range(0.5, 1.5) * enemy.magic)
		heal_target.recieve_healing(healing)

		display_text("The %s healed the %s for %s!" % [enemy.name, heal_target.name, healing])
		await self.textbox_closed

func enemy_block(enemy):
	var allys = 0
	for ally in enemies:
		if not ally.dead:
			allys += 1
	if allys <= 1:
		await enemy_attack(enemy)
	else:
		target = enemy
		display_text("The %s is defending their allies!" % enemy.name)
		await self.textbox_closed
		await enemy.play_animation("attack")
		display_text("The %s is going to take the next attack!" % enemy.name)
		await self.textbox_closed

func enemy_help(enemy):
	var highest_dot = 0
	var help_target
	for ally in enemies:
		if (not ally.dead) and (ally.DOT > highest_dot):
			highest_dot = ally.DOT
			help_target = ally
	if help_target == null:
		await enemy_attack(enemy)
	else:
		help_target.DOT = max(0, help_target.DOT - 5)
		help_target.DOT = floor(help_target.DOT)
		display_text("The %s is saving %s from their infernal prison!" % [enemy.name, help_target.name])
		await self.textbox_closed
		await enemy.play_animation("attack")
		if help_target.DOT == 0:
			display_text("The %s won't take damage on its turns anymore!" % help_target.name)
			await self.textbox_closed
		else:
			display_text("The %s will only take %s damage on each of its turns!" % [help_target.name, help_target.DOT])
			await self.textbox_closed

func enemy_rally(enemy):
	var target_number = randi() % enemies.size()
	var rally_target = enemies[target_number]
	rally_target.damage += floor(rally_target.damage * (enemy.magic / 100.0))
	display_text("The %s is rallying and encouraging its allies!" % enemy.name)
	await self.textbox_closed
	display_text("The %s's damage has increased!" % rally_target.name)
	await self.textbox_closed
	rally_target.create_tooltip()

func enemy_stun(enemy):
	display_text("The %s tries to concuss you!" % enemy.name)
	await self.textbox_closed
	await enemy.play_animation("attack")

	if is_defending:
		is_defending = false
		$AnimationPlayer.play("mini_shake")
		display_text("Your minion took the attack for you!")
		await self.textbox_closed
	else:
		if randi() % 60 <= enemy.magic:
			stunned = true
			$AnimationPlayer.play("shake")
			display_text("You're stunned!")
			await self.textbox_closed
		else:
			$AnimationPlayer.play("mini_shake")
			display_text("You resist the stun!")
			await self.textbox_closed

#func enemy_shield(enemy):
	# couldn't get this to work in a satisfying way
	#display_text("The %s casts magical wards!" % enemy.name)
	#await self.textbox_closed
	#var shielding = floor(randf_range(0.5, 1.5) * enemy.magic)
	#for ally in enemies:
		#if not ally.dead:
			#ally.recieve_shielding(shielding)
	#display_text("Everyone is now shielded!")
	#await self.textbox_closed

func enemy_hide(enemy):
	var allys = 0
	for ally in enemies:
		if not ally.dead:
			allys += 1

	if allys <= 1:
		display_text("The %s attempts to hide but realizes they are the only ones left with no where to run he attacks!" % enemy.name)
		await self.textbox_closed
		await enemy_attack(enemy)
	else:
		if enemy.is_hiding == false:
			enemy.is_hiding = true
			display_text("The %s is hiding!" % enemy.name)
			await self.textbox_closed
			enemy.play_animation_player("hide")
			display_text("The %s can no longer be targetted!" % enemy.name)
			await self.textbox_closed
		else:
			display_text("The %s is biding their time!" % enemy.name)
			await self.textbox_closed
			enemy.modifier +=1

func enemy_hex(enemy):
	if hex_duration == 0: # Check if Hex can be applied
		display_text("The %s casts a Hex, weakening %s attacks!" % [enemy.name, user_name])
		await self.textbox_closed

		# Apply the Hex effect
		var hex_percent = 0.25 # Reduce damage to 75% of its original value
		hex_damage = hex_percent * Boss_damage
		Boss_damage -= hex_damage
		hex_duration = 2 # Hex lasts for 2 rounds

		display_text("The %s attack power has been diminshed!" %user_name)
		await self.textbox_closed
	else:
		await enemy_attack(enemy)

func enemy_redirect(enemy):
	redirect_active = true
	redirect_target = enemy  # This enemy becomes the target for the next attack

	display_text("The %s will redirect the next attack to themselves and attempt to absorb the damage!" % enemy.name)
	await self.textbox_closed

func handle_redirect(target, damage):
	if not redirect_active:
		return damage  # No redirection or self-redirect, return original damage

	var magic_absorption = redirect_target.magic
	var absorbed_damage = min(damage, magic_absorption)  # Absorb up to magic_absorption
	var excess_damage = max(0, damage - absorbed_damage)

	if absorbed_damage > 0:
		display_text("The %s redirects and absorbs %d damage!" % [redirect_target.name, absorbed_damage])
		await self.textbox_closed

	if excess_damage > 0:
		display_text("Excess damage of %d bypasses the redirect!" % excess_damage)
		await self.textbox_closed
	else:
		display_text("All damage is absorbed by %s!" % redirect_target.name)
		await self.textbox_closed
		excess_damage = 0  # Ensure no negative values

	redirect_active = false  # Reset the redirect status after handling
	return excess_damage  # Return the damage after redirect calculation


func player_turn(player):
	# Implement the player's turn logic here
	if not stunned:
		update_tooltip()
		# print("my turn! draw!")
		$ActionsPanel.show()
		await self.action_taken
	else:
		display_text("You're stunned! Your turn will be skipped.")
		await self.textbox_closed
		stunned = false
	# Wait for the player to press the attack button
	# Player attacks adventurers
	# Add any other actions the player should take during their turn

func process():
	while not game_over:
		var actions = {}
		var turn_order = []

		$Timeline.visible = true
		for n in $Timeline/TurnList/TurnLabels.get_children():
			$Timeline/TurnList/TurnLabels.remove_child(n)
			n.queue_free()

		# Create a list of enemies with their corresponding accumulated time
		for character in all_characters:

			if !is_instance_valid(character) or !character.visible:
				continue

			actions[character.name] = []
			for i in range(1,101):
				var speed
				if character.name == "DemonLord":
					speed = Boss_speed
				else:
					speed = character.speed
				if i*speed > 100:
					break
				actions[character.name].append(i*speed)
		for i in range(0,101):
			for character in all_characters:
				if !is_instance_valid(character) or !character.visible or actions[character.name].is_empty() or actions[character.name][0]!=i:
					continue
				turn_order.append(character)

				var turnLabel = Label.new()
				turnLabel.text = "[%d] %s" % [i, character.name]
				var font = FontFile.new()
				font.font_data = load("res://fonts/NESCyrillic.ttf")
				turnLabel.add_theme_font_override("font", font)
				$Timeline/TurnList/TurnLabels.add_child(turnLabel)

				actions[character.name].remove_at(0)
		for i in turn_order.size():
			var character = turn_order[i]
			if !is_instance_valid(character) or !character.visible:
				continue
			display_text("It's the %s's turn!" % character.name)
			await self.textbox_closed

			for turnLabel in $Timeline/TurnList/TurnLabels.get_children():
				if turnLabel.text.get_slice(" ", 1) == character.name and not turnLabel.has_theme_color_override("font_color"):
					turnLabel.add_theme_color_override("font_color", Color.AQUA)
					break
				else:
					turnLabel.add_theme_color_override("font_color", Color.WHITE)

			if character.name == 'DemonLord':
				# Check if the Dempn Lord is returning from a "Red Rush" dive
				if is_flying:
					# Apply the Red Rush damage
					display_text("Diving from the skies, %s strikes %s for %d damage!" % [user_name, red_rush_target.name, red_rush_damage])
					await self.textbox_closed
					$RedRushSound2.play()
					fly_away.play("fly_back")
					await fly_away.animation_finished
					red_rush_damage = await handle_redirect(red_rush_target, red_rush_damage)
					await red_rush_target.took_damage(red_rush_damage, "red rush")
					await check_win()
					if game_over:
						break
					is_flying = false  # Reset flying status
					red_rush_target = null
					red_rush_damage = 0
				await player_turn(character)
				await end_of_turn()
			else:
				await enemy_turn(character)
				await check_win()
#			await household_passive()		# We do not need this active is turned off right now
			if game_over:
				break
		display_text("End of round")
		await self.textbox_closed

	if game_over:
		end_game()

func end_game():
	$PlayerPanel.visible = false
	if State.current_health == 0:
		display_text("Against all odds, the heroes have won.")
		await self.textbox_closed
		display_text("The world will see a new age of peace and prosperity.")
		await self.textbox_closed
		display_text("And they'll live happily ever after...")
		await self.textbox_closed
		display_text("For now.")
		await self.textbox_closed
		start_fade_out("res://MainScenes/start_menu.tscn")
	else:
		display_text("Against your unstoppable might, the heroes have lost.")
		await self.textbox_closed
		if State.currentBattle >= 10:
			display_text("The world will see a dark age under the rule of %s." %user_name)
			await self.textbox_closed
			display_text("The living will suffer, and the dead will rise.")
			await self.textbox_closed
			display_text("And that is...")
			await self.textbox_closed
			display_text("The End.")
			await self.textbox_closed
			start_fade_out("res://MainScenes/start_menu.tscn")
		else:
			State.save_player_data()
			start_fade_out("res://MainScenes/campfire.tscn")

func display_text(text):
	if $ActionsPanel.visible:
		$ActionsPanel.hide()
	$Textbox.show()
	$Textbox/Label.text = text



func select_enemy():
	display_text("Select a target.")
	await self.textbox_closed
	for enemy in enemies:
		if not enemy.is_hiding:
			enemy.get_node("Button").show()
	await self.target_selected

func stop_selecting():
	for enemy in enemies:
		enemy.get_node("Button").hide()
	emit_signal("target_selected")

func _input(event):
	#if (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and $Textbox.visible:
	if Input.is_action_just_released("click") and $Textbox.visible:
		$Textbox.hide()
		emit_signal("textbox_closed")
	# Player attcks adventurers
	# Add any other actions the player should take during their turn

func ready_spells():
	for tier in 4:
		var spell_name = "Not yet\nunlocked"
		if State.spells_unlocked[tier] != "":
			spell_name = State.spells_unlocked[tier].replace(" ", "\n")
		get_node("TierSpellsPanel/TierSpells/%s" % str(tier+1)).text = spell_name

# Deprecated, use take_lifesteal() instead
#VAMP LORD SKILLS 356-720
#func life_steal(damage: int) -> float:
	#var life_steal_amt = 0.0
	#if vampiric_frenzy_active:
		#life_steal_amt = damage # If vampiric frenzy is active, use full damage for life steal
	#else:
		#life_steal_amt = damage * 0.25 # Otherwise, steal 25% of damage dealt
#
	#var actual_life_steal = 0.0 # The actual amount of health restored, considering max health limit
	#
	## Calculate how much health can actually be restored without exceeding max health
	#if (State.current_health + life_steal_amt > State.max_health):
		#actual_life_steal = State.max_health - State.current_health
		#State.current_health = State.max_health
	#else:
		#actual_life_steal = life_steal_amt
		#State.current_health += actual_life_steal
#
	#set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
	#
	#return actual_life_steal

func no_valid_target() -> bool:
	var no_valid = true
	for enemy in enemies:
		if not enemy.dead and not enemy.is_hiding:
			no_valid = false
	if no_valid:
		display_text("There is no valid target for this spell.")
		await self.textbox_closed
	return no_valid

func _on_blood_siphon_pressed():
	var LowDamageRange = 0.8
	var HighDamageRange = 1.1
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()
	if vampiric_frenzy_active:
		LowDamageRange *= 1.5
		HighDamageRange *= 1.5

	var enemy_defending = false	
	if target == null:
		await select_enemy()
	else:
		display_text("The %s senses the impending danger and prepares to counter!" % target.name)
		enemy_defending = true
		await self.textbox_closed

	if is_defending == true:
		LowDamageRange *= 0.5
		HighDamageRange *= 0.5
	if enemy_defending == true:
		LowDamageRange *= 0.75
		HighDamageRange *= 0.75

	# Calculate Blood Siphon damage within a low to medium range
	var blood_siphon_damage = floor(Boss_damage * randf_range(LowDamageRange, HighDamageRange))
	blood_siphon_damage = await handle_redirect(target, blood_siphon_damage) # Adjust the range based on desired spell power
	$VL_BS_Sound.play()
	await target.took_damage(blood_siphon_damage, "blood siphon")

	display_text("The %s cast Blood Siphon, you drain the life force of your enemy dealing %s damage." % [user_name, blood_siphon_damage])
	await self.textbox_closed

	await take_lifesteal(blood_siphon_damage, 0.25, "You have regenerated %d health.")

	if vampiric_frenzy_active and randf() < 0.5:
		apply_noble_charm(target)
		display_text("Vampiric Frenzy charmed %s." %target.name)
		await self.textbox_closed
	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)  # Remove the target from the enemies list
		await check_win()

	target = null
	emit_signal("action_taken")


func household_passive():
	var available_targets = get_available_targets()
	if available_targets.size() == 0:
		# No available targets, possibly due to invisibility or other conditions.
		return

	if not State.household_passive_active:
		return

	var LowDamageRange = 0.4
	var HighDamageRange = 0.6
	if vampiric_frenzy_active:
		LowDamageRange *= 1.2
		HighDamageRange *= 1.2

	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()

	display_text("Household has activated choose a sacrificial target.")
	await self.textbox_closed

	# Select an enemy from available targets.
	await select_enemy()  # This should now ensure there's at least one target available.

	if target == null:
		display_text("Household passive activated, but no target was selected.")
		await self.textbox_closed
		return  # Exit if no target was selected after all.

	var HP_dmg = floor(Boss_damage * randf_range(LowDamageRange, HighDamageRange))
	$VL_HH_Sound.play()
	await target.took_damage(HP_dmg)

	display_text("Your bat has been summoned and flew at %s dealing %s damage, and restoring %s health" % [target.name, HP_dmg, HP_dmg])
	await self.textbox_closed

	take_lifesteal(HP_dmg, 1, "Your bat sacrificed itself so you could fight on, gaining %s health")

	if vampiric_frenzy_active and randf() < 0.5:
		apply_noble_charm(target)
		display_text("Vampiric Frenzy charmed %s." % target.name)
		await self.textbox_closed

	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)  # Remove the target from the enemies list
		target.queue_free()  # Optionally remove the enemy node from the scene
		await check_win()  # Check if this triggers a win condition

	target = null  # Clear the current target
	emit_signal("action_taken")


func _on_red_rush_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if red_rush_cd > 0:
		display_text("Red Rush is still on cooldown for %d more turns." % red_rush_cd)
		await  self.textbox_closed
		return

	if is_flying:
		display_text("You are already flying and cannot use Red Rush again.")
		await self.textbox_closed
		return
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()
	display_text("Select a target for Red Rush.")
	await select_enemy()

	if target == null:
		display_text("No target was selected for Red Rush.")
		await self.textbox_closed
		return

	red_rush_damage = floor(Boss_damage * randf_range(0.8, 1.4))
	
	if vampiric_frenzy_active:
		red_rush_damage *= 1.5
	if is_defending == true:
		red_rush_damage *= 0.5
	
	red_rush_target = target
	is_flying = true

	display_text("%s spreads their wings and takes to the skies, becoming untouchable." %user_name)
	await self.textbox_closed

	$RedRushSound1.play()
	$DemonLord/EffectAnimation.play("red rush")
	fly_away.play("fly_away")

	red_rush_cd = 3
	target = null
	emit_signal("action_taken")


func _on_noble_charm_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()


	if noble_charm_cd > 0:
		display_text("Noble Charm is still on cooldown for %d more turns." % noble_charm_cd)
		await self.textbox_closed
		return
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()
	display_text("Select an enemy to bewitch with Noble Charm.")
	await select_enemy()
	if target != null:
		$VL_NC_Sound.play()
		apply_noble_charm(target)
		display_text("The %s is now charmed and will attack their allies!" % target.name)
		noble_charm_cd = 3  # Set the cooldown
		await self.textbox_closed
	else:
		display_text("No target was selected for Noble Charm.")
		await self.textbox_closed
	target = null
	emit_signal("action_taken")


func _on_vampiric_frenzy_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if vampiric_frenzy_cd > 0:
		display_text("Vampiric Frenzy is still on cooldown for %d more turns" %vampiric_frenzy_cd)
		await self.textbox_closed
		return
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()
	activate_vampiric_frenzy()
	$DemonLord/EffectAnimation.play("vampiric frenzy")
	$VL_VF_Sound.play()
	display_text("Vampiric Frenzy activated! Vampire Lord abilities will now heal you for 100% of the damage you deal and have a chance 50% to charm the enemy.")
	await self.textbox_closed
	emit_signal("action_taken")


func activate_vampiric_frenzy():
	vampiric_frenzy_active = true
	vampiric_frenzy_cd = 5


func apply_noble_charm(target):
	if "noble_charm" not in target.debuffs:
		target.get_node("EffectAnimation").play("noble charm")
		target.debuffs["noble_charm"] = [3, 0]  # Lasts for 3 turns/actions

func end_of_turn():
	if shattering_strike_cd > 0:
		shattering_strike_cd -= 1
	if counter_cd > 0:
		counter_cd -= 1
	if guillotine_cd > 0:
		guillotine_cd -= 1
	if true_form_cd > 0:
		true_form_cd -= 1

	if red_rush_cd > 0:
		red_rush_cd -= 1
	if noble_charm_cd > 0:
		noble_charm_cd -= 1
	if vampiric_frenzy_cd > 0:
		vampiric_frenzy_cd -= 1

	if fire_rain_cd > 0:
		fire_rain_cd -= 1
	if meteor_cd > 0:
		meteor_cd -= 1
	if hell_on_earth_cd > 0:
		hell_on_earth_cd -= 1

	if hex_duration > 0:
		hex_duration -= 1
		if hex_duration == 0:
			Boss_damage += hex_damage
			display_text("You recovered from the Hex, gaining back your power.")
			await self.textbox_closed

#Inferno Spells 738-888
func _on_fireball_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if await no_valid_target():
		return

	$TierSpellsPanel.hide()

	var enemy_defending = false
	if target == null:
		await select_enemy()
	else:
		display_text("You conjure a mighty fireball and hurl it at %s!" % target.name)
		await self.textbox_closed
		enemy_defending = true
	$FireballSound.play()
	# Calculate fireball damage within a medium range
	var fireball_damage = floor(Boss_damage * randf_range(0.7, 1.0))
	
	if vampiric_frenzy_active:
		fireball_damage *= 1.2
	if is_defending == true:
		fireball_damage *= 0.5
	if enemy_defending == true:
		fireball_damage *= 0.75
	
	fireball_damage = await handle_redirect(target, fireball_damage) # Adjust the range based on desired spell power
	await target.took_damage(fireball_damage, "fireball")

	display_text("The fireball hits the %s, dealing %d damage." % [target.name, fireball_damage])
	await self.textbox_closed

	await take_lifesteal(fireball_damage)

	# Apply Scorched Earth debuff
	var dot_damage = floor(Boss_damage * 0.15) # Damage over time effect
	target.DOT += dot_damage # Set the DOT value on the enemy
	target.apply_debuff("Scorched Earth", 2, dot_damage) # Apply debuff for 3 turns

	display_text("The ground beneath %s scorches, igniting them with a lingering flame!" % target.name)
	await self.textbox_closed
	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)  # Remove the target from the enemies list
		await check_win()
	target = null
	emit_signal("action_taken")

# NEXT TWO FUNCTIONS ARE HELPERS
# This function will return an array of selected targets up to a maximum number specified.
func select_multiple_targets(max_targets : int) -> Array:
	var selected_targets = []
	var available_targets = get_available_targets()
	var num_targets_to_select = min(available_targets.size(), max_targets)

	for i in range(num_targets_to_select):
		await select_enemy()
		if target != null:
			selected_targets.append(target)
			available_targets.erase(target)  # Ensure the same target cannot be selected again
			target = null  # Reset target for next selection
		else:
			display_text("No target was selected.")
			await self.textbox_closed
			break  # Exit the selection process if no target is selected

	return selected_targets

func get_available_targets():
	var targets = []
	for enemy in enemies:
		if not enemy.dead and not enemy.is_hiding:  # Assumed conditions for a target to be available
			targets.append(enemy)
	return targets

#BACK TO INFERNO SPELLS
func _on_fire_rain_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if fire_rain_cd > 0:
		display_text("Fire Rain is still on cooldown for %d more turns." % fire_rain_cd)
		await self.textbox_closed
		return
	if await no_valid_target():
		return

	$TierSpellsPanel.hide()

	# Use the function to select up to 2 targets
	var targets = await select_multiple_targets(2)
	var dead_enemies = [] # To track enemies that die due to this spell

	# Apply Fire Rain effects to the selected targets
	for target in targets:
		var fire_rain_damage = floor(Boss_damage * randf_range(0.5, 0.8)) # Adjust damage range as desired
		if vampiric_frenzy_active:
			fire_rain_damage *= 1.2
		if is_defending == true:
			fire_rain_damage *= 0.5
		fire_rain_damage = await handle_redirect(target, fire_rain_damage)
		$FireRainSound.play()
		var is_dead = await target.took_damage(fire_rain_damage, "firerain") # Assume took_damage can return a death boolean
		target.DOT += floor(Boss_damage * 0.15) # Apply one stack of DOT
		target.apply_debuff("Scorched Earth", 2, Boss_damage * 0.15) # Apply debuff for 3 turns

		display_text("Fire rains down upon %s, dealing %d damage and scorching the earth!" % [target.name, fire_rain_damage])
		await self.textbox_closed

		if is_dead:
			dead_enemies.append(target) # Collect dead enemies for later removal

	# Safely remove dead enemies after applying effects
	for dead_enemy in dead_enemies:
		enemies.erase(dead_enemy)

	await check_win() # Check for a win condition after all effects and removals

	fire_rain_cd = 3 # Reset the spell's cooldown
	emit_signal("action_taken")



func _on_meteor_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if meteor_cd > 0:
		display_text("Meteor is still on cooldown for %d more turns." % meteor_cd)
		await self.textbox_closed
		return
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()
	# Use the new function to select up to 3 targets
	var targets = await select_multiple_targets(3)
	var dead_enemies = [] # To track enemies that are killed by this spell

	# Apply Meteor effects to the selected targets
	for target in targets:
		var meteor_damage = floor(Boss_damage * randf_range(0.8, 1.2))
		if vampiric_frenzy_active:
			meteor_damage *= 1.2
		if is_defending == true:
			meteor_damage *= 0.5
		meteor_damage = await handle_redirect(target, meteor_damage) # Assume this adjusts damage as needed
		$MeteorSound.play()
		var is_dead = await target.took_damage(meteor_damage, "meteor") # Assume took_damage returns a boolean for death
		target.apply_debuff("Scorched Earth", 2, 0) # Apply debuff

		display_text("A meteor strikes %s, dealing %d damage and scorching the earth!" % [target.name, meteor_damage])
		await self.textbox_closed

		if is_dead:
			dead_enemies.append(target) # Add dead target to the list for later removal

	# Remove dead enemies after applying damage to all targets
	for dead_enemy in dead_enemies:
		enemies.erase(dead_enemy)

	await check_win() # Check win condition after all effects are processed

	meteor_cd = 3 # Set the ability's cooldown
	emit_signal("action_taken")


func _on_hell_on_earth_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if hell_on_earth_cd > 0:
		display_text("Hell on Earth is still on cooldown for %d more turns." % hell_on_earth_cd)
		await self.textbox_closed
		return
	$TierSpellsPanel.hide()
	hell_on_earth_cd = 6
	hell_on_earth_active = true

	var targets = get_available_targets()
	var dead_enemies = [] # To track enemies that die due to this spell

	for target in targets:
		$HellOnEarthSound.play()
		$DemonLord/HellOnEarth.play("default")
		var hell_on_earth_dmg = floor(Boss_damage * randf_range(0.3, 0.5)) # Adjust range as desired
		if vampiric_frenzy_active:
			hell_on_earth_dmg *= 1.2
		if is_defending == true:
			hell_on_earth_dmg *= 0.5
		hell_on_earth_dmg = await handle_redirect(target, hell_on_earth_dmg)
		var is_dead = await target.took_damage(hell_on_earth_dmg) # Assume took_damage returns a boolean indicating if the target died
		target.DOT += floor(Boss_damage * 0.25) # Apply one stack of DOT immediately
		target.apply_debuff("Scorched Earth", 4, Boss_damage * 0.25)
		if is_dead:
			dead_enemies.append(target)

	display_text("A giant chasm tears open as you unleash Hell on Earth!")
	await self.textbox_closed

	# Remove dead enemies after damage application
	for dead_enemy in dead_enemies:
		enemies.erase(dead_enemy) # Now safely removing dead enemies

	await check_win() # Check win condition after all effects are processed
	emit_signal("action_taken")

func _on_defend_pressed():
	is_defending = true
	display_text("You summon a minion to defend you! However, you'll do less damage this turn.")
	await self.textbox_closed
	$ActionsPanel.show()

func _on_dread_forge_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	$SpellSound2.play()
	display_text("You have become stronger!")
	await self.textbox_closed
	Boss_damage *= 1.25
	emit_signal("action_taken")

func _on_attack_pressed():
	$ActionsPanel.hide()
	if await no_valid_target():
		return
	$SpellsPanel.hide()
	var enemy_defending = false
	if target == null:
		await select_enemy()
	else:
		display_text("The %s rushed in to defend their allies!" % target.name)
		await self.textbox_closed
		enemy_defending = true

	#var final_damage = State.damage
	var final_damage = randf_range(0.5, 1.5) * Boss_damage
	if vampiric_frenzy_active:
		final_damage *= 1.2
	if is_defending == true:
		final_damage *= 0.5
	if enemy_defending == true:
		final_damage *= 0.75
	final_damage = await handle_redirect(target, floor(final_damage))

	$SpellSound1.play()
	await target.took_damage(final_damage)
	display_text("You shoot out a dark magical blast!")
	await self.textbox_closed

	display_text("You dealt %d damage to the %s!" % [final_damage, target.name])
	await self.textbox_closed

	await take_lifesteal(final_damage)

	if vampiric_frenzy_active and randf() < 0.5:
		apply_noble_charm(target)
		display_text("Vampiric Frenzy charmed %s." %target.name)
		await self.textbox_closed
	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)
		await check_win()
	target = null
	emit_signal("action_taken")

func _on_Items_pressed():
	$ActionsPanel.hide()
	display_text("You're the final boss! Why would you need items?")
	await self.textbox_closed
	$ActionsPanel.show()

func _on_spells_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.show()

func _on_infernal_affliction_pressed():
	$ActionsPanel.hide()
	if await no_valid_target():
		return
	$SpellsPanel.hide()
	if target == null:
		await select_enemy()
	else:
		display_text("The %s rushed in to defend its allies!" % target.name)
		await self.textbox_closed
	
	var dotdamage = 0
	if vampiric_frenzy_active:
		dotdamage = floor(Boss_damage / 3) * 1.2
	else:
		dotdamage += floor(Boss_damage / 3)
	target.DOT += dotdamage
	$SpellSound3.play()
	display_text("The %s is engulfed in hellfire!" % target.name)
	await self.textbox_closed
	display_text("The %s will take %s damage on each of its turns!" % [target.name, target.DOT])
	await self.textbox_closed


	target.apply_debuff("Infernal Afliction", 100, dotdamage)  # Assuming a duration of 5 turns
	target = null
	emit_signal("action_taken")

func _on_shattering_strike_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if shattering_strike_cd > 0:
		display_text("Shattering Strike is still on cooldown for %d more turns." % [shattering_strike_cd])
		await self.textbox_closed
		return
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()
	var enemy_defending = false
	if target == null:
		await select_enemy()
	else:
		display_text("The %s rushed in to defend their allies!" % target.name)
		await self.textbox_closed
		enemy_defending = true

	var final_damage = randf_range(0.5, 1.0) * Boss_damage
	if vampiric_frenzy_active:
		final_damage *= 1.2
	if is_defending == true:
		final_damage *= 0.5
	if enemy_defending == true:
		final_damage *= 0.75
	final_damage = floor(final_damage)

	final_damage = await handle_redirect(target, final_damage)

	if target.type == "Defender":
		$dk_spell_1_metal.play()
	else:
		$dk_spell_1_thud.play()
	await target.took_damage(final_damage, "shattering strike")

	display_text("You delivered a Shattering Strike to %s!" % target.name)
	await self.textbox_closed

	display_text("You dealt %d damage to the %s!" % [final_damage, target.name])
	await self.textbox_closed

	await take_lifesteal(final_damage)

	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)
		await check_win()
	else:
		target.stunned_turn += 1 + true_form
		display_text("%s is stunned!" % target.name)
		await self.textbox_closed

	shattering_strike_cd = 2
	target = null
	emit_signal("action_taken")

func _on_counter_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if counter_cd > 0:
		display_text("Counter is still on cooldown for %d more turns." % [counter_cd])
		await self.textbox_closed
		return
	$TierSpellsPanel.hide()
	$DemonLord/EffectAnimation.play("counter cast")
	$dk_spell_2_guard.play()
	countering_turn += 1 + true_form
	display_text("You deftly execute Counter, turning the next enemy's attack against them with twice the force!")
	await self.textbox_closed
	counter_cd = 3
	emit_signal("action_taken")

func _on_guillotine_pressed(recast = false):
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if !recast and guillotine_cd > 0:
		display_text("Guillotine is still on cooldown for %d more turns." % [guillotine_cd])
		await self.textbox_closed
		return
	if await no_valid_target():
		return
	$TierSpellsPanel.hide()
	var enemy_defending = false
	if target == null:
		await select_enemy()
	elif !recast:
		display_text("The %s rushed in to defend their allies!" % target.name)
		await self.textbox_closed
		enemy_defending = true

	var final_damage = randf_range(0.5, 1.5) * Boss_damage
	if vampiric_frenzy_active:
		final_damage *= 1.2
	if is_defending == true:
		final_damage *= 0.5
	if enemy_defending == true:
		final_damage *= 0.75

	if target.current_health <= guillotine_upperbound * target.health:
		final_damage *= 2
		display_text("The target's health dwindles below 25%, unleashing the full might of Guillotine.")
		await self.textbox_closed
	final_damage = floor(final_damage)

	final_damage = await handle_redirect(target, final_damage)

	$SpellSound1.play() # TODO: add sound
	await target.took_damage(final_damage, "guillotine")

	display_text("You dealt %d damage to the %s!" % [final_damage, target.name])
	await self.textbox_closed

	await take_lifesteal(final_damage)

	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)
		await check_win()
		if !game_over:
			var living_enemies = []
			for enemy in enemies:
				if !enemy.dead:
					living_enemies.append(enemy)
			display_text("Your blade slicing through the air with deadly precision, ready to strike again at the next unfortunate target.")
			await self.textbox_closed
			target = living_enemies[randi() % living_enemies.size()]
			await _on_guillotine_pressed(true)
	guillotine_cd = 3
	target = null
	emit_signal("action_taken")

func _on_true_form_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	if true_form_cd > 0:
		display_text("True Form is still on cooldown for %d more turns." % [true_form_cd])
		await self.textbox_closed
		return
	$TierSpellsPanel.hide()
	$DemonLord/EffectAnimation.play("true form")
	$SpellSound2.play() # TODO: Add sound
	display_text("You embraced your True Form.")
	await self.textbox_closed
	Boss_damage *= ceil(Boss_damage * 1.5)
	Boss_speed = ceil(Boss_speed / 1.5)
	Boss_magic *= ceil(Boss_magic * 1.5)
	Boss_lifesteal += 0.2
	true_form += 1
	guillotine_upperbound = 0.35
	true_form_cd = 6
	emit_signal("action_taken")

func take_lifesteal(damage, temp_lifesteal = 0.0, text = ""):
	Boss_lifesteal += temp_lifesteal
	if vampiric_frenzy_active:
		Boss_lifesteal += 1
	if Boss_lifesteal > 0 and State.max_health != State.current_health:
		var health_restored = min(State.max_health - State.current_health, floor(damage * Boss_lifesteal))
		if health_restored == 0:
			Boss_lifesteal -= temp_lifesteal
			return
		State.current_health += health_restored
		set_health(get_node("/root/Battle/PlayerPanel/ProgressBar"), State.current_health, State.max_health)
		if text != "":
			display_text(text % health_restored)
		else:
			display_text("You restored %d health." % health_restored)
		await textbox_closed
	Boss_lifesteal -= temp_lifesteal
	if vampiric_frenzy_active:
		Boss_lifesteal -= 1

func _on_back_pressed():
	$ActionsPanel.show()
	$SpellsPanel.hide()

func _on_vamp_spells_pressed():
	$SpellsPanel.hide()
	$TierSpellsPanel.show()

func _on_back_to_spells_pressed():
	$TierSpellsPanel.hide()
	$SpellsPanel.show()

func _on_tier_pressed(extra_arg_0):
	var spell_name = State.spells_unlocked[extra_arg_0 - 1]
	if spell_name != "":
		spell_name = "_on_" + spell_name.to_snake_case() + "_pressed"
		var spell_func = Callable(self, spell_name)
		spell_func.call()
	else:
		display_text("You haven't unlocked a spell of tier %s yet!" % extra_arg_0)
		await self.textbox_closed


func _on_bg_music_finished():
	$BGMusic.play()
