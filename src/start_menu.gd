extends Control

@onready var battle_scene = preload("res://MainScenes/campfire.tscn") as PackedScene
@onready var confirmation_dialog = $ConfirmationDialog
@onready var load_game = $MarginContainer/HBoxContainer/VBoxContainer/load_game
@onready var screen_fade = $ScreenFade
@onready var screen_fade_anim = $ScreenFade/ScreenFadeAnim




func start_fade_in():
	screen_fade_anim.play("fade_in")
	await screen_fade_anim.animation_finished
	
func _ready():
	var save_file = FileAccess.open(State.FILE_PATH, FileAccess.READ)
	if save_file:
		load_game.visible = true
		save_file.close
	else:
		load_game.visible = false
	start_fade_in()

# Adjusted function to accept a scene path and optionally treat it as a packed scene
func start_fade_out(next_scene_path: String, is_packed_scene: bool = false):
	screen_fade_anim.play("fade_out")
	await screen_fade_anim.animation_finished
	if is_packed_scene:
		var scene = battle_scene
		get_tree().change_scene_to_packed(battle_scene)
	else:
		get_tree().change_scene_to_file(next_scene_path)

# Use this function for starting a new game with a pre-packed scene
func _on_start_new_game_pressed():
	State.initialize_player_data()
	start_fade_out("res://MainScenes/campfire.tscn", true)

# Adjust the loading from a file to potentially utilize `start_fade_out` directly if suitable
func _on_load_game_pressed():
	var save_file = FileAccess.open(State.FILE_PATH, FileAccess.READ)
	if save_file:
		State.load_player_data()
		start_fade_out("res://MainScenes/campfire.tscn")
	else:
		print("Player data not found.")

func _on_quit_game_pressed():
	confirmation_dialog.popup()  


func _on_confirm_button_pressed():
	screen_fade_anim.play("fade_out")
	await screen_fade_anim.animation_finished
	get_tree().quit()


func _on_cancel_button_pressed():
	confirmation_dialog.hide()
