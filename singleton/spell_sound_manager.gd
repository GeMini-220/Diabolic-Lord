extends Node

#PASS THESE STRINGS IN PLAY CLIP TO PLAY THE SOUND
const FIENDISH_FURY = "fiendish_fury"
const DREADFORGE = "dreadforge"
const INFERNAL_AFFLICTION = "infernal_affliction"
const DK_SPELL_1_METAL = "dk_spell_1_block"
const DK_SPELL_1_THUD = "dk_spell_1_hit"
const DK_SPELL_2_GUARD = "dk_spell_2_guard"
const DK_SPELL_2_COUNTER = "dk_spell_2_counter"
const VL_BLOOD_SIPHON = "blood_siphon"
const VL_HOUSEHOLD = "household"
const VL_NOBLE_CHARM = "noble_charm"
const VL_VAMPIRIC_FRENZY = "vampiric_frenzy"
const VL_RED_RUSH_LEAVE = "red_rush_leave"
const VL_RED_RUSH_BACK = "red_rush_back"
const SCORCHED_EARTH = "scorched_earth"
const FIREBALL = "fireball"
const FIRE_RAIN = "fire_rain"
const METEOR = "meteor"
const HELL_ON_EARTH = "hell_on_earth"


#MAKE SURE TO PRELOAD THE SOUNDS YOU WANT TO USE
var SOUNDS = {
	FIENDISH_FURY: preload("res://audio/fout-01.wav"),
	DREADFORGE: preload("res://audio/fout-02.wav"),
	INFERNAL_AFFLICTION: preload("res://audio/fout-03.wav"),
	DK_SPELL_1_METAL: preload("res://audio/DemonSounds/dk_spell_1_metal.mp3"),
	DK_SPELL_1_THUD: preload("res://audio/DemonSounds/dk_spell_1_thud.mp3"),
	DK_SPELL_2_GUARD: preload("res://audio/DemonSounds/dk_spell_2_guard.mp3"),
	DK_SPELL_2_COUNTER: preload("res://audio/DemonSounds/dk_spell_2_counter.mp3"),
	VL_BLOOD_SIPHON: preload("res://audio/VampireSounds/vamp_lord_spell_2.wav"),
	VL_HOUSEHOLD: preload("res://audio/VampireSounds/vamp_lord_spell_1.wav"),
	VL_NOBLE_CHARM: preload("res://audio/VampireSounds/vamp_lord_spell_3.wav"),
	VL_VAMPIRIC_FRENZY: preload("res://audio/VampireSounds/vamp_lord_spell_4.wav"),
	VL_RED_RUSH_LEAVE: preload("res://audio/VampireSounds/red_rush_1.wav"),
	VL_RED_RUSH_BACK: preload("res://audio/VampireSounds/red_rush_2.wav"),
	SCORCHED_EARTH: preload("res://audio/InfernoSounds/scorched_earth.wav"),
	FIREBALL: preload("res://audio/InfernoSounds/fireball_sound.wav"),
	FIRE_RAIN: preload("res://audio/InfernoSounds/fire_rain_sound.wav"),
	METEOR: preload("res://audio/InfernoSounds/meteor_sound.wav"),
	HELL_ON_EARTH: preload("res://audio/InfernoSounds/hell_on_earth_sound.wav"),
	#PRELOAD MORE SOUNDS TO USE HERE!
	
}

#Call this function anywhere throughout the program to play one of these sounds, 
#there need to be an AudioStreamPlayer2D attached to the scene
func play_clip(player: AudioStreamPlayer2D, clip_key: String):
	if SOUNDS.has(clip_key) == false:
		return
	player.stream = SOUNDS[clip_key]
	player.play()


