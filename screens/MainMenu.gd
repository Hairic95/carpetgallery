extends GameScene

@onready var pointer: Sprite2D = %Pointer
@onready var start: Node2D = %Start
@onready var online: Node2D = %Online
@onready var options: Node2D = %Options
@onready var quit: Node2D = %Quit
@onready var ip_address: LineEdit = %IpAddress


@onready var items = [
	start,
	online,
	options,
	#quit,
]

var item_selected = 0

var is_on_online = false

func _ready() -> void:
	if !OS.get_name() == "Web":
		items.append(quit)
	else:
		quit.hide()
	AudioGen.play_song(preload("res://Procgen/Sound/music/trimmed/pause.mp3"))

func _process(delta: float) -> void:
	var old = item_selected
	if Input.is_action_just_pressed("move_down"):
		item_selected += 1
	if Input.is_action_just_pressed("move_up"):
		item_selected -= 1
	item_selected = item_selected % items.size()
	var selected = items[item_selected]
	if old != item_selected:
		%Blip.play()
	pointer.position.y = Math.splerp(pointer.position.y, selected.position.y, delta, 0.5)

	if Input.is_action_just_pressed("primary"):
		if !is_on_online:
			%Blip.play()
			if selected == start:
				PersistentData.load_game()
				queue_scene_change("Game")
				set_process(false)
			elif selected == online:
				$Main.hide()
				$Online.show()
				is_on_online = true
			elif selected == quit:
				while PersistentData.saving:
					await get_tree().process_frame
				queue_scene_change("Quit")
				set_process(false)
			elif selected == options:
				queue_scene_change("Options")
				set_process(false)
			
		else:
			queue_scene_change("Game")

	
	if Input.is_action_just_pressed("secondary") && is_on_online:
		is_on_online = false
		$Main.show()
		$Online.hide()
		
