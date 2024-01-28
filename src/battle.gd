extends Control
signal textbox_closed
signal action_taken
signal target_selected
@export var characters = {}
var enemies
var all_characters
var is_defending = false
var in_action = false
var Boss_damage = State.damage
var game_over = false
var second_phase = false
var target = null

func _ready():
	set_health($PlayerPanel/ProgressBar, State.max_health, State.max_health)
	
	$DemonLord.play("idle")
	$BGMusic.play()
	
	enemies = $Enemies.get_children()
	all_characters = enemies.duplicate()
	all_characters.append($DemonLord)
	
	for enemy in enemies:
		enemy.get_ready()
	
	$ActionsPanel.hide()
	$SpellsPanel.hide()
	display_text("Summoned by your loyal cultists, you, the Demon Lord, have awoken!")
	await self.textbox_closed
	display_text("These four adventurers wish to return you to your eternal slumber.")
	await self.textbox_closed
	display_text("This is the final battle!")
	await self.textbox_closed
	await process()

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
	await enemy.turn()
	
	if enemy.DOT > 0:
		await enemy.took_damage(enemy.DOT)
	if enemy.dead:
		display_text("The %s burned to death!" % enemy.name)
		await self.textbox_closed
		enemies.erase(enemy)
		await check_win()
	else:
		match enemy.current_action:
			"attack":
				await enemy_attack(enemy)
			"heal":
				await enemy_heal(enemy)

func enemy_attack(enemy):
	display_text("The %s attacks!" % enemy.name)
	await self.textbox_closed
	await enemy.play_animation()
			
	if is_defending:
		is_defending = false
		$AnimationPlayer.play("mini_shake")
		display_text("Your minion took the attack for you!")
		await self.textbox_closed
	else:
		var final_damage = floor(randf_range(0.5, 1.5) * enemy.damage)
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
		
		await enemy.play_animation()
		
		var healing = floor(randf_range(0.5, 1.5) * enemy.damage)
		heal_target.recieve_healing(healing)
		
		display_text("The %s healed the %s for %s!" % [enemy.name, heal_target.name, healing])
		await self.textbox_closed

func player_turn(player):
	# Implement the player's turn logic here
	print("my turn! draw!")
	$ActionsPanel.show()
	await self.action_taken
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
				while next < turn_order.size() and turn_order[next].current_health == 0:
					next = next + 1
				if next < turn_order.size():
					display_text("The next character taking action is %s" % turn_order[next].name)
					await self.textbox_closed
				
				$ActionsPanel.show()
				await player_turn(character)
			if game_over:
				break
		display_text("End of round")
		await self.textbox_closed
	if game_over:
		end_game()

func end_game():
	$PlayerPanel.hide()
	if State.current_health == 0:
		display_text("Against all odds, the heroes have won.")
		await self.textbox_closed
		display_text("The world will see a new age of peace and prosperity.")
		await self.textbox_closed
		display_text("And they'll live happily ever after...")
		await self.textbox_closed
		display_text("For now.")
		await self.textbox_closed
	else:
		display_text("Against your unstoppable might, the heroes have lost.")
		await self.textbox_closed
		display_text("The world will see a dark age under your rule.")
		await self.textbox_closed
		display_text("The living will suffer, and the dead will rise.")
		await self.textbox_closed
		display_text("And that is...")
		await self.textbox_closed
		display_text("The End.")
		await self.textbox_closed
	#get_tree().quit()

func display_text(text):
	if $ActionsPanel.visible:
		$ActionsPanel.hide()
	$Textbox.show()
	$Textbox/Label.text = text
	
func select_enemy():
	display_text("Select a target.")
	await self.textbox_closed
	for enemy in enemies:
		enemy.get_node("Button").show()
	#await get_tree().create_timer(5.0).timeout
	#if target == null:
		#var target_number = randi() % enemies.size()
		#target = enemies[target_number]
		#display_text("You took too long to decide.")
		#await self.textbox_closed
		#display_text("A demon lord should not hesitate!")
		#await self.textbox_closed
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
	
	var final_damage = randf_range(0.5, 1.5) * Boss_damage
	if is_defending == true:
		final_damage *= 0.5
	final_damage = floor(final_damage)
	
	await select_enemy()
	$SpellSound1.play()
	await target.took_damage(final_damage)
	display_text("You shoot out a dark magical blast!")
	await self.textbox_closed
	
	display_text("You dealt %d damage to the %s!" % [final_damage, target.name])
	await self.textbox_closed
	
	if target.dead:
		display_text("You killed the %s!" % target.name)
		await self.textbox_closed
		#enemies.remove_at(target_number)
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
	
	await select_enemy()
	
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
