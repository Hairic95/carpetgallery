extends Node

signal hide_border_setting_changed
signal room_memory_updated
signal player_notes_updated

var player_room_coords: Vector3i

var player_room_coords_2d: Vector2i:
	get:
		return Vector2(player_room_coords.x, player_room_coords.y)

var player_room_position: Vector2 = Vector2()

var memories: Dictionary[Vector3i, VisitedRoomMemory] = {}

var player_notes: Dictionary[Vector3i, PlayerRoomNotes] = {}

var hide_border = false:
	set(value):
		var changed = hide_border != value
		if changed:
			hide_border = value
			hide_border_setting_changed.emit()


func _ready() -> void:
	pass

func get_save_data_dict() -> Dictionary:
	var save = {}
	
	return save

func save_game() -> void:
	pass

func load_game() -> void:
	pass

func get_memory(coords: Vector3i) -> VisitedRoomMemory:
	return memories.get(coords)

func add_memory(room: RandomRoom):
	memories[room.room_coords] = VisitedRoomMemory.from_room(room)
	room_memory_updated.emit()
