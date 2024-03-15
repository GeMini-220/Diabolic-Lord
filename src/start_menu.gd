extends Control
signal cult_name_confirmed

@onready var battle_scene = preload("res://MainScenes/campfire.tscn") as PackedScene
@onready var confirmation_dialog = $ConfirmationDialog
@onready var load_game = $load_game
@onready var screen_fade = $ScreenFade
@onready var screen_fade_anim = $ScreenFade/ScreenFadeAnim

@onready var username_edit = $UsernameWindow/HBoxContainer/VBoxContainer/UsernameEdit
@onready var username_confirm = $UsernameWindow/HBoxContainer/VBoxContainer/UsernameConfirm



func start_fade_in():
	
	screen_fade_anim.play("fade_in")
	await screen_fade_anim.animation_finished
	
func _ready():
	var save_file = FileAccess.open(State.FILE_PATH, FileAccess.READ)
	if save_file:
		load_game.visible = true
		save_file.close()
	else:
		load_game.visible = false
	start_fade_in()

# Adjusted function to accept a scene path and optionally treat it as a packed scene
func start_fade_out(next_scene_path: String, is_packed_scene: bool = false):
	screen_fade_anim.play("fade_out")
	await screen_fade_anim.animation_finished
	if is_packed_scene:
		get_tree().change_scene_to_packed(battle_scene)
	else:
		get_tree().change_scene_to_file(next_scene_path)

# Use this function for starting a new game with a pre-packed scene
func _on_start_new_game_pressed():
	if FileAccess.file_exists(State.FILE_PATH):
		$newGameConfirmationDialog.popup()  # Ask for confirmation if a save exists
	else:
		State.initialize_player_data()  # Initialize player data if no save file exists
		username_edit.show()  # Show the cult name input
		username_confirm.grab_focus() 


func _on_new_game_confirmation_dialog_confirmed():
	$newGameConfirmationDialog.hide()
	$UsernameWindow.show()
	username_edit.text = "Demon Lord"
	await username_confirm.pressed
	
	
func _on_new_game_confirmation_dialog_canceled():
	$newGameConfirmationDialog.hide()

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

func _on_username_confirm_pressed():
	$UsernameWindow.hide()
	var user_name = username_edit.text.strip_edges()
	if user_name == "Cheater":
		State.initialize_cheater_data()
		State.user_name = user_name
		emit_signal("cult_name_confirmed")  # Emit the signal indicating the name has been set
		username_edit.hide()
	elif user_name != "":
		State.initialize_player_data()
		State.user_name = user_name  # Update the cult name in the State
		emit_signal("cult_name_confirmed")  # Emit the signal indicating the name has been set
		username_edit.hide()
	else:
		State.initialize_player_data()
	State.save_player_data()
	#screen_fade_anim.play("fade_out")
	#await screen_fade_anim.animation_finished
	#get_tree().change_scene_to_packed(battle_scene)
	start_fade_out("res://MainScenes/lore.tscn")

func _on_username_window_close_requested():
	$UsernameWindow.hide()

func _on_username_edit_focus_entered():
	username_edit.text = ""


func _on_bg_music_finished():
	$BGMusic.play()
