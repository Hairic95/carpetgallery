extends GameScene


const VOLUME_DIFF = 5

const VOLUME_MIN = -30

@onready var fullscreen: Node2D = %Fullscreen
@onready var fullscreen_on_label: Label = $"options menu/Fullscreen/FullscreenOnLabel"

@onready var fx_volume: Node2D = %FxVolume
@onready var fx_progress_bar: ProgressBar = %FxProgressBar

@onready var music_volume: Node2D = %MusicVolume
@onready var music_progress_bar: ProgressBar = %MusicProgressBar

@onready var clear_data: Node2D = %ClearData
@onready var clear_data_progress_bar: ProgressBar = %ClearDataProgressBar

@onready var pointer: Sprite2D = %Pointer
@onready var exit: Node2D = %Exit
@onready var items = [
	exit,
	fullscreen,
	fx_volume,
	music_volume,
	clear_data,
]


var item_selected = 0

var cleared = false

func _process(delta: float) -> void:
	fullscreen_on_label.text = "on" if Config.fullscreen else "off"
	fx_progress_bar.value = remap(Config.fx_volume, VOLUME_MIN, 0, 0, 100)
	music_progress_bar.value = remap(Config.music_volume, VOLUME_MIN, 0, 0, 100)

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
		if selected == fullscreen:
			Config.fullscreen = !Config.fullscreen
		if selected == exit:
			set_process(false)
			queue_scene_change("MainMenu")
	if Input.is_action_just_pressed("move_left"):
		if selected == music_volume:
			%Blip.play()
			Config.music_volume -= VOLUME_DIFF
			if Config.music_volume <= VOLUME_MIN:
				Config.music_volume = -80
		elif selected == fx_volume:
			%Blip.play()
			Config.fx_volume -= VOLUME_DIFF
			if Config.music_volume <= VOLUME_MIN:
				Config.music_volume = -80
	if Input.is_action_just_pressed("move_right"):
		if selected == music_volume:
			%Blip.play()
			Config.music_volume = max(Config.music_volume, VOLUME_MIN) + VOLUME_DIFF 
		elif selected == fx_volume:
			%Blip.play()
			Config.fx_volume =  max(Config.fx_volume, VOLUME_MIN) + VOLUME_DIFF 
	
	var clearing = false
	if Input.is_action_pressed("primary"):
		if selected == clear_data and !cleared:
			clear_data_progress_bar.value += delta * 33
			clearing = true
			if clear_data_progress_bar.value == clear_data_progress_bar.max_value:
				await PersistentData.initialize_data()
				PersistentData.save_game()
				cleared = true
				clear_data_progress_bar.value = clear_data_progress_bar.min_value
				%Blip2.play()
	if !clearing:
		clear_data_progress_bar.value -= delta * 100
