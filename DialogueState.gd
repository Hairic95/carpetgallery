extends Node

var talking_to: NetworkBody
var rng: BetterRng = BetterRng.new()
var vars:
	get:
		return talking_to.story_variables

func _ready():
	rng.randomize()

func dialogue_get(property):
	var obj_variable = get_var(property)
	if obj_variable:
		return obj_variable
	return false

func get_var(key):
	return talking_to.get_story_variable(key)

func set_var(key, value):
	talking_to.set_story_variable(key, value)

func get_player_var(key):
	GlobalState.player.get_story_variable(key)

func set_player_var(key, value):
	GlobalState.player.set_story_variable(key, value)

func get_nearby_var(object_name, key):
	var obj = talking_to.get_nearby_object(object_name)
	if obj:
		return obj.get_story_variable(key)
	return false

func set_nearby_var(object_name, key, value):
	var obj = talking_to.get_nearby_object(object_name)
	if obj:
		return obj.get_story_variable(key)
	return false

func percent(num):
	return rng.percent(num)
