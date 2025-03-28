extends World

class_name InfiniteWorld

signal exit_requested

const MAX_ROOMS_LOADED = 3

const RANDOM_ROOM = preload("res://worlds/InfiniteWorld/maps/RandomRoom.tscn")
var SEED = 12

var lobby: RandomRoom

var loaded_rooms: Array[String] = []

@onready var camera: GoodCamera = $GoodCamera
@export var player: NetworkBody
@export var room_browser: RoomBrowser2D
@onready var pause_screen_layer: PauseScreenLayer = $PauseScreenLayer
@onready var screenshot_flash: ColorRect = %ScreenshotFlash
@onready var canvas_layer: CanvasLayer = $CanvasLayer
var can_screenshot = true

func _ready() -> void:
	NetworkSocket.player_join.connect(player_join)
	NetworkSocket.update_user_list.connect(get_users_result)
	NetworkSocket.on_set_seed.connect(on_set_seed)
	NetworkSocket.web_socket_connected.connect(web_socket_connected)
	NetworkSocket.connection.connect(on_completed_connection)
	NetworkSocket.set_room_content.connect(set_room_content)
	NetworkSocket.entity_added.connect(entity_added)
	NetworkSocket.connect_to_server("localhost:61900", "Test")


func _process(delta: float) -> void:
	if Debug.enabled and Input.is_action_just_pressed("debug_random"):
		_on_fast_travel_selected(Vector3i(randi_range(-100, 100), randi_range(-100, 100), 0))

func _on_screenshot_intent():
	if pause_screen_layer.menu_open:
		return
	if !can_screenshot:
		return
	can_screenshot = false
	await RenderingServer.frame_post_draw
	var texture = get_viewport().take_screenshot()

	camera_sound()
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	screenshot_flash.color.a = 0.25
	tween.tween_property(screenshot_flash, "color:a", 0.0, 0.25)
	var sprite = Sprite2D.new()
	sprite.z_index = 100
	add_child(sprite)
	sprite.texture = texture
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.set_ease(Tween.EASE_IN_OUT)
	tween2.set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(sprite, "scale", Vector2.ONE * 0.25, 0.25)
	tween2.tween_property(sprite, "position", Vector2(0, 50), 0.25)
	await tween2.finished
	tween2 = create_tween()
	tween2.set_trans(Tween.TRANS_QUAD)
	tween2.set_ease(Tween.EASE_IN_OUT)
	tween2.tween_property(sprite, "position", Vector2(0, 200), 0.25)
	await tween2.finished
	can_screenshot = true
	sprite.queue_free()

func save_memory_screenshot():
	#var image = get_viewport().get_texture().get_image()
	#var sprite = Sprite2D.new()
	#add_child(sprite)
	#sprite.texture = get_viewport().get_texture()
	#sprite.z_index += 10
	
	#await get_tree().physics_frame
	if %AnimationPlayer.is_playing():
		await %AnimationPlayer.animation_finished 
	var image = get_viewport().get_texture().get_image()
	image.resize(30, 22, Image.INTERPOLATE_NEAREST)
	image = image.get_region(Rect2i(2, 2, 26, 18))

	var memory = PersistentData.get_memory(active_map.room_coords)
	if memory:
		memory.set_image(image)
	#await get_tree().physics_frame
	player.modulate.a = 0.0
	var tween = create_tween()
	player.show()
	tween.tween_property(player, "modulate:a", 1.0, 0.1)

func camera_sound():
	$CameraSound1.play()

func _on_fast_travel_selected(coords: Vector3i,fade=false):
	var room_info = RoomInfo.new(coords)
	map_transition.call_deferred(room_info.to_name(), fade)
	PersistentData.player_room_coords = coords
	await changed_active_map
	move_object(player, active_map.name, "CenterEntrance")
	tp_to_room.call_deferred(active_map)


func setup_lobby() -> void:
	lobby = initialize_room(RoomInfo.coords_to_name(PersistentData.player_room_coords))
	add_map(lobby)
	#lobby.generate(randi())
	lobby.generate()
	#activate_map(lobby.name)
	tp_to_room.call_deferred(lobby)
	#player.global_position = PersistentData.player_room_position
	lobby.on_player_entered.call_deferred()
	await get_tree().create_timer(0.25).timeout
	save_memory_screenshot()

func tp_to_room(room: RandomRoom):
	player.global_position = room.cell_to_world(room.closest_unoccupied_cell_to_center()) + Vector2(0, 8)

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
	
func map_transition(map: String, fade=true) -> void:
	for child in %Entities.get_children():
		child.queue_free.call_deferred()
	
	if !(map in maps):
		initialize_room(map)
	$MapExitSound.play()
	player.hide()
	await super.map_transition(map, fade)
	
	NetworkSocket.send_get_room_data(player.map_coordinates)
	
	save_memory_screenshot()
	
	
func initialize_room(map: String) -> RandomRoom:
	var room_info := process_room_info(map)
	var room = create_room(room_info)
	return room

func create_room(room_info: RoomInfo) -> RandomRoom:
	var instance = RANDOM_ROOM.instantiate()
	var seed = get_room_seed(SEED, room_info.coords.x, room_info.coords.y, room_info.coords.z)
	instance.name = room_info.to_name()
	instance.room_coords = room_info.coords
	instance.seed = seed
	add_map(instance)

	return instance
	
func process_room_info(map_name: String) -> RoomInfo:
	var split = map_name.split(" ")
	var coords = split[1].split("_")
	return RoomInfo.new(Vector3i(int(coords[0]), int(coords[1]), int(coords[2])))

func get_room_seed(global_seed: int, x: int, y: int, z: int) -> int:
	# Adjust negative integers to positive
	var adjusted_x = x * 2 if x >= 0 else (-x) * 2 - 1
	var adjusted_y = y * 2 if y >= 0 else (-y) * 2 - 1
	var adjusted_z = z * 2 if z >= 0 else (-z) * 2 - 1
	
	# Combine the adjusted coordinates and global seed using the hash function
	var room_seed = hash_coordinates(global_seed, adjusted_x, adjusted_y, adjusted_z)

	return room_seed

func hash_coordinates(a: int, b: int, c: int, d: int) -> int:
	var hash = a
	hash = mix64(hash ^ b)
	hash = mix64(hash ^ c)
	hash = mix64(hash ^ d)
	return hash

func mix64(k: int) -> int:
	k = (k ^ (k >> 30)) * -4690894493242683975
	k = (k ^ (k >> 27)) * -7723592293110705685
	k = k ^ (k >> 31)
	return k & 0x7FFFFFFFFFFFFFFF  # Ensure 64-bit signed integer

func on_set_seed(seed: String) -> void:
	SEED = hash(seed)
	setup_lobby.call_deferred()
	room_browser.fast_travel_initiated.connect(_on_fast_travel_selected)
	player.get_component("MapTraversalComponent").fast_travel_initiated.connect(_on_fast_travel_selected)
	pause_screen_layer.exit_requested.connect(exit_requested.emit)
	#player.get_component(PlayerControlComponent).screenshot_intent.connect(_on_screenshot_intent)
	player.hide()
	super._ready()
	player.owner_uuid = NetworkSocket.current_web_id
	player.entity_uuid = NetworkSocket.current_web_id

func player_join(data) -> void:
	var new_player_object = preload("res://object/entities/character/player/player.tscn").instantiate()
	new_player_object.hide()
	new_player_object.global_position = Vector2(data.position.x, data.position.y)
	new_player_object.map_coordinates = Vector2(data.map_coordinates.x, data.map_coordinates.y)
	add_child(new_player_object)
	new_player_object.remove_component("MapTraversalComponent")
	new_player_object.remove_component("InteractComponent")
	new_player_object.add_to_group("OtherPlayer")
	new_player_object.set_web_id(data.id, data.id)
	new_player_object.show()

func get_users_result(users: Array) -> void:
	for user in users:
		if user.id != NetworkSocket.current_web_id:
			
			var new_player_object = preload("res://object/entities/character/player/player.tscn").instantiate()
			new_player_object.hide()
			new_player_object.global_position = Vector2(user.position.x, user.position.y)
			new_player_object.map_coordinates = Vector2(user.map_coordinates.x, user.map_coordinates.y)
			add_child(new_player_object)
			new_player_object.add_to_group("OtherPlayer")
			new_player_object.remove_component("MapTraversalComponent")
			
			new_player_object.set_web_id(user.id, user.id)
			new_player_object.show()
		

func web_socket_connected():
	player.map_coordinates = Vector2(PersistentData.player_room_coords.x, PersistentData.player_room_coords.y)
	NetworkSocket.send_message_connect("User", player.global_position, player.map_coordinates)
	
	NetworkSocket.send_get_room_data(player.map_coordinates)

func on_completed_connection(result: bool):
	if result:
		NetworkSocket.send_get_seed()
		NetworkSocket.send_message_get_users()
		player.set_username(NetworkSocket.current_username)
func set_room_content(data):
	
	for entity in data.entities:
		var new_test_entity = load("res://object/entities/character/neutral/moving_test_entity.tscn").instantiate()
		new_test_entity.entity_uuid = entity.id
		new_test_entity.global_position = Vector2(entity.position.x, entity.position.y)
		new_test_entity.owner_uuid = entity.currentOwnerId
		new_test_entity.map_coordinates = Vector2(entity.mapCoordinates.x, entity.mapCoordinates.y)
		%Entities.add_child.call_deferred(new_test_entity)
	
	if data.entities.size() == 0:
		if $Entities.get_child_count() == 0:
			for i in 9:
				for y in 10:
					var new_test_entity = load("res://object/entities/character/neutral/moving_test_entity.tscn").instantiate()
					new_test_entity.is_new = true
					new_test_entity.global_position = Vector2(-30 * 4.5 + i * 30, 0)
					new_test_entity.owner_uuid = NetworkSocket.current_web_id
					new_test_entity.map_coordinates = player.map_coordinates
					%Entities.add_child.call_deferred(new_test_entity)
					await get_tree().create_timer(.04).timeout
				

func entity_added(entity_data):
	var new_test_entity = load("res://object/entities/character/neutral/moving_test_entity.tscn").instantiate()
	new_test_entity.global_position = Vector2(entity_data.position.x, entity_data.position.y) 
	new_test_entity.owner_uuid = NetworkSocket.current_web_id
	new_test_entity.map_coordinates = Vector2(entity_data.map_coordinates.x, entity_data.map_coordinates.y)
	%Entities.add_child.call_deferred(new_test_entity)
