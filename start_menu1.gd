extends Control

   
func _on_start_new_game_pressed():
	ScenceChanger.change_scence("res://MainScenes/campfire.tscn")
	pass 


func _on_quit_game_pressed():
	get_tree().quit()
	pass
