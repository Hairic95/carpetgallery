@tool

extends BaseMap

class_name RandomRoom

signal generation_finished()

const CELL_SIZE = 8

const ENTRANCE_PADDING = -5
const EXIT_PADDING = -0
const VERT_OFFSET = 16
const VERT_OFFSET_SOUTH = 16
const HORIZ_OFFSET = 16
const CAMERA_PADDING_H = 0
const CAMERA_PADDING_V = 0
const V_ENTRANCE_OFFSET = 8

### generation params
const TILE_RARITY = 6
const MAX_NUM_COLOR_SCHEMES = 5

const MIN_AMPLITUDE_FOR_OBJECT_GENERATION = 0.5

### scenes
const FLOOR = preload("res://Procgen/Map/parts/Floor.tscn")
const WALL = preload("res://Procgen/Map/parts/Wall.tscn")
const DUNGEON_WALL = preload("res://Procgen/Map/parts/DungeonWall.tscn")
const BASE_OBJECT = preload("res://Procgen/Object/RandomObject.tscn")

var MAP_START: Vector2:
	get:
		return -MAP_SIZE_CELLS * CELL_SIZE / 2.0

var MAP_END: Vector2:
	get:
		return MAP_SIZE_CELLS * CELL_SIZE / 2.0

var MAP_SIZE: Vector2i:
	get:
		return CELL_SIZE * MAP_SIZE_CELLS

const MAP_EXIT = preload("res://worlds/map/MapExit.tscn")


@export_tool_button("Generate", "Callable")
var test_generate: Callable = _test_generate

@export_group("Generation Parameters")
@export var MAP_SIZE_CELLS = Vector2i(21, 21)

@export_group("Other")
@export var expand_camera_bounds = true


@onready var floor_tiles: Node2D = $FloorTiles
@onready var wall_tiles: Node2D = $WallTiles
@onready var object_holder: Marker2D = $Objects

@onready var west_entrance: MapEntrance = $WestEntrance
@onready var east_entrance: MapEntrance = $EastEntrance
@onready var south_entrance: MapEntrance = $SouthEntrance
@onready var north_entrance: MapEntrance = $NorthEntrance
@onready var center_entrance: MapEntrance = $CenterEntrance

@onready var west_exit: MapExit = $WestExit
@onready var east_exit: MapExit = $EastExit
@onready var north_exit: MapExit = $NorthExit
@onready var south_exit: MapExit = $SouthExit

@onready var west_boundary: CollisionShape2D = %WestBoundary
@onready var east_boundary: CollisionShape2D = %EastBoundary
@onready var north_boundary: CollisionShape2D = %NorthBoundary
@onready var south_boundary: CollisionShape2D = %SouthBoundary

@onready var west_arrow: Node2D = $WestArrow
@onready var east_arrow: Node2D = $EastArrow
@onready var north_arrow: Node2D = $NorthArrow
@onready var south_arrow: Node2D = $SouthArrow

var floor_map: Array2D
var color_map: Array2D
var wall_map: Dictionary = {}
var object_map: Dictionary = {}

@export var noise_1 := FastNoiseLite.new()
@export var noise_2 := FastNoiseLite.new()
@export var noise_3 := FastNoiseLite.new()
@export var noise_4 := FastNoiseLite.new()
@export var noise_5 := FastNoiseLite.new()
@export var noise_6 := FastNoiseLite.new()

var color_schemes = []
var color_scheme_materials = []
var num_color_schemes := 0
var color_scheme_1 := 0
var color_scheme_2 := 0
var color_scheme_3 := 0
var color_scheme_4 := 0
var color_scheme_5 := 0
var num_total_objects = 0
#var floor_color_indices = {}
var floor_color_weights = {}

var most_used_color_scheme: ColorGradient

var occupied_coords = {}
var generated := false

var placed_object_index = 0
var total_placed_objects_this_set = 0
var placed_object_ratio:
	get:
		return float(placed_object_index) / float(total_placed_objects_this_set)

var footstep_sound: AudioStream
var music_stream: AudioStream

var entrance_sprites = {}

var entrance_cells = []
	
var center_cells = []
	
var pattern_dicts = []

var object_terrain_pattern_dicts = []

var rng_meta = BetterRng.new()
var rng_pattern = BetterRng.new()
var rng_color = BetterRng.new()
var rng_texture = BetterRng.new()
var rng_object = BetterRng.new()
var rng_person = BetterRng.new()
var rng_audio = BetterRng.new()

var room_coords = Vector3i(0, 0, 0)
var amplitude := 0.0

var lobby: bool:
	get:
		return room_coords == Vector3i(0, 0, 0)

var seed: int = 0


func _ready() -> void:
	super._ready()
	update_positions()
	wall_tiles.visible = !PersistentData.hide_border
	PersistentData.hide_border_setting_changed.connect(func(): wall_tiles.visible = !PersistentData.hide_border)
	#tile_map_layer.clear()

func _process(delta: float) -> void:
	super._process(delta)
	if Engine.is_editor_hint():
		update_positions()

func _test_generate() -> void:
	#if lobby:
		#return
	
	generate(randi())
	
func generate(seed=null) -> void:
	generated = true
	
	if seed != null:
		self.seed = seed
	
	initialize_generation()

	amplitude = pow(rng_meta.randf_range(0.0, 1.0), 1.2)
	#amplitude = 1.0
	
	var gradient_brightness = rng_color.randfn(-0.25, 0.25)
	if rng_color.percent(50):
		gradient_brightness = NAN
	elif rng_color.percent(20):
		gradient_brightness = rng_color.randfn(0.1, 0.5)
	
	num_color_schemes = clamp(round(rng_pattern.randfn(lerpf(1.0, float(MAX_NUM_COLOR_SCHEMES), remap(amplitude, 0.0, 1.0, 0.25, 1.0)), 3.0)) * 1.0, 3.0, MAX_NUM_COLOR_SCHEMES)
	for i in range(num_color_schemes):
		var gradient: ColorGradient = ColorGen.generate_gradient(rng_color, gradient_brightness)
		color_schemes.append(gradient)
		color_scheme_materials.append(gradient.generate_material())
	
	num_color_schemes = color_schemes.size()
	color_scheme_1 = rng_color.randi() % num_color_schemes
	color_scheme_2 = rng_color.randi() % num_color_schemes
	color_scheme_3 = rng_color.randi() % num_color_schemes
	color_scheme_4 = rng_color.randi() % num_color_schemes
	color_scheme_5 = rng_color.randi() % num_color_schemes
	
	# spawn floors
	for y in range(MAP_SIZE_CELLS.y):
		for x in range(MAP_SIZE_CELLS.x):
			var floor = FLOOR.instantiate()
			floor_tiles.add_child(floor)
			floor.position = Vector2(x, y) * CELL_SIZE
			floor_map.set_cell_force_used(x, y, floor)
	
	for procedure in determine_generation_procedures():
		procedure.call()
	
	generation_finished.emit()

func initialize_generation():
	Utils.clear_children(floor_tiles)
	#Utils.clear_children(wall_tiles)
	Utils.clear_children(object_holder)
	
	west_exit.map = RoomInfo.coords_to_name(Vector3i(-1, 0, 0) + room_coords)
	east_exit.map = RoomInfo.coords_to_name(Vector3i(1, 0, 0) + room_coords)
	north_exit.map = RoomInfo.coords_to_name(Vector3i(0, -1, 0) + room_coords)
	south_exit.map = RoomInfo.coords_to_name(Vector3i(0, 1, 0) + room_coords)
	
	rng_meta.seed = seed
	rng_color.seed = seed
	rng_pattern.seed = seed + 1
	rng_texture.seed = seed
	rng_object.seed = seed
	rng_person.seed = seed
	rng_audio.seed = seed

	floor_map = Array2D.new(MAP_SIZE_CELLS.x, MAP_SIZE_CELLS.y)
	color_map = Array2D.new(MAP_SIZE_CELLS.x, MAP_SIZE_CELLS.y)
	wall_map = {}
	object_map = {}

	noise_1 = FastNoiseLite.new()
	noise_2 = FastNoiseLite.new()
	noise_3 = FastNoiseLite.new()
	noise_4 = FastNoiseLite.new()
	noise_5 = FastNoiseLite.new()
	noise_6 = FastNoiseLite.new()
	
	randomize_noise(noise_1)
	randomize_noise(noise_2)
	randomize_noise(noise_3)
	randomize_noise(noise_4)
	randomize_noise(noise_5)
	randomize_noise(noise_6)

		
func randomize_noise(noise: FastNoiseLite):
	noise.seed = rng_pattern.randi()
	noise.frequency = clamp(rng_pattern.randfn(0.15, 0.65), 0.0, 1.0)
	noise.noise_type = rng_pattern.choose([
		FastNoiseLite.TYPE_CELLULAR,
		FastNoiseLite.TYPE_PERLIN,
		FastNoiseLite.TYPE_SIMPLEX,
		FastNoiseLite.TYPE_SIMPLEX_SMOOTH,
		FastNoiseLite.TYPE_VALUE,
		FastNoiseLite.TYPE_VALUE_CUBIC,
	])
	noise.fractal_type = rng_pattern.choose([
		FastNoiseLite.FRACTAL_FBM,
		FastNoiseLite.FRACTAL_NONE,
		FastNoiseLite.FRACTAL_PING_PONG,
		FastNoiseLite.FRACTAL_RIDGED,
	])
	noise.fractal_gain = rng_pattern.randfn(0.15, 0.25)

func determine_generation_procedures() -> Array[Callable]:
	var arr: Array[Callable] = []
	
	var generation_type = rng_meta.weighted_choice_dict({
		generate_normal: 1000,
	})
	
	arr.append(generation_type)
	
	return arr

func generate_normal() -> void:
	generate_floors_normal()
	generate_objects_normal()
	generate_audio_normal()

func generate_audio_normal() -> void:
	footstep_sound = rng_audio.weighted_choice_dict(AudioGen.footstep_sounds)
	if pow(amplitude, 2) > 0.6 or num_total_objects >= rng_audio.randfn(10, 1) and rng_audio.percent(90):
		music_stream = rng_audio.choose(AudioGen.music)


func generate_floors_normal() -> void:
	const MAX_PATTERN_COUNT = 10

	
	for i in range(int(clampf(absf(rng_pattern.randfn(0, 4 * amplitude)), 1, MAX_PATTERN_COUNT))):
		pattern_dicts.append(get_pattern_weights())
	#print(pow(amplitude, 3))
	
	#Utils.print_dict(Utils.dicts_to_percents(pattern_dicts[0]))
	#print(pattern_dicts.size())
		
	var color_pattern: Callable = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
	var texture_pattern: Callable = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
	var h_flip_pattern: Callable = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
	var v_flip_pattern: Callable = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
	var rotate_pattern: Callable = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
	var tile_pattern: Callable = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
	var wall_pattern: Callable = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))


	var base_color_scheme = rng_pattern.randi() % num_color_schemes
	
	var floor_tile_sprites = []
	for i in range(num_color_schemes):
		floor_tile_sprites.append(rng_texture.choose(SpriteGen.floor_tiles))
	
	var color_index_multiplier = rng_pattern.randi()
	var texture_index_multiplier = rng_pattern.randi()
	var h_flip_index_multiplier = rng_pattern.randi()
	var v_flip_index_multiplier = rng_pattern.randi()
	var rotate_index_multiplier = rng_pattern.randi()
	var tile_index_multiplier = rng_pattern.randi()
	var wall_pattern_index_multiplier = rng_pattern.randi()

	var texture_conforms_to_color = rng_pattern.chance(0.5)
	
	var get_pattern_index = func(callable: Callable, x:int, y:int, multiplier: int) -> int:
		return ((base_color_scheme + callable.call(x, y)) * multiplier) % num_color_schemes
		
	var tiled_materials = []

	for mat in color_scheme_materials:
		var new = mat.duplicate()
		new.set_shader_parameter("tile", 2)
		tiled_materials.append(new)


	var process_sprite = func(sp: Sprite2D, floor_cell: Vector2i, color_index):
		var color_scheme_material: ShaderMaterial = color_scheme_materials[color_index]
		if color_index in floor_color_weights:
			floor_color_weights[color_index] += 1
		else:
			floor_color_weights[color_index] = 1
		sp.material = color_scheme_material
		if texture_conforms_to_color:
			sp.texture = floor_tile_sprites[color_index]
		else:
			var texture_index = get_pattern_index.call(texture_pattern, floor_cell.x, floor_cell.y, texture_index_multiplier)
			sp.texture = floor_tile_sprites[texture_index]
		sp.flip_h = get_pattern_index.call(h_flip_pattern, floor_cell.x, floor_cell.y, h_flip_index_multiplier) % 2 == 0
		sp.flip_v = get_pattern_index.call(v_flip_pattern, floor_cell.x, floor_cell.y, v_flip_index_multiplier) % 2 == 0
		sp.rotation = get_pattern_index.call(rotate_pattern, floor_cell.x, floor_cell.y, rotate_index_multiplier) * (PI/2)

		var tile_amount = get_pattern_index.call(tile_pattern, floor_cell.x, floor_cell.y, tile_index_multiplier) % TILE_RARITY
		#if darken:
			#sp.material = darkened_materials[color_index]
		if tile_amount == 0:
			sp.material = tiled_materials[color_index]
			#if darken:
				#sp.material = darkened_tiled_materials[color_index]
		#floor_color_indices[floor_cell] = color_index
		if color_map.contains_v(floor_cell):
			color_map.set_cell_force_used(floor_cell.x, floor_cell.y, color_schemes[color_index])

	for floor_cell in floor_map.used_positions():
		var color_index = get_pattern_index.call(color_pattern, floor_cell.x, floor_cell.y, color_index_multiplier)
		var floor: Node2D = floor_map.get_cell_v_unsafe(floor_cell)
		process_sprite.call(floor.sprite, floor_cell, color_index)

	for sprite in entrance_sprites:
		var floor_cell = entrance_sprites[sprite]
		var color_index = get_pattern_index.call(color_pattern, floor_cell.x, floor_cell.y, color_index_multiplier)
		process_sprite.call(sprite, floor_cell, color_index)
		
	var wall_image_material = color_scheme_materials[rng_pattern.weighted_choice_dict(floor_color_weights)]
	var use_solid_wall_color = rng_pattern.percent(10)
	
	var dungeon_wall_texture = rng_texture.weighted_choice_dict(SpriteGen.dungeon_wall_tiles)
	var border_tile_collision_shape = RectangleShape2D.new()
	border_tile_collision_shape.size = Vector2.ONE * CELL_SIZE * 0.5
	var border_tile_collision_object = StaticBody2D.new()
	wall_tiles.add_child(border_tile_collision_object)
	
	var wall_index = rng_pattern.randi() % 2
	var use_wall_tile_pattern = rng_pattern.percent(80)
	
	var border_variant_tiles: Dictionary[StringName, Array] = {
		&"north": [Vector2(1, 0), Vector2(2, 0)],
		&"south": [Vector2(1, 6), Vector2(2, 6)],
		&"east": [Vector2(0, 1), Vector2(0, 2)],
		&"west": [Vector2(6, 1), Vector2(6, 2)],
	}
	var num_border_variants: int = border_variant_tiles[&"north"].size()
	
	var create_border_tile = func(x: int, y: int, will_hide = false):
		var floor_cell = Vector2i(x, y)
		var color_index = get_pattern_index.call(color_pattern, floor_cell.x, floor_cell.y, color_index_multiplier)
		var floor = FLOOR.instantiate()
		wall_tiles.add_child(floor)
		floor.z_index -= 1
		floor.position = floor_cell * CELL_SIZE
		process_sprite.call(floor.sprite, floor_cell, color_index)

		var dungeon_wall = DUNGEON_WALL.instantiate()
		
		if use_wall_tile_pattern:
			wall_index = (get_pattern_index.call(wall_pattern, floor_cell.x, floor_cell.y, tile_index_multiplier))
		
		var coords = null
				
		var num_h_entrances = 2 if MAP_SIZE_CELLS.x % 2 == 0 else 3
		var num_v_entrances = 2 if MAP_SIZE_CELLS.y % 2 == 0 else 3
		
		var h_door_start = MAP_SIZE_CELLS.x / 2 - num_h_entrances / 2
		var h_door_end = MAP_SIZE_CELLS.x / 2 + num_h_entrances / 2 - 1
		var v_door_start = MAP_SIZE_CELLS.y / 2 - num_v_entrances / 2
		var v_door_end = MAP_SIZE_CELLS.y / 2 + num_v_entrances / 2 - 1
		
		var has_collision = true
		
		#var entrance = floor_cell + Vector2i(1 if x < 0 else (-1 if x >= MAP_SIZE_CELLS.x else 0), 1 if y < 0 else (-1 if y >= MAP_SIZE_CELLS.y else 0))
	
		
		var result = null
		if x == -1 and y == -1:
			dungeon_wall.set_coords(Vector2i(0, 0))
		elif x == -1 and y == MAP_SIZE_CELLS.y:
			dungeon_wall.set_coords(Vector2i(0, 6))
		elif x == MAP_SIZE_CELLS.x and y == MAP_SIZE_CELLS.y:
			dungeon_wall.set_coords(Vector2i(6, 6))
		elif x == MAP_SIZE_CELLS.x and y == -1:
			dungeon_wall.set_coords(Vector2i(6, 0))
		elif x == h_door_start - 1:
			dungeon_wall.set_coords(Vector2i(3, 0 if y == -1 else 6))
			if y == -1 or y == MAP_SIZE_CELLS.y:
				result = Vector2(x, y - (1 if y == -1 else -1))
		elif x == h_door_end + 1:
			dungeon_wall.set_coords(Vector2i(5, 0 if y == -1 else 6))
			if y == -1 or y == MAP_SIZE_CELLS.y:
				result = Vector2(x, y - (1 if y == -1 else -1))
		elif x >= h_door_start and x <= h_door_end:
			dungeon_wall.set_coords(Vector2i(4, 0 if y == -1 else 6))
			has_collision = false
			entrance_cells.append(floor_cell)
		elif x > -1 and x < h_door_start or x > h_door_end and x < MAP_SIZE_CELLS.x:
			if y == -1:
				dungeon_wall.set_coords(border_variant_tiles[&"north"][wall_index % num_border_variants])
			else:
				dungeon_wall.set_coords(border_variant_tiles[&"south"][wall_index % num_border_variants])

		elif y == v_door_start - 1:
			dungeon_wall.set_coords(Vector2i(0 if x == -1 else 6, 3))
			if x == -1 or x == MAP_SIZE_CELLS.x:
				result = Vector2(x - (1 if x == -1 else -1), y)
		elif y == v_door_end + 1:
			dungeon_wall.set_coords(Vector2i(0 if x == -1 else 6, 5))
			if x == -1 or x == MAP_SIZE_CELLS.x:
				result = Vector2(x - (1 if x == -1 else -1), y)
		elif y >= v_door_start and y <= v_door_end:
			dungeon_wall.set_coords(Vector2i(0 if x == -1 else 6, 4))
			has_collision = false
			entrance_cells.append(floor_cell)

		elif y < v_door_start - 1 or y > v_door_start + 1:
			if x == -1:
				dungeon_wall.set_coords(border_variant_tiles[&"east"][wall_index % num_border_variants])
			else:
				dungeon_wall.set_coords(border_variant_tiles[&"west"][wall_index % num_border_variants])

		if has_collision:
			occupied_coords[floor_cell] = true
			var collision_shape = CollisionShape2D.new()
			collision_shape.shape = border_tile_collision_shape
			border_tile_collision_object.add_child(collision_shape)
			collision_shape.position = floor.position
		wall_tiles.add_child(dungeon_wall)
		if !use_solid_wall_color:
			wall_image_material = color_scheme_materials[color_index]
		dungeon_wall.texture = dungeon_wall_texture
		dungeon_wall.material = wall_image_material
		dungeon_wall.position = floor.position
		if will_hide:
			dungeon_wall.hide()
			floor.hide()
		return result
	

	for x in range(-1, MAP_SIZE_CELLS.x + 1):
		for y in [-1, MAP_SIZE_CELLS.y]:
			var result = create_border_tile.call(x, y)
			if result:
				create_border_tile.call(result.x, result.y, true)
	
	for x in [-1, MAP_SIZE_CELLS.x]:
		for y in range(0, MAP_SIZE_CELLS.y):
			var result = create_border_tile.call(x, y)
			if result:
				create_border_tile.call(result.x, result.y, true)

	west_arrow.material = color_scheme_materials[0]
	east_arrow.material = color_scheme_materials[0]
	north_arrow.material = color_scheme_materials[0]
	south_arrow.material = color_scheme_materials[0]
	
	var astar = AStarGrid2D.new()

	for x in range(0 if MAP_SIZE_CELLS.x % 2 == 0 else -1, 2):
		for y in range(0 if MAP_SIZE_CELLS.x % 2 == 0 else -1, 2):
				center_cells.append(MAP_SIZE_CELLS/2 + Vector2i(x - 1, y - 1))
	
	
	var solid_cells = []
	var pattern_mul = rng_pattern.randi()

	var entrance_neighbors = []

	for entrance_cell in entrance_cells:
		entrance_neighbors.append(entrance_cell)
		for neighbor in Utils.all_dirs:
			entrance_neighbors.append(entrance_cell + neighbor)
	var CONNECTIONS_NEEDED = entrance_cells.size()

	if rng_pattern.percent(90):
		for i in range(int(rng_pattern.randfn(1, 2))):
			for j in range(3):
				solid_cells.clear()
				astar.clear()
				astar.region = Rect2i(-1, -1, MAP_SIZE_CELLS.x+2, MAP_SIZE_CELLS.y+2)
				astar.cell_size = Vector2i(CELL_SIZE, CELL_SIZE)
				astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
				astar.update()
				var pattern = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
				var erase_pattern = rng_pattern.weighted_choice_dict(rng_pattern.choose(pattern_dicts))
				var valid = false
				var solid_placed = false
				var connections_left = CONNECTIONS_NEEDED
				var connections_made = []
				
				for cell in occupied_coords:
					if astar.is_in_boundsv(cell):
						astar.set_point_solid(cell)

				for cell in floor_map.used_positions():
					#if cell in center_cells:
						#continue
					if cell in occupied_coords:
						continue
					if cell in entrance_neighbors:
						continue
					var solid = (pattern.call(cell.x, cell.y) * pattern_mul) % 2 == 0 and !(erase_pattern.call(cell.x, cell.y) * pattern_mul) % 2 == 0
					if solid:
						astar.set_point_solid(cell, true)
						solid_cells.append(cell)
						solid_placed = true

				if solid_placed:
					for entrance in entrance_cells:
						for entrance_other in entrance_cells:
							if astar.is_in_boundsv(entrance) and astar.is_in_boundsv(entrance_other):
								var far_enough = true
								for other in connections_made:
									if entrance.distance_to(other) < 8:
										far_enough = false

								if far_enough:
									var path = astar.get_id_path(entrance, entrance_other)
									
									if path:
										
										if far_enough:
											connections_left -= 1
											connections_made.append(entrance_other)
											if connections_left == 0:
												valid = true
												break

				var tex = rng_pattern.choose(SpriteGen.wall_tiles)
				if rng_pattern.percent(50) and tex in [
					preload("res://Procgen/Map/assets/wall_tiles/wall_tiles22.png"),
					preload("res://Procgen/Map/assets/wall_tiles/wall_tiles23.png"),
					preload("res://Procgen/Map/assets/wall_tiles/wall_tiles24.png"),
					preload("res://Procgen/Map/assets/wall_tiles/wall_tiles9.png"),
				]:
					tex = rng_pattern.choose(SpriteGen.wall_tiles)

				if valid:
					var color = color_scheme_materials[rng_color.weighted_choice_dict(floor_color_weights)]
					for cell in solid_cells:
						var color_index = get_pattern_index.call(pattern, cell.x, cell.y, color_index_multiplier)
						occupied_coords[cell] = true
						var wall = WALL.instantiate()
						wall_tiles.add_child(wall)
						wall.sprite.material = color
						wall.sprite.texture = tex
						wall.sprite.texture_repeat = true
						wall.position = cell * CELL_SIZE + Vector2i(0, 4)
						#process_sprite.call(wall.sprite, cell, color_index)
					break

	most_used_color_scheme = color_schemes[Utils.dict_max(floor_color_weights)]

		

func get_border_positions() -> Array[Vector2]:
	var arr: Array[Vector2] = []
	var start_y = 0
	var start_x = 0
	var end_y = MAP_SIZE_CELLS.y
	var end_x = MAP_SIZE_CELLS.x - 1

	for x in range((MAP_SIZE_CELLS.x / 2) - 2):
		var x2 = (MAP_SIZE_CELLS.x / 2) + 2 + x
		arr.append(Vector2(x, start_y))
		arr.append(Vector2(x2, start_y))
		arr.append(Vector2(x, end_y))
		arr.append(Vector2(x2, end_y))

	for y in range(0, ((MAP_SIZE_CELLS.y / 2) - 2)):

		var y2 = (MAP_SIZE_CELLS.y / 2) + 2 + y
		arr.append(Vector2(start_x, y))
		#arr.append(Vector2(start_x, y - 0.5))
		arr.append(Vector2(start_x, y2))
		#arr.append(Vector2(start_x, y2 + 0.5))
		arr.append(Vector2(end_x, y))
		#arr.append(Vector2(end_x, y - 0.5))
		arr.append(Vector2(end_x, y2))
		#arr.append(Vector2(end_x, y2 + 0.5))
		
	return arr

func get_pattern_weights() -> Dictionary:
	return get_non_noise_pattern_weights().merged({
		random_noise_pattern(rng_pattern): 70,
		random_noise_pattern(rng_pattern): 70,
		random_noise_pattern(rng_pattern): 70,
		random_noise_pattern(rng_pattern): 70,
		random_noise_pattern(rng_pattern): 70,
		random_noise_pattern(rng_pattern): 70,
	})

func get_non_noise_pattern_weights() -> Dictionary:
	return { 
		pattern_solid_color: 50,
		pattern_checkerboard.bind(rng_pattern.randi()): 25,
		pattern_checkerboard2: 15,
		pattern_checkerboard3.bind(rng_pattern.randi_range(1, 3), rng_pattern.randi_range(1, 10)): 15,
		pattern_crosshatch.bind(rng_pattern.randi_range(1, 10), rng_pattern.randi(), rng_pattern.randi()): 15,
		pattern_diag1.bind(rng_pattern.randi()): 10,
		pattern_diag2.bind(rng_pattern.randi()): 10,
		pattern_v_stripes.bind(rng_pattern.randi(), int(clampf(rng_pattern.randfn(1, 5), 1, 10))): 15,
		pattern_h_stripes.bind(rng_pattern.randi(), int(clampf(rng_pattern.randfn(1, 5), 1, 10))): 15,
		pattern_h_stripes2.bind(rng_pattern.randi(), int(clampf(rng_pattern.randfn(1, 5), 1, 10))): 15,
		pattern_v_stripes2.bind(rng_pattern.randi(), int(clampf(rng_pattern.randfn(1, 5), 1, 10))): 15,
		pattern_filled_circle.bind(rng_pattern.randf_range(0.0, 2.0)): 3,
		pattern_concentric_circles.bind(rng_pattern.signed_randi(), rng_pattern.signed_randi(), rng_pattern.randf_range(0.0, 10.0)): 5,
		pattern_gradient_h: 3,
		pattern_gradient_v: 3,
		pattern_diamond_grid.bind(rng_pattern.randi_range(1, 10)): 1,
		pattern_spiral.bind(rng_pattern.randf_range(0.0, 2.0)): 1,
		pattern_diagonal_cross.bind(rng_pattern.randi_range(2, 10), rng_pattern.randi_range(2, 10)): 3,
	}
	
func random_noise_pattern(rng: BetterRng) -> Callable:
	return rng.choose([
			pattern_noise.bind(noise_1),
			pattern_noise.bind(noise_2),
			pattern_noise.bind(noise_3),
			pattern_noise.bind(noise_4),
			pattern_noise.bind(noise_5),
			pattern_noise.bind(noise_6),
	])

func random_noise(rng: BetterRng) -> FastNoiseLite:
	return rng.choose([
		noise_1,
		noise_2,
		noise_3,
		noise_4,
		noise_5,
		noise_6,
	])

func pattern_solid_color(x: int, y: int) -> int:
	return 1

func pattern_checkerboard(x: int, y: int, x_mod: int) -> int:
	return 1 if ((x + x_mod) % 2 == 0 and y % 2 == 0) or ((x + x_mod) % 2 == 1 and y % 2 == 1) else 2

func pattern_checkerboard2(x: int, y: int) -> int:
	if ((x) - 3) % 3 == 0 and (y - 4) % 3 == 0:
		return 3
	return 1 if ((x) % 2 == 0 and y % 2 == 0) or ((x) % 2 == 1 and y % 2 == 1) else 2

func pattern_diag1(x: int, y: int, x_mod: int) -> int:
	if ((x + x_mod) + y) % (3) == 0:
		return 2
	return 1

func pattern_diag2(x: int, y: int, x_mod: int) -> int:
	if ((x + x_mod) - y) % (3) == 0:
		return 2
	return 1
	#return 1 if (x % 2 == 0 and y % 2 == 0) or (x % 2 == 1 and y % 2 == 1) else 2

func pattern_v_stripes(x: int, y: int, x_mod: int, thickness:int) -> int:
	return 1 if (((x / thickness) + x_mod) % 2 == 0) else 2

func pattern_h_stripes(x: int, y: int, y_mod: int, thickness:int) -> int:
	return 1 if (((y / thickness) + y_mod) % 2 == 0) else 2

func pattern_v_stripes2(x: int, y: int, x_mod: int, thickness:int) -> int:
	return 1 if (((x / thickness) + x_mod) % 2 == 0) else 2 if (((x / thickness) + x_mod) % 3 != 0) else 3

func pattern_h_stripes2(x: int, y: int, y_mod: int, thickness: int) -> int:
	return 1 if (((y / thickness) + y_mod) % 2 == 0) else 2 if (((y / thickness) + y_mod) % 3 != 0) else 3

func pattern_noise(x: int, y: int, noise: FastNoiseLite) -> int:
	return int(round(noise.get_noise_2d(x / 10.0, y / 10.0) * num_color_schemes))

func pattern_filled_circle(x: int, y: int, size_mod: float) -> int:
	return 1 if Vector2(x + (0.5 if MAP_SIZE_CELLS.x % 2 == 0 else 0), y + (0.5 if MAP_SIZE_CELLS.y % 2 == 0 else 0)).distance_to(Vector2(MAP_SIZE_CELLS) / 2.0) <= ((min(MAP_SIZE_CELLS.x, MAP_SIZE_CELLS.y) / 3.5) * size_mod) else 2

func pattern_concentric_circles(x: int, y: int, pattern_modifier_1: int, pattern_modifier_2: int, size_mod: float) -> int:
	var center = Vector2(MAP_SIZE_CELLS) / 2.0
	pattern_modifier_1 = pattern_modifier_1 % MAP_SIZE_CELLS.x
	pattern_modifier_2 = pattern_modifier_2 % MAP_SIZE_CELLS.y
	var distance = Vector2(pattern_modifier_1 + x + 0.5, pattern_modifier_2 + y + 0.5).distance_to(center)
	return int((distance * size_mod) / 5) % 2 + 1
	
func pattern_gradient_h(x: int, y: int) -> int:
	return int((float(x) / MAP_SIZE_CELLS.x) * num_color_schemes) + 1
	
func pattern_gradient_v(x: int, y: int) -> int:
	return int((float(y) / MAP_SIZE_CELLS.y) * num_color_schemes) + 1

func pattern_diagonal_cross(x: int, y: int, spacing1: int, spacing2: int) -> int:
	var pattern1 = (x + y) % spacing1
	var pattern2 = (x - y) % spacing2
	return 1 if pattern1 == 0 or pattern2 == 0 else 2

func pattern_crosshatch(x: int, y: int, spacing: int, x_mod: int, y_mod: int) -> int:
	return 3 if ((x + x_mod) % spacing == 0 and (y + y_mod) % spacing == 0) else 1 if ((x + x_mod) % spacing == 0 or (y + y_mod) % spacing == 0) else 2

func pattern_spiral(x: int, y: int, tightness: float) -> int:
	var center = Vector2(MAP_SIZE_CELLS) / 2.0
	var delta = Vector2(x, y) - center
	var angle = atan2(delta.y, delta.x)
	var radius = delta.length()
	return int(((angle + radius * tightness) / (PI * 2)) * num_color_schemes) % num_color_schemes + 1
	
func pattern_checkerboard3(x: int, y: int, amplitude: int, wavelength: int) -> int:
	return 1 if (y % (2 * amplitude) < amplitude) == (x % wavelength < wavelength / 2) else 2

func pattern_diamond_grid(x: int, y: int, size: int) -> int:
	var center = Vector2(MAP_SIZE_CELLS) / 2.0
	var manhattan_distance = abs(x - center.x) + abs(y - center.y)
	return int(fposmod((manhattan_distance / size), num_color_schemes)) + 1

func generate_objects_normal():
	#if pow(amplitude, 2) < MIN_AMPLITUDE_FOR_OBJECT_GENERATION:
		#return
	#if rng_object.percent(75):
		#return
	
	const MAX_PATTERN_COUNT = 4

	var num_object_sets := int(clampf((rng_object.randfn(2, 4)), 0, 5) * pow(amplitude, 2))
	var num_people_sets := mini(int(clampf(abs(rng_object.randfn(1, 1)) * pow(amplitude, 4), 0, 10)), num_object_sets)
	num_total_objects = 0
	var num_total_people := 0
	
	var object_behavior_weights = get_object_behavior_weights()
			
	var behavior_dicts = []
	var placement_dicts = []
	
	for i in range(int(clampf(absf(rng_object.randfn(0, 2)), 1, 5))):
		behavior_dicts.append(get_object_behavior_weights())

	for i in range(int(clampf(absf(rng_object.randfn(0, 2)), 1, 5))):
		object_terrain_pattern_dicts.append(get_non_noise_pattern_weights())

	for i in range(int(clampf(absf(rng_object.randfn(10, 5)), 1, 10))):
		placement_dicts.append(get_object_placement_weights())


	for i in num_object_sets:
		var behavior_dict = rng_object.choose(behavior_dicts)
		var placement_dict = rng_pattern.choose(placement_dicts)
	
		var is_person := i < num_people_sets

		var num_objects = int(clampf(abs(rng_object.randfn(4, 2)), 1, 100))
		if is_person:
			num_objects *= rng_object.randf_range(0.1, 1.0)
		if rng_object.percent(50) and amplitude > 0.5:
			num_objects *= rng_object.randfn(4.0, 3.0)
		num_objects = int(max(num_objects, 1))
		
		var tile_array = SpriteGen.object_tiles if !(is_person) else SpriteGen.person_tiles
		if rng_object.percent(1):
			tile_array = SpriteGen.object_tiles
		
		var object_sprite_index = rng_object.choose_index(tile_array, 2)
		
		var idle_loop_speed = clamp(rng_object.randfn(1.0, 2.5), 0.1, 10.0)
		var walk_loop_speed = rng_object.randfn(0.25, 0.25)
		var idle_2nd_texture = true
		#var idle_2nd_texture = rng_object.percent(30 + (20 if is_person else 0))
		var object_material = color_scheme_materials[rng_object.randi() % num_color_schemes]
		
		var base_behavior = rng_object.weighted_choice_dict(behavior_dict)
		
		var placement = rng_pattern.weighted_choice_dict(placement_dict)
		
		var swap_textures = rng_object.percent(50)
		
		total_placed_objects_this_set = num_objects

		placed_object_index = 0
		for j in range(num_objects):
			
			if rng_object.percent(0.1):
				is_person = true
			
			var object = BASE_OBJECT.instantiate()
			object.auto_setup_components = false
			object.start_flipped = rng_pattern.percent(50)
			object_holder.add_child(object)
			
			# mutate
			var new_object_sprite_index = object_sprite_index
			
			if rng_object.percent(1.0):
				new_object_sprite_index = rng_object.choose_index(tile_array, 2)


			
			var frames = SpriteFrames.new()
			
			var texture_1 = tile_array[new_object_sprite_index]
			var texture_2 = tile_array[new_object_sprite_index + 1]
		
			var disable_collision = texture_1 in [
				preload("res://Procgen/Object/assets/object33.png"),
			]
		
			if swap_textures or rng_object.percent(5.0):
				texture_2 = tile_array[new_object_sprite_index]
				texture_1 = tile_array[new_object_sprite_index + 1]
			
			# idle anim
			frames.add_animation("Idle")
			frames.set_animation_speed("Idle", 1.0)
			frames.set_animation_loop("Idle", true)

			frames.add_frame("Idle", texture_1, clampf(idle_loop_speed * rng_object.randfn(2.0, 0.45), 0.1, 10.0))
			if idle_2nd_texture or rng_object.percent(2.5):
				frames.add_frame("Idle", texture_2, clampf(idle_loop_speed * rng_object.randfn(2.0, 0.45), 0.1, 10.0))
			
			# walk anim
			frames.add_animation("Walk")
			frames.set_animation_speed("Walk", 1.0)
			frames.set_animation_loop("Walk", true)

			frames.add_frame("Walk", texture_1, clampf(walk_loop_speed * rng_object.randfn(1.0, 0.15), 0.1, 10.0))
			frames.add_frame("Walk", texture_2, clampf(walk_loop_speed * rng_object.randfn(1.0, 0.15), 0.1, 10.0))

			object.sprite.sprite_frames = frames
			object.sprite.play("Idle")
			var mat = object_material
			if rng_object.percent(3):
				mat = color_scheme_materials[rng_object.randi() % num_color_schemes]
			object.sprite.material = mat
			
			if disable_collision:
				object.body.shape.disabled = true
			
			var behavior = base_behavior
			if rng_object.percent(10):
				behavior = rng_object.weighted_choice_dict(behavior_dict)
			
			behavior.call(object)

			var placement_cell: Vector2i
			var placement_func = placement
			
			#print(placed_object_ratio)
			
			for k in range(1000):
				if k > 100:
					placement_func = rng_pattern.weighted_choice_dict(placement_dict)
				placement_cell = placement_func.call()
				while placement_cell.x < 1 or placement_cell.x > MAP_SIZE_CELLS.x - 1 or placement_cell.y < 1 or placement_cell.y > MAP_SIZE_CELLS.y - 1:
					placement_cell = rng_pattern.weighted_choice_dict(placement_dict).call()

				if !(placement_cell in occupied_coords):
					occupied_coords[placement_cell] = true
					break

			var placement_pos = placement_cell * CELL_SIZE + Vector2i(0, 4)
			
			#print(placement_cell)
			
			object.position = placement_pos
			object.components.setup()
			placed_object_index += 1
			if is_person:
				num_total_people += 1
			
			
		num_total_objects += num_objects
	
	#print("num_object_sets: %s, num_people_sets: %s, num_total_objects: %s, num_total_people: %s" % [num_object_sets, num_people_sets, num_total_objects, num_total_people])

func get_object_behavior_weights() -> Dictionary:
	return {
		object_behavior_do_nothing: 1000,
	}
	
func object_behavior_do_nothing(object: BaseObject2D) -> void:
	pass


func get_object_placement_weights() -> Dictionary:
	return {
		object_placement_random: 500,
		object_placement_cluster.bind(object_placement_random(), absf(rng_pattern.randfn(1.0, 5.0))): 1000,
		object_placement_noise.bind(random_noise(rng_pattern), min(rng_pattern.randfn(0.8, 0.25), 1.0)): 500,
		object_placement_ring.bind(object_placement_random(), max(absf(rng_pattern.randfn(2.0, 5.0)), 1.0), randf() * TAU, rng_pattern.rand_sign()): 1000,
		object_placement_terrain_pattern.bind(rng_pattern.weighted_choice_dict(rng_pattern.choose(object_terrain_pattern_dicts)), rng_pattern.randi()): 1000,
	}

func object_placement_noise(noise: FastNoiseLite, start_threshold: float) -> Vector2i:
	var vec = null
	var t = start_threshold
	while vec == null:
		var rand = object_placement_random()
		var x = rand.x
		var y = rand.y
		if (round(noise.get_noise_2d(x / 10.0, y / 10.0))) > t:
			vec = Vector2i(x, y)
			return vec
		t -= 0.001
	return vec

func object_placement_ring(center: Vector2i, radius: float, start_angle: float, turn_dir: int):
	return Vector2i(Vector2(center) + Vector2.RIGHT.rotated(placed_object_ratio * TAU * turn_dir) * radius)


func object_placement_random() -> Vector2i:
	return Vector2i(2 + (rng_pattern.randi() % (MAP_SIZE_CELLS.x - 4)), 2 + (rng_pattern.randi() % (MAP_SIZE_CELLS.y - 4)))

func object_placement_cluster(center: Vector2i, deviation: float) -> Vector2i:
	return center + Vector2i(rng_pattern.random_vec() * int(rng_pattern.randfn(0, deviation)))

func object_placement_terrain_pattern(pattern, multiplier) -> Vector2i:
	for i in range(2):
		var x = rng_pattern.randi()
		var y = rng_pattern.randi()
		if (multiplier * pattern.call(x, y)) % 2 == 0:
			return Vector2i(x, y)
		
	return object_placement_random()
	

# TODO: separate placement functions for objects vs people

func update_positions() -> void:
	var view_size_x: float = ProjectSettings.get_setting("display/window/size/viewport_width")
	var view_size_y: float = ProjectSettings.get_setting("display/window/size/viewport_height")
	floor_tiles.position = MAP_START + ((Vector2.ONE * CELL_SIZE) / 2.0)
	wall_tiles.position = MAP_START + ((Vector2.ONE * CELL_SIZE) / 2.0)
	object_holder.position = MAP_START + ((Vector2.ONE * CELL_SIZE) / 2.0)
	if expand_camera_bounds:
		camera_bounds_start_marker.position.x = minf(-view_size_x/2.0, MAP_START.x - CAMERA_PADDING_H)
		camera_bounds_start_marker.position.y = minf(-view_size_y/2.0, MAP_START.y - CAMERA_PADDING_V)
		camera_bounds_end_marker.position.x = maxf(view_size_x/2.0, MAP_END.x + CAMERA_PADDING_H)
		camera_bounds_end_marker.position.y = maxf(view_size_y/2.0, MAP_END.y + CAMERA_PADDING_V)
	else:
		camera_bounds_start_marker.position = Vector2(-view_size_x/2.0, -view_size_y/2.0)
		camera_bounds_end_marker.position = Vector2(view_size_x/2.0, view_size_y/2.0)
	
	west_arrow.global_position = Vector2(MAP_START.x, 0)
	east_arrow.global_position = Vector2(MAP_END.x, 0)
	north_arrow.global_position = Vector2(0, MAP_START.y)
	south_arrow.global_position = Vector2(0, MAP_END.y)
	
	west_entrance.global_position.x = MAP_START.x + ENTRANCE_PADDING 
	west_entrance.global_position.y = V_ENTRANCE_OFFSET
	east_entrance.global_position.x = MAP_END.x - ENTRANCE_PADDING
	east_entrance.global_position.y = V_ENTRANCE_OFFSET
	north_entrance.global_position.x = 0
	north_entrance.global_position.y = MAP_START.y + ENTRANCE_PADDING
	south_entrance.global_position.x = 0
	south_entrance.global_position.y = MAP_END.y - ENTRANCE_PADDING
	center_entrance.global_position.x = 0
	center_entrance.global_position.y = 0
	
	west_boundary.global_position.x = MAP_START.x
	west_boundary.global_position.y = 0
	east_boundary.global_position.x = MAP_END.x
	east_boundary.global_position.y = 0
	north_boundary.global_position.x = 0
	north_boundary.global_position.y = MAP_START.y
	south_boundary.global_position.x = 0
	south_boundary.global_position.y = MAP_END.y

	west_exit.global_position.x = MAP_START.x + EXIT_PADDING - HORIZ_OFFSET
	west_exit.global_position.y = 0
	east_exit.global_position.x = MAP_END.x - EXIT_PADDING + HORIZ_OFFSET
	east_exit.global_position.y = 0
	north_exit.global_position.x = 0
	north_exit.global_position.y = MAP_START.y + EXIT_PADDING - VERT_OFFSET
	south_exit.global_position.x = 0
	south_exit.global_position.y = MAP_END.y - EXIT_PADDING + VERT_OFFSET_SOUTH


func on_player_entered():
	west_arrow.startup_timer.start()
	east_arrow.startup_timer.start()
	north_arrow.startup_timer.start()
	south_arrow.startup_timer.start()
	if !generated:
		await generation_finished
	AudioGen.play_song(music_stream)
	PersistentData.add_memory(self)
	PersistentData.player_room_coords = room_coords

func closest_unoccupied_cell_to_center():
	var avg = Vector2i()
	for cell in center_cells:
		avg += cell
	avg = Vector2(avg) / float(center_cells.size())
	
	var unoccupied = floor_map.used_positions()
	var unoccupied_dict = {}
	
	for cell in unoccupied:
		unoccupied_dict[cell] = null
	
	for cell in occupied_coords:
		unoccupied_dict.erase(cell)
	
	unoccupied = unoccupied_dict.keys()
	
	unoccupied.sort_custom(func(a,b): return Vector2(a).distance_squared_to(avg) < Vector2(b).distance_squared_to(avg))
	
	var astar := create_a_star()
	
	for cell in unoccupied:
		for entrance in entrance_cells:
			if astar.is_in_boundsv(cell) and astar.is_in_boundsv(entrance):
				var path = astar.get_id_path(cell, entrance)
				if path:
					#print(path)
					return cell
	
	return unoccupied[0]

func create_a_star() -> AStarGrid2D:
	var astar = AStarGrid2D.new()
	astar.region = Rect2i(-1, -1, MAP_SIZE_CELLS.x+2, MAP_SIZE_CELLS.y+2)
	astar.cell_size = Vector2i(CELL_SIZE, CELL_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for cell in occupied_coords:
		if astar.is_in_boundsv(cell):
			astar.set_point_solid(cell)
	return astar

func cell_to_world(cell: Vector2i) -> Vector2:
	return floor_tiles.global_position + (Vector2(cell) * CELL_SIZE)

func _draw() -> void:
	super._draw()
	if Engine.is_editor_hint():
		draw_rect(Rect2(-MAP_SIZE_CELLS * CELL_SIZE / 2.0, MAP_SIZE_CELLS * CELL_SIZE), Color.RED, false, 1.0)
