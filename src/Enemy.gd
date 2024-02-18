extends CharacterBody2D
@onready var battle = get_node("/root/Battle")
@export var enemy: Resource = null
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
var is_stunned = false
var modifier = 0

func _physics_process(_delta):
	# Add the gravity.
	pass

func get_ready():
	battle.set_health($ProgressBar, enemy.health, enemy.health)
	$AnimatedSprite2D.sprite_frames = enemy.animation
	$AudioStreamPlayer2D.stream = enemy.audio
	create_tooltip()

func create_tooltip():
	var actionString = ""
	for i in actions:
		actionString += str(i) + ". "
	actionString = actionString.capitalize()
	$Control.tooltip_text = "Name: %s\nDamage: %s\nSpeed: %s\nMagic: %s\nActions: %s" % [enemy.name, damage, speed, magic, actionString]

func took_damage(taken_damage) -> bool:
	current_health = max(0,current_health - taken_damage)
	battle.set_health($ProgressBar, current_health, health)
	
	await play_animation_player("damaged")
	
	if current_health == 0:
		await play_animation_player("died")
		self.visible = false
		dead = true
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
