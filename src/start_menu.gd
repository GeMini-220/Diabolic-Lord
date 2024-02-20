extends Control

@onready var battle_scene = preload("res://MainScenes/campfire.tscn") as PackedScene
@onready var confirmation_dialog = $ConfirmationDialog
@onready var load_game = $load_game

func _ready():
	var save_file = FileAccess.open(State.FILE_PATH, FileAccess.READ)
	if save_file:
		load_game.visible = true
		save_file.close
	else:
		load_game.visible = false

func _on_start_new_game_pressed():
	State.initialize_player_data()
	get_tree().change_scene_to_packed(battle_scene)

func _on_load_game_pressed():
	var save_file = FileAccess.open(State.FILE_PATH, FileAccess.READ)
	if save_file:
		State.load_player_data()
		get_tree().change_scene_to_file("res://MainScenes/campfire.tscn")
	else:
		print("Player data not found.")

func _on_quit_game_pressed():
	confirmation_dialog.popup()  


func _on_confirm_button_pressed():
	get_tree().quit()


func _on_cancel_button_pressed():
	confirmation_dialog.hide()
