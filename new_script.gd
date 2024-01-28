extends Control

signal textbox_closed
var current_player_health = 30
@export var enemies: Array = []

class Enemy:
	var name: String = ""
	var damage: int = 0
	var speed: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
	
	var new_enemy: Enemy = Enemy.new()
	new_enemy.name = 'player1'
	new_enemy.damage = 1
	new_enemy.speed = 50
	enemies.append(new_enemy)

	var new_enemy2: Enemy = Enemy.new()
	new_enemy2.name = 'player2'
	new_enemy2.damage = 2
	new_enemy2.speed = 30
	enemies.append(new_enemy2)

	var new_enemy3: Enemy = Enemy.new()
	new_enemy3.name = 'player3'
	new_enemy3.damage = 3
	new_enemy3.speed = 20
	enemies.append(new_enemy3)

	$Textbox.hide()
	$ActionsPanel.hide()
	
	display_text("The adventurers approach!")
	await textbox_closed
	$ActionsPanel.show()

func set_health(progress_bar, health, max_health):
	progress_bar.value = health
	progress_bar.max_value = max_health
	progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]

func enemy_turn(enemy):
	display_text("%s launches at you fiercely!" % enemy.name)
	State.current_health = max(0, State.current_health - enemy.damage)
	set_health($PlayerPanel/ProgressBar, State.current_health, State.max_health)
	display_text("%s dealt %d damage!" % [enemy.name, enemy.damage])
	if State.current_health == 0:
		display_text("You died")
		get_tree().quit()

func _process(delta):
	pass

func display_text(text):
	$Textbox.show()
	$Textbox/Label.text = text
	await self.textbox_closed

func _input(event):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and $Textbox.visible:
		emit_signal("textbox_closed")

func _on_attack_pressed():
	display_text("You swing your piercing sword!")
	
	$AnimationPlayer.play("enemy_damaged")
	await $AnimationPlayer.animation_finished
	
	display_text("enemies' turn begin!")
	
	# Iterate through each enemy and let them take their turn
	for enemy_instance in enemies:
		display_text("%s's turn!" % [enemy_instance.name])
		await enemy_turn(enemy_instance)
	
	$ActionsPanel.show()
