extends CharacterBody2D
class_name NetworkBody

var active: bool = true
var is_neutral = false
var current_speed = 0
var speed = 0

var packet_time = 0
var packet_timer = .05
var owner_uuid = ""
var entity_uuid = ""

var target_position: Vector2 = Vector2.ZERO
var movement_direction: Vector2 = Vector2.ZERO

var map_coordinates = Vector2.ZERO

func _ready():
	target_position = global_position
	NetworkSocket.entity_updated.connect(entity_updated)
	NetworkSocket.entity_position_update.connect(remote_entity_position_update)
	NetworkSocket.entity_update_state.connect(remote_entity_update_state)
	NetworkSocket.entity_update_flip.connect(remote_entity_update_flip)
	NetworkSocket.entity_update_map_coordinates.connect(remote_entity_update_map_coordinates)
	NetworkSocket.entity_hard_position_update.connect(remote_entity_hard_update_position)
	NetworkSocket.entity_misc_process_data.connect(remote_entity_misc_process_data)
	NetworkSocket.entity_misc_one_off.connect(remote_entity_misc_one_off)
	NetworkSocket.entity_death.connect(remote_entity_death)
	

func _physics_process(delta):
	if is_client_owner():
		if packet_time >= packet_timer:
			NetworkSocket.send_message({
				"entity_id": entity_uuid, #NetworkSocket.current_web_id,
				"type": NetworkConstants.GenericAction_EntityUpdatePosition,
				"position": {
					"x": global_position.x,
					"y": global_position.y,
				},
				"speed": current_speed,
			})
			packet_time = 0
		else:
			packet_time += delta
	else:
		if (map_coordinates != GlobalState.player.map_coordinates):
			global_position = lerp(global_position, target_position, .2) 

func change_map_coordinates(_map_coords: Vector2) -> void:
	if is_client_owner():
		map_coordinates = _map_coords
		NetworkSocket.send_message_to_server({
			"entity_id": entity_uuid,
			"type": NetworkConstants.GenericAction_EntityUpdateMapCoordinates,
			"map_coordinates": {
				"x": _map_coords.x,
				"y": _map_coords.y
			},
			"position": {
				"x": global_position.x,
				"y": global_position.y
			},
		})
		for other_player in get_tree().get_nodes_in_group("OtherPlayer"):
			if other_player is NetworkBody:
				if other_player.map_coordinates == _map_coords:
					other_player.global_position = other_player.target_position
				else:
					other_player.global_position = Vector2(-100, -100)

func remote_entity_position_update(data):
	if data.entity_id == entity_uuid:
		target_position = Vector2(data.position.x, data.position.y)
		movement_direction = Vector2(data.position.x, data.position.y) - target_position
		speed = data.speed
		

func remote_entity_update_state(data):
	if data.entity_id == entity_uuid:
		pass

func remote_entity_hard_update_position(data):
	if data.entity_id == entity_uuid:
		target_position = Vector2(data.position.x, data.position.y)
		global_position = Vector2(data.position.x, data.position.y)

func remote_entity_misc_process_data(data):
	if data.entity_id == entity_uuid:
		pass

func remote_entity_death(data):
	if data.entity_id == entity_uuid:
		queue_free()

func remote_entity_misc_one_off(data):
	if data.entity_id == entity_uuid:
		pass

func remote_entity_update_flip(data):
	if data.entity_id == entity_uuid:
		pass

func remote_entity_update_map_coordinates(data):
	if data.entity_id == entity_uuid:
		map_coordinates = Vector2(data.map_coordinates.x, data.map_coordinates.y)
		if GlobalState.player.map_coordinates == map_coordinates:
			remote_entity_hard_update_position(data)
		else:
			global_position = Vector2(-100, -100)

func is_client_owner():
	return owner_uuid == NetworkSocket.current_web_id

func entity_updated(data):
	if entity_uuid == data.entity.id:
		owner_uuid = data.entity.currentOwnerId
