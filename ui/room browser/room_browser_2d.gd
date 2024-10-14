extends Node2D

class_name RoomBrowser2D

const GRID_DIMENSIONS = Vector2i(11, 11)
const _2D_ROOM = preload("res://ui/room browser/2DRoom.tscn")

const RECT_SIZE = Vector2(30, 22)
#const ROOM_DISTANCE = 1.1
const GRID_SIZE = Vector2(32, 24)


#@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var open_timer: Timer = $OpenTimer
@onready var rooms: Node2D = $Rooms
@onready var rect_grabber: Sprite2D = %RectGrabber
@onready var rapid_input_timer: Timer = $RapidInputTimer
@onready var rapid_input_startup_timer: Timer = $RapidInputStartupTimer

@export var game_camera: Camera2D


var displayed_rooms: Dictionary[Vector2i, RoomBox2D] = {
}

var current_coord = Vector2i(0, 0)

var opening = true
var closing = true

var receiving_input = true

var force_camera_focus = null

var holding = false

var room_pool = []

func _ready() -> void:
	hide()
	for i in range(GRID_DIMENSIONS.x * GRID_DIMENSIONS.y):
		var room = _2D_ROOM.instantiate()
		room.coords = null
		rooms.add_child(room)
		room.position = Vector2(NAN, NAN)
		room_pool.push_back(room)
	#set_process.call_deferred(false)

func _process(delta: float) -> void:
	if !visible:
		return

	if opening and open_timer.is_stopped():
		camera.zoom = Math.splerp_vec(camera.zoom, Vector2(1, 1), delta, 1.0)
		if camera.zoom == Vector2.ONE:
			opening = false
	if closing:
		camera.zoom = game_camera.zoom * (8.0)
	
	
	rect_grabber.scale = Vector2.ONE * Math.splerp(rect_grabber.scale.x, 0.0 if (!receiving_input or !open_timer.is_stopped()) else 1.0, delta, 2.0)
	#if receiving_input:
	rect_grabber.position = Math.splerp_vec(rect_grabber.position, cell_to_world(current_coord), delta, 0.8)
	
	var camera_focus = current_coord if force_camera_focus == null else force_camera_focus
	
	camera.position = Math.splerp_vec(camera.position, cell_to_world(camera_focus), delta, 2.0)
	
	if receiving_input:
		var move_dir = Utils.bools_to_vector2i(Input.is_action_just_pressed("move_left"), Input.is_action_just_pressed("move_right"), Input.is_action_just_pressed("move_up"), Input.is_action_just_pressed("move_down"))
		if move_dir:
			shift_to(current_coord + move_dir)
			if !holding:
				holding = true
				rapid_input_startup_timer.start()
		
		var hold_dir = Utils.bools_to_vector2i(Input.is_action_pressed("move_left"), Input.is_action_pressed("move_right"), Input.is_action_pressed("move_up"), Input.is_action_pressed("move_down"))
		
		if hold_dir:
			if rapid_input_timer.is_stopped() and holding and rapid_input_startup_timer.is_stopped():
				shift_to(current_coord + hold_dir)
				rapid_input_timer.start()
			pass
		else:
			holding = false
			rapid_input_startup_timer.stop()
			rapid_input_timer.stop()
			pass

	Debug.dbg("rapid_input_startup_timer.is_stopped()", rapid_input_startup_timer.is_stopped())
	Debug.dbg("rapid_input_timer.is_stopped()", rapid_input_timer.is_stopped())

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GRID_SIZE

func init_rooms() -> void:
	shift_to(current_coord)

func create_room(x, y) -> Node2D:
	var room = room_pool.pop_back()
	room.coords = Vector3i(x, y, 0)
	room.initialize()
	#rooms.add_child(room)
	room.update()
	
	room.position = Vector2((x), (y)) * GRID_SIZE
	displayed_rooms[Vector2i(x, y)] = room
	return room

func get_grid_start():
	return Vector2i(current_coord.x - GRID_DIMENSIONS.x / 2, current_coord.y - GRID_DIMENSIONS.y / 2)

func get_grid_end():
	return Vector2i(current_coord.x + GRID_DIMENSIONS.x / 2 - (1 if GRID_DIMENSIONS.x % 2 == 0 else 0), current_coord.y + GRID_DIMENSIONS.y / 2 - (1 if GRID_DIMENSIONS.y % 2 == 0 else 0))

func get_selected_room() -> RoomBox2D:
	return displayed_rooms.get(current_coord)

func shift_to(to: Vector2i):
	var selected = get_selected_room()
	if selected:
		selected.deselect()
	current_coord = to
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

func open_animation() -> void:
	open_timer.stop()
	#process_mode = Node.PROCESS_MODE_ALWAYS
	#await get_tree().process_frame
	#set_process(true)
	force_camera_focus = null
	receiving_input = true
	rooms.process_mode = Node.PROCESS_MODE_ALWAYS
	shift_to(PersistentData.player_room_coords_2d)
	camera.position = cell_to_world(current_coord)
	init_rooms.call_deferred()
	get_selected_room().show_label_timer.start()
	camera.zoom = Vector2(8, 8)
	open_timer.start()
	opening = true
	closing = false
	rect_grabber.show()
	show.call_deferred()

func close_animation() -> void:
	#open_timer.stop()
	#open_timer.start()
	receiving_input = false
	shift_to(PersistentData.player_room_coords_2d)
	#force_camera_focus = PersistentData.player_room_coords_2d
	rect_grabber.hide()
	var old_pos = camera.position
	var new_pos = cell_to_world(PersistentData.player_room_coords_2d)
	camera.position = new_pos - (old_pos.direction_to(new_pos) * 20).limit_length(new_pos.distance_to(old_pos))
	rect_grabber.position = new_pos
	closing = true

func close():
	hide()
	rooms.process_mode = Node.PROCESS_MODE_DISABLED
	camera.zoom = Vector2(1, 1)
