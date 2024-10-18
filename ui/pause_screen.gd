extends Control

class_name PauseScreen

signal exit

@export var player: BaseObject2D
@export var world: InfiniteWorld

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bg: ColorRect = $BG

@onready var room_browser: Node2D = %RoomBrowser

var rng := BetterRng.new()

var map_options_open = false

func open_animation():
	animation_player.play("Open")
	room_browser.open_animation()
	%Open.play()
	pass

func close_animation():
	%Close.play()
	animation_player.play("Close")
	room_browser.close_animation()
