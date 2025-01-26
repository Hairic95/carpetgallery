extends Node

const SAVE_CHUNK_SIZE = 100

signal room_memory_updated(coords: Vector3i)
signal bookmarks_updated(coords: Vector3i)
signal player_location_changed(old: Vector3i, new: Vector3i)

var player_room_coords: Vector3i:
	set(value):
		var old = player_room_coords
		player_room_coords = value
		player_room_coords_2d = Vector2i(value.x, value.y)
		if old != value:
			player_location_changed.emit(old, value)

var player_room_coords_2d: Vector2i

var player_room_position: Vector2 = Vector2()

var memories: Dictionary[Vector3i, VisitedRoomMemory] = {}

var bookmarks: Dictionary = {}

var saving = false

func _ready() -> void:
	pass

func get_save_data_dict() -> Dictionary:
	var save = {
		"coords": player_room_coords,
		#"pp": player_room_position,
		"memories": {},
		"bookmarks": bookmarks,
	}
	
	var c = Time.get_ticks_msec()
	for cell in memories:
		save.memories[cell] = memories[cell].get_save_data()
		var c2 = Time.get_ticks_msec()
		if c2 - c >= 8:
			c = Time.get_ticks_msec()
			await get_tree().process_frame
	
	return save

func save_game() -> void:
	while saving:
		await get_tree().process_frame
	saving = true
	var dict = await get_save_data_dict()
	var save_file = FileAccess.open_compressed("user://game.save", FileAccess.WRITE)
	save_file.store_var(dict, false)
	saving = false
	#print("saved")

func load_game() -> void:
	if not FileAccess.file_exists("user://game.save"):
		initialize_data()
		save_game()
		return # Error! We don't have a save to load.
	
	var save_file = FileAccess.open_compressed("user://game.save", FileAccess.READ)
	var dict = save_file.get_var()
	
	#for i in range(1):
	memories.clear()
	bookmarks.clear()
	player_room_coords *= 0

	setup_bookmarks(dict)
	setup_memories(dict)

	player_room_coords = dict.coords

func setup_bookmarks(dict):
	var c = Time.get_ticks_msec()
	for cell in dict.bookmarks:
		add_bookmark(cell, dict.bookmarks[cell])
		var c2 = Time.get_ticks_msec()
		if c2 - c >= 8:
			c = Time.get_ticks_msec()
			await get_tree().process_frame

func setup_memories(dict):
	var c = Time.get_ticks_msec()	
	for cell in dict.memories:
		var memory = (VisitedRoomMemory.from_save_data(dict.memories[cell]))
		memories[cell] = memory
		memory.updated.connect(room_memory_updated.emit.bind(cell))
		room_memory_updated.emit(cell)
		var c2 = Time.get_ticks_msec()
		if c2 - c >= 8:
			c = Time.get_ticks_msec()
			await get_tree().process_frame

func add_bookmark(coord: Vector3i, name: String):
	bookmarks[coord] = name
	bookmarks_updated.emit(coord)
	save_game()

func remove_bookmark(coord: Vector3i):
	bookmarks.erase(coord)
	bookmarks_updated.emit(coord)
	save_game()

func initialize_data():
	while saving:
		await get_tree().process_frame
	memories.clear()
	bookmarks.clear()
	player_room_coords *= 0
	memories.clear()
	bookmarks.clear()
	bookmarks[Vector3i(0, 0, 0)] = "center"

func get_memory(coords: Vector3i) -> VisitedRoomMemory:
	return memories.get(coords)

func add_memory(room: RandomRoom):
	var memory = VisitedRoomMemory.from_room(room)
	memories[room.room_coords] = memory
	memory.updated.connect(room_memory_updated.emit.bind(room.room_coords))
	room_memory_updated.emit(room.room_coords)
	#save_game()
