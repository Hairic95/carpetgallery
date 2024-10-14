extends Node

class_name Client

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal message_received(message, data, sender_id)
signal message_sent
signal sent_message_failed

signal left_server()
signal joined_server()

#const DEFAULT_SERVER_IP = "wss://ivysly.com:%s" % PORT

# originally: 
# this works on windows executable, and "run in browser" but not from any https site

#const DEFAULT_SERVER_IP = "ws://localhost:%s" % PORT

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.c
# For example, the value of "name" can be set to something the player
# entered in a UI scene.

var my_id = null
var connected:
	get:
		return multiplayer.multiplayer_peer != null

func _ready():
	multiplayer.multiplayer_peer = null
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	join_server()

func quit_chat():
	_on_server_disconnected()
	left_server.emit()


func send_message(message):
	_send_message.rpc_id(1, my_id, message)

@rpc("any_peer", "call_remote", "reliable")
func _send_message(my_id: int, message: String):
	pass

@rpc("authority", "call_remote", "reliable")
func _receive_message(sender_id: int, message: String):
	pass

func join_server(address = ""):
	if address.is_empty():
		address = Network.DEFAULT_URL
	var peer = ENetMultiplayerPeer.new()
	#var error = peer.create_client(address, TLSOptions.client(load("res://cert/X509_Certificate.crt")))
	var error = peer.create_client(address, Network.PORT)
	if error:
		print(error)
		return error
	multiplayer.multiplayer_peer = peer

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null

func get_player_info():
	return {}

@rpc("authority", "call_remote", "reliable")
func message_ok():
	message_sent.emit()

	
@rpc("authority", "call_remote", "reliable")
func message_fail():
	sent_message_failed.emit()

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	pass

func _on_connected_ok():
	print("connected")
	var peer_id = multiplayer.get_unique_id()

	player_connected.emit(peer_id, get_player_info())
	my_id = peer_id
	joined_server.emit()

func _on_connected_fail():
	print("disconnected")
	multiplayer.multiplayer_peer = null
	my_id = null

func _on_server_disconnected():
	print("disconnected")
	multiplayer.multiplayer_peer = null
	my_id = null

	server_disconnected.emit()
