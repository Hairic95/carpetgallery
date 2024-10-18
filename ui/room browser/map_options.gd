extends Node2D

const DIST = 300

signal option_selected(option: String)

@onready var options_holder: Node2D = $OptionsHolder

var options = [

]

var selected_option = 0

var is_open = false

var room: RoomBox2D

func _ready():
	pass


func open(room: RoomBox2D):
	show()
	self.room = room
	setup_options.call_deferred()

	selected_option = 0
	is_open = true
	pass

func setup_options():
	var option_names = []
		
	#if room.memory and room.coords != PersistentData.player_room_coords:
	if room.coords != PersistentData.player_room_coords:
		option_names.append("EnterRoom")
		

	if !room.coords in PersistentData.bookmarks:
		option_names.append("MarkRoom")
	
	if !PersistentData.bookmarks.is_empty():
		option_names.append("ViewBookmarks")
	
	if room.coords in PersistentData.bookmarks:
			option_names.append("UnmarkRoom")
	
	option_names.append("RoomLookup")
	
	for option in options_holder.get_children():
		option.free()
		options.clear()
	
	for n in option_names:
		var map_option = preload("res://ui/room browser/map_option.tscn").instantiate()
		map_option.name = n
		options_holder.add_child(map_option)

		options.append(map_option)
	
	for i in range(options.size()):
		options[i].position.x = i * DIST

func close():
	hide()


	selected_option = 0
	is_open = false

func _process(delta: float) -> void:
	position.y = Math.splerp(position.y, (300 if !is_open else 70), delta, 2.0)
	position.x = get_parent().offset.x
	options_holder.position.x = Math.splerp(options_holder.position.x, -selected_option * DIST, delta, 1)
	if is_open:
		if Input.is_action_just_pressed("primary"):
			var option = options[selected_option].name
			%Blip2.play()
			option_selected.emit(option)
			close()
		elif Input.is_action_just_pressed("secondary"):
			option_selected.emit("cancel")
		var old = selected_option
		
		if Input.is_action_just_pressed("move_left"):
			selected_option -= 1
		if Input.is_action_just_pressed("move_right"):
			selected_option += 1
		
		selected_option = clamp(selected_option, 0, options.size() - 1)
		if old != selected_option:
			%Blip1.play() 
