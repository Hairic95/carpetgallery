extends Control

class_name PauseScreen

@export var player: BaseObject2D
@export var world: InfiniteWorld

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bg: ColorRect = $BG

@onready var room_browser: Node2D = %RoomBrowser

var rng := BetterRng.new()

func open_animation():
	#bg.color = player.room.color_schemes[0].color_1
	animation_player.play("Open")
	room_browser.open_animation()
	pass

func close_animation():
	animation_player.play("Close")
	room_browser.close_animation()
