extends Control

var skill_tree_opened = false

@onready var bg_music = $BGMusic
@onready var screen_fade = $ScreenFade
@onready var screen_fade_anim = $ScreenFade/ScreenFadeAnim
@onready var cult_name_sign = $CultName



func _ready():
	cult_name_sign.text = State.cult_name
	screen_fade.visible = true
	screen_fade_anim.play("fade_in")
	await screen_fade_anim.animation_finished



func _on_embark_pressed():
	start_fade_out("res://MainScenes/battle.tscn")

func _on_main_menu_pressed():
	start_fade_out("res://MainScenes/start_menu.tscn")

func _on_upgrade_pressed():
	$"Skill Tree".show()
	if skill_tree_opened == false:
		$"Skill Tree".check_for_upgrades()
		skill_tree_opened = true

func start_fade_out(next_scene_path: String):
	screen_fade.visible = true
	screen_fade_anim.play("fade_to_black")
	await screen_fade_anim.animation_finished
	get_tree().change_scene_to_file(next_scene_path)
	
