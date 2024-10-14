extends Node

const ADDRESS = ""

const URL = "ivysly.com"
#const URL = "168.235.86.185"
const PORT = 8443

#@onready var DEFAULT_URL = "ws://" + URL + ":" + str(PORT)
@onready var DEFAULT_URL = URL
#@onready var DEFAULT_SERVER_IP = "ws://" + URL
#@onready var DEFAULT_SERVER_IP = "ws://" + URL

var root: Node

var client: Client:
	get:
		return root

var server: Server:
	get:
		return root

var is_server := false

func _ready():
	if OS.has_feature("server") or OS.get_cmdline_args().has("--server"):
		is_server = true
		root = Server.new()
	else:
		root = Client.new()
	root.name = "Root"
	add_child(root, true)
