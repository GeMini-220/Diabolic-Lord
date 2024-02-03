extends CharacterBody2D
@onready var battle = get_node("/root/Battle")
@export var enemy: Resource = null
var dead = false
var health
var current_health
var damage
var speed
var actions
var current_action
var audio
var DOT = 0

func _ready():
	self.visible = false

func get_ready():
	self.visible = true
	battle.set_health($ProgressBar, enemy.health, enemy.health)
	$AnimatedSprite2D.sprite_frames = enemy.animation
	$AudioStreamPlayer2D.stream = enemy.audio
	health = enemy.health
	current_health = health
	damage = enemy.damage
	speed = enemy.speed
	actions = enemy.actions
	$Button.hide()

func took_damage(taken_damage) -> bool:
	current_health = max(0,current_health - taken_damage)
	battle.set_health($ProgressBar, current_health, health)
	
	$AnimationPlayer.play("damaged")
	await $AnimationPlayer.animation_finished
	
	if current_health == 0:
		$AnimationPlayer.play("died")
		await $AnimationPlayer.animation_finished
		self.visible = false
		dead = true
	return dead
	
func recieve_healing(healing):
	current_health = min(health, current_health + healing)
	battle.set_health($ProgressBar, current_health, health)
	
func turn():
	var target_number = randi() % actions.size()
	current_action = actions[target_number]

func play_animation():
	$AnimatedSprite2D.play("attack")
	await $AnimatedSprite2D.animation_finished
	$AudioStreamPlayer2D.play()

func _on_button_pressed():
	battle.target = self
	battle.stop_selecting()
