extends TextureRect

@onready var screen_fade = $ScreenFade
@onready var screen_fade_anim = $ScreenFade/ScreenFadeAnim

var ending_state = 0

func start_fade_in():
	screen_fade_anim.play("fade_in")
	await screen_fade_anim.animation_finished
	
func start_fade_out(next_scene_path: String):
	screen_fade_anim.play("fade_out")
	await screen_fade_anim.animation_finished
	get_tree().change_scene_to_file(next_scene_path)

func _ready():
	start_fade_in()
	if State.currentBattle < 10:
		$VBoxContainer/Text.text = """
You have ruled us for too long…
Finally, we have overthrown you.
Now, %s, I banish thee…
to the human realm!""" % State.user_name
		$VBoxContainer/Text2.text = """
After centuries of ruling over your country, 
you grew idle and weak.
Your citizens staged a successful uprising, 
ousting you from the throne.
As punishment for your idleness
while they lived in poverty, 
they have banished you here, 
to the human realm."""
	else:
		ending_state = 1
		$VBoxContainer/Text.text = """
No…you demon, you've doomed us all!
You've taken all of our soldiers.
Now Altaria will surely defeat us.
Our kingdom, our way of life will be gone."""
		$VBoxContainer/Text2.text = """
You cast aside the laments of the human.
You wonder, how much more must you conquer this world? 
You've converted nearly everyone in the kingdom into your followers. 
How many more until you have enough power 
to return to the demon realm and exact your revenge?"""

func _input(event):
	if Input.is_action_just_released("click"):
		if ending_state == 1:
			screen_fade_anim.play("fade_out")
			await screen_fade_anim.animation_finished
			start_fade_in()
			$VBoxContainer/Text.text = """
With Bajoria fallen, what am I to do?
There is nothing here for me now.
Perhaps I've no choice but to become one of your accursed followers.
At least there, I will be among all those others 
whom I used to know and whom you have taken."""
			$VBoxContainer/Text2.text = """
You're close; you can feel your restoration within reach, 
but some final delicate, infuriatingly intangible barrier obscures it."""
			ending_state = 2
		elif ending_state == 2:
			screen_fade_anim.play("fade_out")
			await screen_fade_anim.animation_finished
			start_fade_in()
			$VBoxContainer/Text.text = """
Bajoria…is no more. I submit my soul to you, my lord."""
			$VBoxContainer/Text2.text = """
A bright crimson light appears. 
What's this? An eerie hum emanates from the glow.
You feel the barrier between you and your goal crumble down, 
and you realize that you've cleared the final hurdle. 
All your toil in this realm has paid off.
You have taken not only the people, but the spirit of Bajoria.
Drawing power from the soul of the kingdom itself, 
you cast a powerful transcendence spell, 
making a straight course for the demon realm.
Sending you to the human realm was their great folly. 
Here, you have discovered the secret to obtaining more power 
than they could possibly imagine wielding. 
You will return powerful enough to return them all 
to their rightful places beneath you."""
			ending_state = 3
		elif ending_state == 3:
			screen_fade_anim.play("fade_out")
			await screen_fade_anim.animation_finished
			start_fade_in()
			$VBoxContainer/Text.text = """
You will become the ultimate conqueror, the ultimate ruler—"""
			$VBoxContainer/Text2.text = """
The Diabolic Lord."""
			ending_state = 4
		elif ending_state == 4:
			ending_state = -1 # prevent multi click bug
			start_fade_out("res://MainScenes/start_menu.tscn")
		elif ending_state == 0:
			ending_state = -1 # prevent multi click bug
			start_fade_out("res://MainScenes/campfire.tscn")

func _on_timer_timeout():
	pass
	#start_fade_out("res://MainScenes/campfire.tscn")
