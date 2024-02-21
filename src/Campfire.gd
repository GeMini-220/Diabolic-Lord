extends Control


@onready var bg_music = $BGMusic
@onready var screen_fade = $ScreenFade
@onready var screen_fade_anim = $ScreenFade/ScreenFadeAnim



func _ready():
	screen_fade_anim.play("fade_in")
	await screen_fade_anim.animation_finished



func _on_embark_pressed():
	start_fade_out("res://MainScenes/battle.tscn")

func _on_main_menu_pressed():
	start_fade_out("res://MainScenes/start_menu.tscn")

func _on_upgrade_pressed():
	$"Skill Tree".show()

func start_fade_out(next_scene_path: String):
	screen_fade.visible = true
	screen_fade_anim.play("fade_to_black")
	await screen_fade_anim.animation_finished
	get_tree().change_scene_to_file(next_scene_path)
