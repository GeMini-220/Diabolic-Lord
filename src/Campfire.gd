extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_embark_pressed():
	get_tree().change_scene_to_file("res://MainScenes/battle.tscn")


func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://MainScenes/start_menu.tscn")


func _on_upgrade_pressed():
	#get_tree().change_scene_to_file("res://MainScenes/skill_tree.tscn")
	$"Skill Tree".show()
