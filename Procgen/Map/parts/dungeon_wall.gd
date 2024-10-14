@tool

extends Sprite2D

class_name DungeonWall

const CELL_SIZE = 8

@export var coords: Vector2i:
	set(value):
		set_coords(value)
		coords = value

func set_coords(coords: Vector2i) -> void:
	region_rect.position = Vector2(coords * CELL_SIZE)
