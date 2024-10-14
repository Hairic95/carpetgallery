@tool
extends Node3D

class_name RoomBrowser

const GRID_DIMENSIONS = Vector2i(20, 20)
const _3D_ROOM = preload("res://ui/room browser/3DRoom.tscn")

const ROOM_DISTANCE = 1.2

@onready var camera: Camera3D = %Camera3D
@onready var room_holder: Node3D = %RoomHolder

var player: BaseObject2D

func _ready() -> void:
	setup_room_grid.call_deferred()

func setup_room_grid() -> void:
	for x in range(GRID_DIMENSIONS.x):
		for y in range(GRID_DIMENSIONS.y):
			var room = _3D_ROOM.instantiate()
			room_holder.add_child(room)
			var x_offset = GRID_DIMENSIONS.x / 2
			var y_offset = GRID_DIMENSIONS.y / 2
			room.position = Vector3((x - x_offset) * ROOM_DISTANCE * room.RECT_RATIO, (y - y_offset) * ROOM_DISTANCE, 0.0)
