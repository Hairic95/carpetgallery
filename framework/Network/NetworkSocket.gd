extends Node

var current_username : String = ""

var web_socket_client : WebSocketPeer = null
var socket_initialized = false

var current_web_id = ""

var lobby_data = null
var current_map_key = "Map001"

# Web socket signals
signal web_socket_connected()
signal web_socket_disconnected()

# Web socket message signals
signal connection(success)

signal update_user_list(success, users)
signal player_join(id, position, direction)
signal player_left(webId)

signal get_users_result(users)

signal game_started()

signal entity_position_update(data)
signal entity_hard_position_update(data)
signal entity_update_map_coordinates(data)
signal entity_update_state(data)
signal entity_update_flip(data)
signal entity_misc_process_data(data)
signal entity_misc_one_off(data)
signal entity_death(data)
signal entity_spawn(data)
signal on_set_seed(seed)

signal entity_added(data)
signal entity_updated(data)
signal set_room_content(data)

func _ready():
	var new_timer = Timer.new()
	add_child(new_timer)
	new_timer.timeout.connect(send_message_heartbeat)
	new_timer.wait_time = 20
	new_timer.start()

func _process(_delta):
	if _is_web_socket_connected():
		web_socket_client.poll()
		
		var state = web_socket_client.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if !socket_initialized:
				socket_initialized = true
				connection_established()
			while web_socket_client.get_available_packet_count():
				data_received(web_socket_client.get_packet())
		elif state == WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		elif state == WebSocketPeer.STATE_CLOSED:
			var code = web_socket_client.get_close_code()
			var reason = web_socket_client.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			connection_closed(code == OK)

func connect_to_server(server_url: String, username : String):
	if _is_web_socket_connected():
		web_socket_client.close()
	
	current_username = username
	
	web_socket_client = WebSocketPeer.new()
	
	web_socket_client.connect_to_url(server_url)
	
	await get_tree().create_timer(4.0).timeout
	
	if !(_is_web_socket_connected()):
		web_socket_client.close()
		emit_signal("web_socket_disconnected")
	

func data_received(packet):
	#var packet = web_socket_client.get_peer(1).get_packet().get_string_from_utf8()
	parse_message_received(JSON.parse_string(packet.get_string_from_utf8()))

func connection_established():
	print("Connected! Sending Connect confirmation message")
	emit_signal("web_socket_connected")

func connection_closed(was_clean_close):
	web_socket_client = null
	print("Web socket connection was closed")
	emit_signal("web_socket_disconnected")
func connection_error():
	web_socket_client = null
	print("Web socket connection was interrupted")
	emit_signal("web_socket_disconnected")
func connection_failed():
	web_socket_client = null
	print("Web socket connection failed")
	emit_signal("web_socket_disconnected")

func _send_message(action : String, payload : Dictionary):
	if _is_web_socket_connected():
		var message = {
			"action": action,
			"payload": payload
		}
		var parsed_message = JSON.stringify(message)
		web_socket_client.send_text(parsed_message)

func _is_web_socket_connected() -> bool:
	return web_socket_client != null

func send_message_connect(username : String, position: Vector2 = Vector2.ZERO, map_coordinates = Vector2.ZERO):
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_Connect, 
			{
				"secretKey" : NetworkConstants.Server_SecretKey, 
				"username" : username,
				"position": { 
					"x": position.x,
					"y": position.y
				},
				"map_coordinates": {
					"x": map_coordinates.x,
					"y": map_coordinates.y
				}
			})

func send_message_get_users():
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_GetUsers,  {})

func send_message(messageContent):
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_MessageToRoom, messageContent)

func send_message_to_server(messageContent):
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_MessageToServer, messageContent)

func send_message_heartbeat():
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_Heartbeat, {})

func send_get_seed():
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_GetSeed, {})

func send_add_entity(entity):
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_AddEntity, entity)

func send_get_room_data(map_coordinates):
	if _is_web_socket_connected():
		_send_message(NetworkConstants.Action_GetRoomData, {"map_coordinates": {"x": map_coordinates.x, "y": map_coordinates.y,}})

func parse_message_received(json_message):
	if json_message.has("action") && json_message.has("payload"):
		
		match(json_message.action):
			NetworkConstants.Action_Connect:
				if json_message.payload.has("success") &&  json_message.payload.has("webId"):
					current_web_id = json_message.payload.webId
					emit_signal("connection", json_message.payload.success)
					if !json_message.payload.success:
						web_socket_client.close()
				else:
					emit_signal("connection", false)
					web_socket_client.close()
			NetworkConstants.Action_GetUsers:
				if json_message.payload.has("users"):
					update_user_list.emit(json_message.payload.users)
			NetworkConstants.Action_PlayerJoin:
				if json_message.payload.has("id") && json_message.payload.has("position"):
					emit_signal("player_join", json_message.payload)
			NetworkConstants.Action_PlayerLeft:
				if json_message.payload.has("webId"):
					emit_signal("player_left", json_message.payload.webId)
			NetworkConstants.Action_MessageToRoom, NetworkConstants.Action_MessageToServer:
				if json_message.payload.has("type"):
					match (json_message.payload.type):
						NetworkConstants.GenericAction_EntityUpdatePosition:
							if json_message.payload.has("position"):
								entity_position_update.emit(json_message.payload)
						NetworkConstants.GenericAction_EntityUpdatePosition:
							if json_message.payload.has("position"):
								emit_signal("entity_hard_position_update", json_message.payload)
						NetworkConstants.GenericAction_EntityUpdateState:
							if json_message.payload.has("state"):
								entity_update_state.emit(json_message.payload)
						NetworkConstants.GenericAction_EntityUpdateFlip:
							if json_message.payload.has("flip"):
								entity_update_flip.emit(json_message.payload)
						NetworkConstants.GenericAction_EntityUpdateMapCoordinates:
							entity_update_map_coordinates.emit(json_message.payload)
						NetworkConstants.GenericAction_EntityMiscProcessData:
							emit_signal("entity_misc_process_data", json_message.payload)
						NetworkConstants.GenericAction_EntityMiscOneOff:
							emit_signal("entity_misc_one_off", json_message.payload)
						NetworkConstants.GenericAction_EntityDeath:
							emit_signal("entity_death", json_message.payload)
						NetworkConstants.GenericAction_EntitySpawn:
							emit_signal("entity_spawn", json_message.payload)
			NetworkConstants.Action_GameStarted:
				emit_signal("game_started")
			NetworkConstants.Action_MapSelected:
				current_map_key = json_message.payload.mapKey
			NetworkConstants.Action_SetSeed:
				on_set_seed.emit(json_message.payload.seed)
			NetworkConstants.Action_AddedEntity:
				entity_added.emit(json_message.payload)
			NetworkConstants.Action_UpdatedEntity:
				entity_updated.emit(json_message.payload)
			NetworkConstants.Action_SetRoomData:
				set_room_content.emit(json_message.payload)

func current_pos_in_lobby():
	if lobby_data:
		for i in lobby_data.players.size():
			if lobby_data.players[i].id == current_web_id:
				return i
	return 2000

func get_position_in_lobby():
	if lobby_data == null || !lobby_data.has("players"):
		return 0
	var result = 0
	for i in lobby_data.players.size():
		if lobby_data.players[i].id == current_web_id:
			result = i
			break
	return result
