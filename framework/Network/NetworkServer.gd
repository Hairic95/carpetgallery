extends Node

class_name Server

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const MAX_CLIENTS = 4096

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.

var player_info = {"name": "Name"}

var rng = BetterRng.new()

var players = {}

func _ready():
	rng.randomize()
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	create_game()

func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error
	#if ResourceLoader.exists("user://X509_Certificate.crt") and ResourceLoader.exists("user://X509_Key.key"):
		#var cert = load("user://X509_Certificate.crt")
		#var key = load("user://X509_Key.key")
		#if cert and key:
			#error = peer.create_server(PORT, "*", TLSOptions.server(key, cert))
	#else:
	error = peer.create_server(Network.PORT)
	if error:
		print(error)
		return error
	print("starting server on port " + str(Network.PORT))

	multiplayer.multiplayer_peer = peer

	players[1] = player_info
	player_connected.emit(1, player_info)

@rpc("any_peer", "call_remote", "reliable")
func _send_message(sender_id: int, message: String):
	if !(await player_registered(sender_id)):
		message_fail.rpc_id(sender_id)
		return
	if message.strip_edges() == "":
		message_fail.rpc_id(sender_id)
		return
		
	message = process_message(message)

	_receive_message.rpc(sender_id, message)

	message_ok.rpc_id(sender_id)

func process_message(message: String) -> String:
	return message


@rpc("authority", "call_remote", "reliable")
func message_ok():
	pass
	
@rpc("authority", "call_remote", "reliable")
func message_fail():
	pass

func player_registered(id):
	for i in range(120):
		if id in players and players[id] != null and !players[id].is_empty():
			return true
		else:
			await get_tree().physics_frame
	return false

@rpc("authority", "call_remote", "reliable")
func _receive_message(sender_id: int, message: String):
	pass

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null

func _on_player_disconnected(id):
	print("%s disconnected" % id)
	players.erase(id)
	player_disconnected.emit(id)

func _on_player_connected(id):
	print("%s connected" % id)
	players[id] = {}
	player_disconnected.emit(id)
