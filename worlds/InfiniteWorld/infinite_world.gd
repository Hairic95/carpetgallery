extends World

class_name InfiniteWorld

const MAX_ROOMS_LOADED = 10

const RANDOM_ROOM = preload("res://worlds/InfiniteWorld/maps/RandomRoom.tscn")
const SEED = 3443013762

var lobby: RandomRoom

var loaded_rooms: Array[String] = []

@onready var camera: GoodCamera = $GoodCamera
@export var player: BaseObject2D


func _ready() -> void:
	setup_lobby.call_deferred()
	super._ready()
	
func setup_lobby() -> void:
	lobby = initialize_room("Room 0_0_0")
	add_map(lobby)
	#lobby.generate(randi())
	lobby.generate()
	#activate_map(lobby.name)
	tp_to_room.call_deferred(lobby)
	

func tp_to_room(room: RandomRoom):
	player.global_position = room.cell_to_world(room.closest_unoccupied_cell_to_center())
	room.on_player_entered()

func add_map(map: BaseMap) -> void:
	super.add_map(map)

func activate_map(map: String) -> void:
	#if !(map in maps):
		#initialize_room(map)
	var old_map = active_map
	super.activate_map(map)
	var new_map = maps[map]
	if new_map is RandomRoom:
		if !new_map.generated:
			new_map.generate()
		if !new_map.lobby and not (map in loaded_rooms):
				loaded_rooms.append(map)
		while loaded_rooms.size() > MAX_ROOMS_LOADED:
			#await get_tree().physics_frame
			var map_to_remove = loaded_rooms[0]
			loaded_rooms.remove_at(0)
			remove_map.call_deferred(map_to_remove)
	#Debug.dbg("loaded_rooms", loaded_rooms)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
func map_transition(map: String) -> void:
	if !(map in maps):
		initialize_room(map)
	$MapExitSound.play()
	super.map_transition(map)
	
func initialize_room(map: String) -> RandomRoom:
	var room_info := process_room_info(map)
	var room = create_room(room_info)
	return room

func create_room(room_info: RoomInfo) -> RandomRoom:
	var instance = RANDOM_ROOM.instantiate()
	var seed = hash(SEED) + hash(room_info.coords)
	instance.name = room_info.to_name()
	instance.room_coords = room_info.coords
	instance.seed = seed
	add_map(instance)

	return instance
	
func process_room_info(map_name: String) -> RoomInfo:
	var split = map_name.split(" ")
	var coords = split[1].split("_")
	return RoomInfo.new(Vector3i(int(coords[0]), int(coords[1]), int(coords[2])))
