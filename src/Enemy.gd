extends CharacterBody2D
@onready var battle = get_node("/root/Battle")
@export var enemy: Resource = null
@onready var type = enemy.type
@onready var health = enemy.health
@onready var current_health = health
@onready var damage = enemy.damage
@onready var speed = enemy.speed
@onready var magic = enemy.magic
@onready var actions = enemy.actions
var dead = false
var current_action
var audio
var DOT = 0
var is_hiding = false
var stunned_turn = 0
var modifier = 0
var debuffs = {}

func _ready():
	self.visible = false

func get_ready():
	self.visible = true
	battle.set_health($ProgressBar, enemy.health, enemy.health)
	$AnimatedSprite2D.sprite_frames = enemy.animation
	$AudioStreamPlayer2D.stream = enemy.audio
	create_tooltip()

func create_tooltip():
	var actionString = ""
	for i in actions:
		actionString += str(i) + ". "
	actionString = actionString.capitalize()
	$Control.tooltip_text = "Class: %s\nDamage: %s\nSpeed: %s\nMagic: %s\nActions: %s" % [enemy.name, damage, speed, magic, actionString]

func took_damage(taken_damage) -> bool:
	current_health = max(0,current_health - taken_damage)
	battle.set_health($ProgressBar, current_health, health)
	
	await play_animation_player("damaged")
	
	if current_health == 0:
		await play_animation_player("died")
		self.visible = false
		dead = true
		for turnLabel in get_node("/root/Battle/Timeline/TurnList/TurnLabels").get_children():
			if turnLabel.text.get_slice(" ", 1) == enemy.name:
				turnLabel.queue_free()
	return dead
	
func recieve_healing(healing):
	current_health = min(health, current_health + healing)
	battle.set_health($ProgressBar, current_health, health)

func recieve_shielding(shielding):
	health += shielding
	current_health += shielding
	battle.set_health($ProgressBar, current_health, health)
	
func turn():
	var target_number = randi() % actions.size()
	current_action = actions[target_number]

func play_animation(animation):
	$AnimatedSprite2D.play(animation)
	await $AnimatedSprite2D.animation_finished
	$AudioStreamPlayer2D.play()
	
func play_animation_player(animation):
	$AnimationPlayer.play(animation)
	await $AnimationPlayer.animation_finished

func _on_button_pressed():
	battle.target = self
	battle.stop_selecting()

func apply_debuff(name: String, duration: int, dotdamage: int):
	debuffs[name] = [duration, dotdamage]

func reduce_debuff_duration():
	var keys_to_delete = []
	for debuff in debuffs.keys():
		debuffs[debuff][0] -= 1
		if debuffs[debuff][0] <= 0:
			enemy.DOT = max(0, enemy.DOT - debuffs[debuff][1])
			keys_to_delete.append(debuff)
	for key in keys_to_delete:
		debuffs.erase(key)

func has_debuff(debuff_name: String) -> bool:
	return debuff_name in debuffs and debuffs[debuff_name][0] > 0
