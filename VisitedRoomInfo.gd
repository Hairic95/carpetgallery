extends RefCounted

class_name VisitedRoomMemory

var most_used_color: ColorGradient
var coords: Vector3i
var amplitude: float
var num_objects: int
#var room_picture: Image

static func from_room(room: RandomRoom):
	var desc = VisitedRoomMemory.new()
	desc.most_used_color = room.most_used_color_scheme
	desc.coords = room.room_coords
	desc.amplitude = room.amplitude
	desc.num_objects = room.num_total_objects
	
	#var image = Image.create_empty(28, 20, false, Image.FORMAT_RGBA8)
	#image.decompress()
#
	#var tile_colors = {
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles1.png"): 0.0,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles2.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles3.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles4.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles5.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles6.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles7.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles8.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles9.png"): 1.0,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles10.png"): 0.0,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles11.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles12.png"): 0.0,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles13.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles14.png"): 0.5,
		#preload("res://Procgen/Map/assets/floor_tiles/floor_tiles15.png"): 1.0,
	#}
#
	#for pos in room.floor_map.used_positions():
		#var floor = room.floor_map.get_cell_v_unsafe(pos)
		#var color_scheme = room.color_map.get_cell_v_unsafe(pos)
		#image.set_pixelv(pos, color_scheme.color_1.lerp(color_scheme.color_2, tile_colors[floor.sprite.texture]))
	#desc.room_picture = image
	#
	#image.save_png("user://image.png")
	
	return desc
