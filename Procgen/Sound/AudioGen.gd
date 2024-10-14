extends Node

const MUSIC_NODE = preload("res://Procgen/Sound/MusicNode.tscn")

var footstep_sounds: Dictionary = {
	preload("res://Procgen/Sound/footstep/footstep1.wav"): 200,
	preload("res://Procgen/Sound/footstep/footstep2.wav"): 100,
	preload("res://Procgen/Sound/footstep/footstep3.wav"): 20000,
	preload("res://Procgen/Sound/footstep/footstep4.wav"): 50,
	preload("res://Procgen/Sound/footstep/footstep5.wav"): 100,
	preload("res://Procgen/Sound/footstep/footstep6.wav"): 100,
}

var music : Array[AudioStream] = [
	preload("res://Procgen/Sound/music/1.mp3"),
	preload("res://Procgen/Sound/music/2.mp3"),
	preload("res://Procgen/Sound/music/3.mp3"),
	preload("res://Procgen/Sound/music/4.mp3"),
	preload("res://Procgen/Sound/music/5.mp3"),
	preload("res://Procgen/Sound/music/6.mp3"),
	preload("res://Procgen/Sound/music/7.mp3"),
	preload("res://Procgen/Sound/music/8.mp3"),
	preload("res://Procgen/Sound/music/9.mp3"),
	preload("res://Procgen/Sound/music/10.mp3"),
	preload("res://Procgen/Sound/music/11.mp3"),
	preload("res://Procgen/Sound/music/12.mp3"),
	preload("res://Procgen/Sound/music/13.mp3"),
	preload("res://Procgen/Sound/music/14.mp3"),
	preload("res://Procgen/Sound/music/15.mp3"),
]


var current_music_node := 0

var music_node_0: AudioStreamPlayer
var music_node_1: AudioStreamPlayer

var music_volume: float

var music_tween_1
var music_tween_2

func _ready():
	music_node_0 = MUSIC_NODE.instantiate()
	music_node_1 = MUSIC_NODE.instantiate()
	add_child.call_deferred(music_node_0)
	add_child.call_deferred(music_node_1)
	#music_node_0.looping = true
	#music_node_1.looping = true
	music_volume = music_node_0.volume_db
	music_node_0.volume_db = -80
	music_node_1.volume_db = -80

func play_song(stream: AudioStreamMP3):
	
	if music_node_0.playing and music_node_0.stream == stream:
		return
	if music_node_1.playing and music_node_1.stream == stream:
		return
	#music_node_0.stop()
	#music_node_1.stop()
	if music_tween_1:
		music_tween_1.stop()
	if music_tween_2:
		music_tween_2.stop()
	if stream:
		stream.loop = true


	if current_music_node == 0:
		fade_out(music_node_0)
		if stream:
			music_node_1.stream = stream
			fade_in(music_node_1)

	elif current_music_node == 1:
		fade_out(music_node_1)
		if stream:
			music_node_0.stream = stream
			fade_in(music_node_0)

	current_music_node = (current_music_node + 1) % 2



func fade_out(music_node: AudioStreamPlayer):
	if !music_node.playing:
		return
	music_tween_1 = create_tween()
	music_tween_1.set_parallel(false)
	music_tween_1.tween_property(music_node, "volume_db", -80, 0.75)
	music_tween_1.tween_callback(music_node.stop)

func fade_in(music_node: AudioStreamPlayer):
	music_tween_2 = create_tween()
	music_tween_2.set_parallel(true)
	music_tween_2.tween_property(music_node, "volume_db", music_volume, 0.75)
	music_tween_2.tween_callback(music_node.play)
