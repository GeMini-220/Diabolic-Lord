extends CharacterBody2D
@onready var battle = get_node("/root/Battle")
@export var enemy: Resource = null
var dead = false
var health
var current_health
var damage
var speed
var magic
var actions
var current_action
var audio
var DOT = 0
var is_hiding = false
var modifier = 0

func _physics_process(_delta):
	# Add the gravity.
	pass

func get_ready():
	battle.set_health($ProgressBar, enemy.health, enemy.health)
	$AnimatedSprite2D.sprite_frames = enemy.animation
	$AudioStreamPlayer2D.stream = enemy.audio
	health = enemy.health
	current_health = health
	damage = enemy.damage
	speed = enemy.speed
	magic = enemy.magic
	actions = enemy.actions
	$Button.hide()

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
