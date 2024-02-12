extends CanvasLayer

@onready var animation:AnimationPlayer = $AnimationPlayer

func _ready():
	self.hide()
	pass 

func change_scence(path):
	self.show()
	self.set_layer(100)
	animation.play("Animation")
	await  animation.animation_finished
	get_tree().change_scene_to_file(path)
	animation.play_backwards("Animation")
	await  animation.animation_finished
	self.set_layer(-1)
	self.hide()
	pass
	
