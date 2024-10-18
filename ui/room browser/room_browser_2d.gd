extends Node2D

class_name RoomBrowser2D

signal exit

signal fast_travel_initiated(coords: Vector3i, fade: bool)

const GRID_DIMENSIONS = Vector2i(40, 50)
const _2D_ROOM = preload("res://ui/room browser/2DRoom.tscn")

const RECT_SIZE = Vector2(30, 22)
#const ROOM_DISTANCE = 1.1
const GRID_SIZE = Vector2(32, -24)


#@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var open_timer: Timer = $OpenTimer
@onready var rooms: Node2D = $Rooms
@onready var rect_grabber: Sprite2D = %RectGrabber
@onready var rapid_input_timer: Timer = $RapidInputTimer
@onready var rapid_input_startup_timer: Timer = $RapidInputStartupTimer

@export var game_camera: Camera2D
@onready var room_options: Node2D = $RoomOptions
@onready var map_options: Node2D = %MapOptions
@onready var bookmark_options: BookmarkViewer = %BookmarkOptions
@onready var bookmark_namer: BookmarkNamer = %BookmarkNamer
@onready var lookup_dialogue: LookupDialogue = %LookupDialogue
@onready var hold_zoom_in_timer: Timer = $HoldZoomInTimer
@onready var rect_grabber_zoomed_out: Sprite2D = %RectGrabberZoomedOut

var rng = BetterRng.new()

var displayed_rooms: Dictionary[Vector2i, RoomBox2D] = {
}

var current_coord = Vector2i(0, 0)

var z = 0

var opening = true
var closing = true

var receiving_input = true

var force_camera_focus = null

var holding = false

var room_pool = []
var force_grabber_visible = false


var camera_zoom_target = 1.0

@onready var hold_start_speed = rapid_input_timer.wait_time
@onready var hold_speed = hold_start_speed

var room_options_active = false
var map_options_active = false

func _ready() -> void:
	hide()
	setup_rooms.call_deferred()
	PersistentData.room_memory_updated.connect(update_memory)
	PersistentData.player_location_changed.connect(update_player_room)
	PersistentData.bookmarks_updated.connect(update_bookmark)

func update_memory(coords: Vector3i):
	var room: RoomBox2D = displayed_rooms.get(Vector2i(coords.x, coords.y))
	if room:
		room.update_memory()

func update_bookmark(coords: Vector3i):
	var room: RoomBox2D = displayed_rooms.get(Vector2i(coords.x, coords.y))
	if room:
		room.update_bookmark()
	
func update_player_room(old: Vector3i, new: Vector3i):
	var room: RoomBox2D = displayed_rooms.get(Vector2i(old.x, old.y))
	if room:
		room.update_player_room()
	var room2: RoomBox2D = displayed_rooms.get(Vector2i(new.x, new.y))
	if room2:
		room2.update_player_room()

func setup_rooms():
	for i in range(GRID_DIMENSIONS.x * GRID_DIMENSIONS.y):
		var room = _2D_ROOM.instantiate()
		room.coords = null
		rooms.add_child(room)
		room.position = Vector2(NAN, NAN)
		room_pool.push_back(room)

func _process(delta: float) -> void:
	if !visible:
		return

	if closing:
		camera.zoom = game_camera.zoom * (8.0)
	else:
		camera.zoom =  Math.splerp_vec(camera.zoom, Vector2(1, 1) * camera_zoom_target, delta, 1.0)
	
	if !holding and hold_zoom_in_timer.is_stopped():
		camera_zoom_target = Math.approach(camera_zoom_target, 1.0, delta * 1.0)
	#rect_grabber_zoomed_out.visible = camera_zoom_target < 0.35
	rect_grabber_zoomed_out.modulate.a = clamp(inverse_lerp(0.5, 0.2, camera_zoom_target), 0, 1)
	if room_options_active:
		camera.offset = Math.splerp_vec(camera.offset, Vector2(60, 0), delta, 3.0)
	else:
		camera.offset = Math.splerp_vec(camera.offset, Vector2(0, 0), delta, 1.0)
		
	if bookmark_options.is_open:
		if bookmark_options.options.size() > 0:
			var coords = bookmark_options.coords[bookmark_options.selected_option]
			#print(coords)
			shift_to(Vector2i(coords.x, coords.y))

	
	rect_grabber.scale = Vector2.ONE * Math.splerp(rect_grabber.scale.x, 0.0 if (!force_grabber_visible and (!receiving_input or !open_timer.is_stopped())) else 1.0, delta, 2.0)
	#if receiving_input:
	rect_grabber.position = Math.splerp_vec(rect_grabber.position, cell_to_world(current_coord), delta, 0.8)
	
	var camera_focus = current_coord if force_camera_focus == null else force_camera_focus
	
	camera.position = Math.splerp_vec(camera.position, cell_to_world(camera_focus), delta, 2.0)
	
	room_options.position = cell_to_world(current_coord)
	
	if receiving_input:
		var move_dir = Utils.bools_to_vector2i(Input.is_action_just_pressed("move_left"), Input.is_action_just_pressed("move_right"), Input.is_action_just_pressed("move_up"), Input.is_action_just_pressed("move_down"))
		move_dir.y *= -1
		if move_dir:
			shift_to(current_coord + move_dir)
			if !holding:
				holding = true
				rapid_input_startup_timer.start()
				hold_speed = hold_start_speed
				rapid_input_timer.wait_time = hold_speed
		
		var hold_dir = Utils.bools_to_vector2i(Input.is_action_pressed("move_left"), Input.is_action_pressed("move_right"), Input.is_action_pressed("move_up"), Input.is_action_pressed("move_down"))
		hold_dir.y *= -1
		if hold_dir:
			if rapid_input_timer.is_stopped() and holding and rapid_input_startup_timer.is_stopped():
				shift_to(current_coord + hold_dir)
				rapid_input_timer.start(hold_speed)
				hold_speed -= 0.005
				hold_speed = max(hold_speed, 0.02)
				camera_zoom_target = min(camera_zoom_target, clamp(hold_speed * 10, 0.20, 1))
				hold_zoom_in_timer.start()

				if camera_zoom_target >= 0.8:
					camera_zoom_target = 1.0
			pass
		else:
			holding = false
			rapid_input_startup_timer.stop()
			rapid_input_timer.stop()
			pass
		
		if Input.is_action_just_pressed("primary"):
			select_room()
			
		elif Input.is_action_just_pressed("secondary"):
			exit.emit()


	Debug.dbg("rapid_input_startup_timer.is_stopped()", rapid_input_startup_timer.is_stopped())
	Debug.dbg("rapid_input_timer.is_stopped()", rapid_input_timer.is_stopped())

func select_room():
	holding = false
	rect_grabber.hide()
	receiving_input = false
	%Blip2.play()
	%Blip3.play()
	#%Blip4.play()
	room_options_active = true
	map_options_active = true
	map_options.open.call_deferred(get_selected_room())
	room_options.process_room(get_selected_room())
	#process_room_options_selection(selection)
	camera_zoom_target = 1.0
	var selection = await map_options.option_selected
	process_map_options_selection(selection)
	map_options_active = false

func process_room_options_selection(selection: String):
	match selection:
		"cancel":
			receiving_input = true

func process_map_options_selection(selection: String):
	match selection:
		"cancel":
			return_input()
			map_options.close()
			room_options.close()
			room_options_active = false
		"EnterRoom":
			%Blip6.play()
			fast_travel_initiated.emit(get_3d_coords(), false)
			exit.emit()
			room_options.close()
			room_options_active = false
		"MarkRoom":
			var coords = get_3d_coords()
			var placeholder = "%s, %s" % [coords.x, coords.y] # TODO: 3d coords if they find the z axis?
			PersistentData.add_bookmark(coords, placeholder)
			bookmark_namer.open.call_deferred(placeholder)
			var bookmark_name = await bookmark_namer.name_selected
			if bookmark_name == null:
				bookmark_namer.close()
				PersistentData.remove_bookmark(coords)
				return_input()
				room_options.close()
				room_options_active = false
			else:
				if bookmark_name.strip_edges() == "":
					bookmark_name = placeholder
				bookmark_namer.close()
				if bookmark_name:
					PersistentData.remove_bookmark(coords)
					PersistentData.add_bookmark(coords, bookmark_name)
				return_input()
				room_options.close()
				room_options_active = false
		"UnmarkRoom":
			PersistentData.remove_bookmark(get_3d_coords())
			return_input(false)
			room_options.close()
			room_options_active = false

		"ViewBookmarks":
			var coord = current_coord
			force_grabber_visible = true
			rect_grabber.show()
			bookmark_options.open.call_deferred()
			room_options.close()
			room_options_active = false
			var bookmark_selection = await bookmark_options.option_selected
			bookmark_options.close()
			if bookmark_selection == null:
				#shift_to(Vector2i(bookmark_selection.x, bookmark_selection.y))
				shift_to(coord)
				return_input()
			else:
				select_room()
		"RoomLookup":
			
			var random_coords = "%s %s" % [rng.randi_range(-1000, 1000), rng.randi_range(-1000, 1000)]
			lookup_dialogue.open(random_coords)
			var coords = await lookup_dialogue.coords_selected
			#coords.x = clamp(coords.x, -9000000000000000000, 9000000000000000000)
			#coords.y = clamp(coords.y, -9000000000000000000, 9000000000000000000)
			if coords != null:
				shift_to(Vector2i(coords.x, coords.y))
				select_room()
			else:
				room_options.close()
				room_options_active = false
				return_input()



func return_input(play_sound=true):
	rect_grabber.show()
	force_grabber_visible = false
	receiving_input = true
	if play_sound:
		%Blip4.play()

func get_3d_coords():
	return Vector3i(current_coord.x, current_coord.y, z)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(process_cell_visual(cell)) * GRID_SIZE

func init_rooms() -> void:
	shift_to(current_coord)

func create_room(x, y) -> Node2D:
	var room = room_pool.pop_back()
	room.coords = Vector3i(x, y, 0)
	room.initialize()
	#rooms.add_child(room)
	room.update()
	
	var cell = Vector2i(x, y)
	
	room.position = cell_to_world(cell)
	displayed_rooms[Vector2i(x, y)] = room
	return room

func process_cell_visual(cell: Vector2i):
	var new_cell = cell
	new_cell.x = posmod(cell.x + 156248, 312496) - 156248
	new_cell.y = posmod(cell.y + 156248, 312496) - 156248
	return new_cell

func get_grid_start():
	return Vector2i(current_coord.x - GRID_DIMENSIONS.x / 2, current_coord.y - GRID_DIMENSIONS.y / 2)

func get_grid_end():
	return Vector2i(current_coord.x + GRID_DIMENSIONS.x / 2 - (1 if GRID_DIMENSIONS.x % 2 == 0 else 0), current_coord.y + GRID_DIMENSIONS.y / 2 - (1 if GRID_DIMENSIONS.y % 2 == 0 else 0))

func get_selected_room() -> RoomBox2D:
	return displayed_rooms.get(current_coord)

func shift_to(to: Vector2i, instant=false, play_sound=true):
	var selected = get_selected_room()
	if selected:
		selected.deselect()
	if current_coord != to and play_sound:
		#if camera.zoom.x == 1:
			%Blip1.play()
	current_coord = to

	var world = cell_to_world(to)

	var diff = camera.position - world
	if diff.length() > 200:
		camera.position = (world + diff.normalized() * 200)

	if instant:
		camera.position = cell_to_world(current_coord)
		rect_grabber.position = camera.position

	var start = get_grid_start()
	var end = get_grid_end()
	for key in displayed_rooms.keys():
		if key.x < start.x or key.x > end.x or key.y < start.y or key.y > end.y:
			remove_room(key)

	for x in range(start.x, end.x + 1):
		for y in range(start.y, end.y + 1):
			var cell = Vector2i(x, y)
			if !displayed_rooms.has(cell):
				create_room(x, y)
	get_selected_room().select()


func remove_room(cell: Vector2i):
	if !(cell in displayed_rooms):
		return
	
	var room = displayed_rooms[cell]
	
	displayed_rooms.erase(cell)
	
	if is_instance_valid(room):
		room_pool.push_back(room)

	room.initialize()

func open_animation() -> void:
	camera_zoom_target = 1
	open_timer.stop()
	#process_mode = Node.PROCESS_MODE_ALWAYS
	#await get_tree().process_frame
	#set_process(true)
	force_camera_focus = null
	receiving_input = true
	rooms.process_mode = Node.PROCESS_MODE_ALWAYS
	shift_to(PersistentData.player_room_coords_2d, false, false)
	camera.position = cell_to_world(current_coord)
	init_rooms.call_deferred()
	get_selected_room().open_anim()
	camera.zoom = Vector2(8, 8)
	open_timer.start()
	opening = true
	closing = false
	room_options_active = false
	rect_grabber.show()
	show.call_deferred()
	#for room in displayed_rooms.values():
		#room.update()

func close_animation() -> void:
	#open_timer.stop()
	#open_timer.start()
	receiving_input = false
	shift_to(PersistentData.player_room_coords_2d, false, false)
	#force_camera_focus = PersistentData.player_room_coords_2d
	rect_grabber.hide()
	var old_pos = camera.position
	var new_pos = cell_to_world(PersistentData.player_room_coords_2d)
	camera.position = new_pos - (old_pos.direction_to(new_pos) * 20).limit_length(new_pos.distance_to(old_pos))
	rect_grabber.position = new_pos
	closing = true
	await get_tree().create_timer(0.06).timeout
	get_selected_room().close_anim()

func close():
	hide()
	rooms.process_mode = Node.PROCESS_MODE_DISABLED
	camera.zoom = Vector2(1, 1)

func _draw():
	pass
