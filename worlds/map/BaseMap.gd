@tool
extends Node2D

class_name BaseMap

@export var map_colors: MapColors

var entrances = {}
var world

@onready var player_start = $PlayerStart
@onready var camera_bounds_start_marker: Marker2D = $CameraBoundsStart
@onready var camera_bounds_end_marker: Marker2D = $CameraBoundsEnd
@onready var tile_map_layer: TileMapLayer = $TileMapLayer

var camera_bounds_start: Vector2:
	get:
		return camera_bounds_start_marker.global_position

var camera_bounds_end: Vector2:
	get:
		return camera_bounds_end_marker.global_position

func _ready():
	if map_colors == null:
		map_colors = MapColors.new()
	if Engine.is_editor_hint():
		return

	for child in get_children():
		if child is MapEntrance:
			entrances[child.name] = child
		if child is Sprite2D:
			child.y_sort_enabled = true

	if !Engine.is_editor_hint():
		set_process(false)

func _process(delta: float) -> void:
	queue_redraw()

func get_object(object_name: String) -> BaseObject2D:
	for child in get_children().filter(func(c): c is BaseObject2D):
		if child.name == object_name:
			return child
	return null

func _draw():
	if Engine.is_editor_hint():
		draw_rect(Rect2(to_local(camera_bounds_start), camera_bounds_end - camera_bounds_start), Color.PURPLE, false, 1.0)

func on_player_entered():
	pass
