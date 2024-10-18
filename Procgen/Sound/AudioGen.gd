extends Node

const MUSIC_NODE = preload("res://Procgen/Sound/MusicNode.tscn")

var footstep_sounds: Dictionary = {
	preload("res://Procgen/Sound/footstep/footstep1.wav"): 200,
	preload("res://Procgen/Sound/footstep/footstep2.wav"): 100,
	preload("res://Procgen/Sound/footstep/footstep3.wav"): 2000,
	preload("res://Procgen/Sound/footstep/footstep4.wav"): 50,
	preload("res://Procgen/Sound/footstep/footstep5.wav"): 100,
	preload("res://Procgen/Sound/footstep/footstep6.wav"): 100,
}

var music : Array[AudioStream] = [
	preload("res://Procgen/Sound/music/trimmed/1.mp3"),
	preload("res://Procgen/Sound/music/trimmed/2.mp3"),
	preload("res://Procgen/Sound/music/trimmed/3.mp3"),
	preload("res://Procgen/Sound/music/trimmed/4.mp3"),
	preload("res://Procgen/Sound/music/trimmed/5.mp3"),
	preload("res://Procgen/Sound/music/trimmed/6.mp3"),
	preload("res://Procgen/Sound/music/trimmed/7.mp3"),
	preload("res://Procgen/Sound/music/trimmed/8.mp3"),
	preload("res://Procgen/Sound/music/trimmed/9.mp3"),
	preload("res://Procgen/Sound/music/trimmed/10.mp3"),
	preload("res://Procgen/Sound/music/trimmed/11.mp3"),
	preload("res://Procgen/Sound/music/trimmed/12.mp3"),
	preload("res://Procgen/Sound/music/trimmed/13.mp3"),
	preload("res://Procgen/Sound/music/trimmed/14.mp3"),
	preload("res://Procgen/Sound/music/trimmed/15.mp3"),
	preload("res://Procgen/Sound/music/trimmed/16.mp3"),
	preload("res://Procgen/Sound/music/trimmed/17.mp3"),
	preload("res://Procgen/Sound/music/trimmed/18.mp3"),
	preload("res://Procgen/Sound/music/trimmed/19.mp3"),
	preload("res://Procgen/Sound/music/trimmed/20.mp3"),
	preload("res://Procgen/Sound/music/trimmed/21.mp3"),
	preload("res://Procgen/Sound/music/trimmed/22.mp3"),
	preload("res://Procgen/Sound/music/trimmed/23.mp3"),
	preload("res://Procgen/Sound/music/trimmed/24.mp3"),
	preload("res://Procgen/Sound/music/trimmed/25.mp3"),
	preload("res://Procgen/Sound/music/trimmed/26.mp3"),
	preload("res://Procgen/Sound/music/trimmed/27.mp3"),
	preload("res://Procgen/Sound/music/trimmed/28.mp3"),
	preload("res://Procgen/Sound/music/trimmed/29.mp3"),
	preload("res://Procgen/Sound/music/trimmed/30.mp3"),
	preload("res://Procgen/Sound/music/trimmed/31.mp3"),
	preload("res://Procgen/Sound/music/trimmed/32.mp3"),
	preload("res://Procgen/Sound/music/trimmed/33.mp3"),
	preload("res://Procgen/Sound/music/trimmed/34.mp3"),
	preload("res://Procgen/Sound/music/trimmed/35.mp3"),
	preload("res://Procgen/Sound/music/trimmed/36.mp3"),
	#preload("res://Procgen/Sound/music/trimmed/pause.mp3"),
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

func play_song(stream: AudioStreamMP3, pitch=1.0):
	
	var volume = music_volume
	if stream and stream == preload("res://Procgen/Sound/music/trimmed/15.mp3"):
		volume = music_volume - 5
	
	if music_node_0.playing and music_node_0.stream == stream and music_node_0.pitch_scale == pitch:
		return
	if music_node_1.playing and music_node_1.stream == stream and music_node_1.pitch_scale == pitch:
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
			music_node_1.pitch_scale = pitch
			fade_in(music_node_1, volume)

	elif current_music_node == 1:
		fade_out(music_node_1)
		if stream:
			music_node_0.stream = stream
			music_node_0.pitch_scale = pitch
			fade_in(music_node_0, volume)

	current_music_node = (current_music_node + 1) % 2



func fade_out(music_node: AudioStreamPlayer):
	if !music_node.playing:
		return
	music_tween_1 = create_tween()
	music_tween_1.set_parallel(false)
	music_tween_1.tween_property(music_node, "volume_db", -80, 0.75)
	music_tween_1.tween_callback(music_node.stop)

func fade_in(music_node: AudioStreamPlayer,volume=music_volume):
	music_tween_2 = create_tween()
	music_tween_2.set_parallel(true)
	music_tween_2.tween_property(music_node, "volume_db", volume, 0.75)
	music_tween_2.tween_callback(music_node.play)
