extends CanvasLayer

class_name PauseScreenLayer

signal exit_requested

@export var player: NetworkPlatformerPlayer
@export var camera: GoodCamera
@export var world: InfiniteWorld
#@onready var pause_screen: PauseScreen = %PauseScreen
@export var room_browser: RoomBrowser2D
@onready var pause_screen: PauseScreen = %PauseScreen
@onready var menu_screen: MenuScreen = $MenuScreen


@onready var animation_player: AnimationPlayer = $AnimationPlayer

var menu_open = false

func _ready():
	room_browser.exit.connect(_on_room_browser_exit)
	pass

func _process(delta: float) -> void:
	if !world.transitioning and player.active:
		if !menu_open:
			if Input.is_action_just_pressed("secondary"):
				menu_open = true
				player.active = false
				
				animation_player.play("Pause")
			if Input.is_action_just_pressed("menu"):
				open_menu_screen.call_deferred()

func open_menu_screen():
	menu_open = true
	
	player.active = false
	menu_screen.open()
	var selection = await menu_screen.option_selected
	if selection == "resume":
		menu_screen.close()
		menu_open = false
		player.active = true
	if selection == "quit":
		exit_requested.emit()

func _on_room_browser_exit():
	menu_open = false
	player.active = true
	animation_player.play("Unpause")
