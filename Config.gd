extends Node

signal hide_border_setting_changed

const VOLUME_MIN = -60

var screenshot_pixel_size = 4
var fullscreen = false:
	set(value):
		fullscreen = value
		Display.toggle_fullscreen(value)

var master_volume: float:
	set(value):
		value = clamp(value, VOLUME_MIN, 0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
		save_config()
	get:
		return AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))

var music_volume: float:
	set(value):
		value = clamp(value, VOLUME_MIN, 0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
		save_config()
	get:
		return AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))

var fx_volume: float:
	set(value):
		value = clamp(value, VOLUME_MIN, 0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Fx"), value)
		save_config()
	get:
		return AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Fx"))

var config = ConfigFile.new()

var hide_border = false:
	set(value):
		var changed = hide_border != value
		if changed:
			hide_border = value
			hide_border_setting_changed.emit()

func _ready():
	load_config()

func load_config():
	var err = config.load("user://settings.cfg")
	if err != OK:
		return

	screenshot_pixel_size = config.get_value("display", "screenshot_pixel_size", 4)
	fullscreen = config.get_value("display", "fullscreen", false)
	

	master_volume = config.get_value("audio", "master_volume", 0)
	music_volume = config.get_value("audio", "music_volume", 0)
	fx_volume = config.get_value("audio", "fx_volume", 0)

func save_config():
	config = ConfigFile.new()
	config.set_value("display", "screenshot_pixel_size", screenshot_pixel_size)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "fx_volume", fx_volume)
	config.save("user://settings.cfg")
