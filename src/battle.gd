extends Control
signal textbox_closed
signal action_taken
signal target_selected
@export var characters = {}
var enemies
var num_current_enemies
var all_characters
var is_defending = false
var game_over = false
var second_phase = false
var target = null
var stunned = false
var Boss_damage = State.damage
var noble_charm_cd = 0
var vampiric_frenzy_active = false
var vampiric_frenzy_cd = 0

func _ready():
	
	set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
	State.currentBattle += 1
	$DemonLord.play("idle")
	$BGMusic.play()
	
	randomize()
	enemies = choose_random_enemies()
	all_characters = enemies.duplicate()
	all_characters.append($DemonLord)
	
	var screen_resolution = get_tree().root.content_scale_size # (1152, 648)
	for i in len(enemies):
		enemies[i].get_ready()
		enemies[i].position = Vector2(screen_resolution.x / (num_current_enemies + 1) * (i + 1), screen_resolution.y / 2)
		# temporary alignment of enemies
	
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	$VampSpellsPanel.hide()
	display_text("Summoned by your loyal cultists, you, the Demon Lord, have awoken!")
	await self.textbox_closed
	display_text("These %s adventurers wish to return you to your eternal slumber." % num_current_enemies)
	await self.textbox_closed
	display_text("This is the final battle!")
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
	$SpellsPanel/Spells/dreadforge.tooltip_text = "Increases your damage by %s%% for the remainder of the battle." % State.magic
	$SpellsPanel/Spells/InfernalAffliction.tooltip_text = "Traps one target in a ring of fire, which deals %s damage on each of its turns." % floor(Boss_damage / 3)

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
	# Check if the enemy is charmed and the charm effect should trigger this turn
	if enemy.has_debuff("noble_charm"):
		display_text("%s is under the charms influence and ready to serve" % enemy.name)
		await self.textbox_closed
		var ally = select_random_ally(enemy)
		if ally:
			var damage = calculate_damage(enemy, ally)  # Implement based on your game's logic
			ally.took_damage(damage)
			display_text("%s attacks %s for %d damage." % [enemy.name, ally.name, damage])
			await  self.textbox_closed
			enemy.reduce_debuff_duration("noble_charm")
			if ally.dead:
				display_text("The %s killed the %s!" % [enemy.name, ally.name])
				await self.textbox_closed
				enemies.erase(target)  # Remove the target from the enemies list
		
		else:
			display_text("%s is charmed but has no allies to attack!" % enemy.name)
			await self.textbox_closed
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
		else:
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

#this is for a charmed enemy to select a random enemy that is not them selves
func select_random_ally(charmed_enemy):
	var potential_allies = enemies.duplicate()  # Assuming 'enemies' is an Array of nodes
	potential_allies.erase(charmed_enemy)  # Remove the charmed enemy from the list
	
	if potential_allies.is_empty():
		return null  # Return null if no allies are left for selection
	
	var random_index = randi() % potential_allies.size()  # Select a random index
	return potential_allies[random_index]  # Return the randomly selected ally


func calculate_damage(attacker, target) -> int:
	var final_damage = floor(randf_range(0.5 + attacker.modifier, 1.5 + attacker.modifier) * attacker.damage)
	final_damage = max(final_damage, 0)
	return final_damage


func enemy_attack(enemy):
	if enemy.is_hiding:
		display_text("The %s reveals themselves!" % enemy.name)
		await self.textbox_closed
		await enemy.play_animation_player("reveal")
		enemy.modifier += 1
		enemy.is_hiding = false
	display_text("The %s attacks!" % enemy.name)
	await self.textbox_closed
	await enemy.play_animation("attack")
	
	if is_defending:
		is_defending = false
		$AnimationPlayer.play("mini_shake")
		display_text("Your minion took the attack for you!")
		await self.textbox_closed
	else:
		var final_damage = floor(randf_range(0.5 + enemy.modifier, 1.5 + enemy.modifier) * enemy.damage)
		State.current_health = max(0, State.current_health - final_damage)
		set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
		
		$AnimationPlayer.play("shake")
		display_text("The %s dealt %d damage!" % [enemy.name, final_damage])
		await self.textbox_closed
		
		if State.current_health==0:
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
	var actions = {}
	var turn_order = []
	# Create a list of enemies with their corresponding accumulated time
	for character in all_characters:
		actions[character.name] = []
		for i in range(1,101):
			var speed
			if character.name == "DemonLord":
				speed = State.speed
			else:
				speed = character.speed
			if i*speed > 100:
				break
			actions[character.name].append(i*speed)
	for i in range(0,101):
		for character in all_characters:
			if actions[character.name].is_empty() or actions[character.name][0]!=i:
				continue
			turn_order.append(character) 
			actions[character.name].remove_at(0)
			#actions[character.name].remove(actions[character.name][0])
# Define the custom comparison function
	while not game_over:
		for i in turn_order.size():
			var character = turn_order[i]
			if !character.visible:
				continue
			display_text("It's the %s's turn!" % character.name)
			await self.textbox_closed
			if character.name != 'DemonLord':
				await enemy_turn(character)
			else:
				var next = i + 1
				var current_health
				if next < turn_order.size():
					if turn_order[next].name == 'DemonLord':
						current_health = State.current_health
					else:
						current_health = turn_order[next].current_health
				while next < turn_order.size() and current_health == 0:
					next = next + 1
				if next < turn_order.size():
					display_text("The next character taking action is %s" % turn_order[next].name)
					await self.textbox_closed
				$ActionsPanel.show()
				await player_turn(character)
				await household_passive()
				end_of_turn()
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
		get_tree().change_scene_to_file("res://MainScenes/start_menu.tscn")
	else:
		display_text("Against your unstoppable might, the heroes have lost.")
		await self.textbox_closed
		if State.currentBattle >= 10:
			display_text("The world will see a dark age under your rule.")
			await self.textbox_closed
			display_text("The living will suffer, and the dead will rise.")
			await self.textbox_closed
			display_text("And that is...")
			await self.textbox_closed
			display_text("The End.")
			await self.textbox_closed
			get_tree().change_scene_to_file("res://MainScenes/start_menu.tscn")
		else:
			State.save_player_data()
			get_tree().change_scene_to_file("res://MainScenes/campfire.tscn")

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
	if (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and $Textbox.visible:
		$Textbox.hide()
		emit_signal("textbox_closed")

	# Player attcks adventurers
	# Add any other actions the player should take during their turn
	
	#VAMP LORD SKILLS 356-487pending
func life_steal(damage: int):
	State.current_health += damage
	if State.current_health > State.max_health:
		State.current_health = State.max_health
	
	# Assuming 'player_health_bar' is a reference to the ProgressBar node for the player's health
	set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
	
func _on_blood_siphon_pressed():
	var LowDamageRange = 0.8
	var HighDamageRange = 1.1
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	$VampSpellsPanel.hide()
	if vampiric_frenzy_active:
		LowDamageRange *= 1.5
		HighDamageRange *= 1.5

	if target == null:
		await select_enemy()
	else:
		display_text("The %s senses the impending danger and prepares to counter!" % target.name)
		await self.textbox_closed

	# Calculate Blood Siphon damage within a low to medium range
	var blood_siphon_damage = floor(Boss_damage * randf_range(LowDamageRange, HighDamageRange)) # Adjust the range based on desired spell power
	$VL_BS_Sound.play()
	await target.took_damage(blood_siphon_damage)
	
	display_text("You cast Blood Siphon, draining life from your foe.")
	await self.textbox_closed
	
	var life_steal = life_steal(blood_siphon_damage)

	display_text("You healed for %s by siphoning the blood of your enemy." %blood_siphon_damage)
	await self.textbox_closed
	
	display_text("Blood Siphon dealt %d damage to the %s." % [blood_siphon_damage, target.name])
	await self.textbox_closed
	
	if vampiric_frenzy_active and randf() < 0.5:
		apply_noble_charm(target)
		display_text("Vampiric Frenzy charmed %s." %target.name)
		await self.textbox_closed
	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)  # Remove the target from the enemies list
		target.queue_free()  # Optionally remove the enemy node from the scene
		await check_win()  # Check if this triggers a win condition
	
	target = null 
	emit_signal("action_taken")

func household_passive():
	if not State.household_passive_active:
		return
	var LowDamageRange = 0.4
	var HighDamageRange = 0.6
	if vampiric_frenzy_active:
		LowDamageRange *= 1.2
		HighDamageRange *= 1.2
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	$VampSpellsPanel.hide()
	display_text("Household has activated choose a sacraficial target.")
	await self.textbox_closed
	if target == null:
		await select_enemy()
	else:
		display_text("Household passive activated, but no target was selected.")
		await self.textbox_closed
	
	var HP_dmg = floor(Boss_damage * randf_range(LowDamageRange, HighDamageRange))
	$VL_HH_Sound.play()
	await target.took_damage(HP_dmg)
	display_text("Your bat has been summoned and flew at %s dealing %s damage, and restoring %s health" %[target.name, HP_dmg, HP_dmg])
	await self.textbox_closed
	
	var life_steal = life_steal(HP_dmg)
	set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
	
	display_text("Youre bat sacriced itself so you could fight on, gain %s health" %HP_dmg)
	await self.textbox_closed
	if vampiric_frenzy_active and randf() < 0.5:
		apply_noble_charm(target)
		display_text("Vampiric Frenzy charmed %s." %target.name)
		await self.textbox_closed	
	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		enemies.erase(target)  # Remove the target from the enemies list
		target.queue_free()  # Optionally remove the enemy node from the scene
		await check_win()  # Check if this triggers a win condition
	
	target = null  # Clear the current target
	emit_signal("action_taken")




func _on_noble_charm_pressed():
	$ActionsPanel.hide()
	$SpellsPanel.hide()

	
	if noble_charm_cd > 0:
		display_text("Noble Charm is still on cooldown for %d more turns." % noble_charm_cd)
		await self.textbox_closed
		return
	$VampSpellsPanel.hide()
	display_text("Select an enemy to bewitch with Noble Charm.")
	await select_enemy()
	if target != null:
		$VL_NC_Sound.play()
		apply_noble_charm(target)
		display_text("The %s is now charmed and will attack its allies!" % target.name)
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
	$VampSpellsPanel.hide()
	activate_vampiric_frenzy()
	$VL_VF_Sound.play()
	display_text("Vampiric Frenzy activated! Attacks will now heal you and have a chance to charm the enemy.")
	await self.textbox_closed
	emit_signal("action_taken")



func activate_vampiric_frenzy():
	vampiric_frenzy_active = true
	vampiric_frenzy_cd = 5

func apply_noble_charm(target):
	if "noble_charm" not in target.debuffs:
		target.debuffs["noble_charm"] = 3  # Lasts for 3 turns/actions

func end_of_turn():
	if noble_charm_cd > 0:
		noble_charm_cd -= 1
	if vampiric_frenzy_active:
		if vampiric_frenzy_cd > 0:
			vampiric_frenzy_cd -= 1
	



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
	final_damage = floor(final_damage)
	
	$SpellSound1.play()
	await target.took_damage(final_damage)
	display_text("You shoot out a dark magical blast!")
	await self.textbox_closed
	
	display_text("You dealt %d damage to the %s!" % [final_damage, target.name])
	await self.textbox_closed
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
	$SpellsPanel.hide()
	
	if target == null:
		await select_enemy()
	else:
		display_text("The %s rushed in to defend its allies!" % target.name)
		await self.textbox_closed
	if vampiric_frenzy_active:
		target.DOT += floor(Boss_damage / 3) * 1.2
	else:
		target.DOT += floor(Boss_damage / 3)
	$SpellSound3.play()
	display_text("The %s is engulfed in hellfire!" % target.name)
	await self.textbox_closed
	display_text("The %s will take %s damage on each of its turns!" % [target.name, target.DOT])
	await self.textbox_closed
	target = null
	emit_signal("action_taken")

func _on_back_pressed():
	$ActionsPanel.show()
	$SpellsPanel.hide()







func _on_vamp_spells_pressed():
	$SpellsPanel.hide()
	$VampSpellsPanel.show()


func _on_back_to_spells_pressed():
	$VampSpellsPanel.hide()
	$SpellsPanel.show()

