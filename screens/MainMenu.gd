extends GameScene

@onready var pointer: Sprite2D = %Pointer
@onready var start: Node2D = %Start
@onready var options: Node2D = %Options
@onready var quit: Node2D = %Quit


@onready var items = [
	start,
	options,
	#quit,
]

var item_selected = 0


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
		%Blip.play()
		if selected == start:
			PersistentData.load_game()
			queue_scene_change("Game")
		elif selected == quit:
			queue_scene_change("Quit")
		elif selected == options:
			queue_scene_change("Options")
		set_process(false)
