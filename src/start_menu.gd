extends Control

@onready var battle_scene = preload("res://src/battle.tscn") as PackedScene
@onready var confirmation_dialog = $ConfirmationDialog

func _on_start_new_game_pressed():
	get_tree().change_scene_to_packed(battle_scene)


func _on_quit_game_pressed():
	confirmation_dialog.popup()  


func _on_confirm_button_pressed():
	get_tree().quit()


func _on_cancel_button_pressed():
	confirmation_dialog.hide()
