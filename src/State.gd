extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
var Characters ={
	"player1":{"name":"player1", "damage":1, "speed":25, "HP":10, "Max_HP":10, "alive":true},
	
	"player2":{"name":"player2","damage":2, "speed":40, "HP":20, "Max_HP":20, "alive":true},
	
	"player3":{"name":"player3","damage":3, "speed":70, "HP":30, "Max_HP":30, "alive":true},
	
	"Boss":{"name":"Boss","damage":30, "speed":80, "HP":100, "Max_HP":100, "alive":true}
}
var current_health = 666
var max_health = 666
var damage = 10
var speed = 25
var currentBattle = 0
