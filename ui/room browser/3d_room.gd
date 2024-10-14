@tool
extends Node3D

class_name RoomBox

const RECT_RATIO := 28.0/20.0

const ROOM_WIDTH = 1.0
const ROOM_LENGTH = ROOM_WIDTH * RECT_RATIO
const ROOM_HEIGHT = 0.4

@onready var mesh: MeshInstance3D = $Mesh
#
#func _ready():
	#if !Engine.is_editor_hint():
		#set_process(false)
##
#func _process(delta: float) -> void:
	#if Engine.is_editor_hint():
		#update_dimensions()

func _ready():
	var rng = BetterRng.new()
	if rng.randi() % 2 == 0:
		mesh.mesh.material.albedo_color = ColorGen.random_highlight(rng)

func update_dimensions():
	mesh.mesh.size = Vector3(ROOM_LENGTH, ROOM_HEIGHT, ROOM_WIDTH)
