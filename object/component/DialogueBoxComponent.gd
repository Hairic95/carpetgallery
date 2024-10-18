extends BaseComponent

class_name DialogueBoxComponent

var active: bool = false

@onready var window

func _ready():
	pass

func start(dialogue: DialogueResource, title: String, extra = []):
	#window = preload("res://ui/dialogue/dialogue_window.tscn").instantiate()
	window = preload("res://ui/dialogue/balloon.tscn").instantiate()
	#window = preload("res://addons/dialogue_manager/example_balloon/small_example_balloon.tscn").instantiate()
	
	window.finished.connect(end)
	_start.call_deferred(dialogue, title, extra)

func _start(dialogue: DialogueResource, title: String, extra = []):
	object.get_parent().get_parent().get_parent().get_parent().get_parent().add_child(window)
#	window.tree_exited.connect(set.bind("window", null))
#	object.world.process_mode = PROCESS_MODE_DISABLED
	window.start(dialogue, title, extra)
	object.get_component(PlayerControlComponent).busy = true
	object.get_component(CharacterIntentComponent).interact = false
	active = true

func end():
	get_component(CharacterIntentComponent).reset()
	get_component(InteractComponent).reset()
	object.get_component(PlayerControlComponent).busy = false
	object.get_component(PlayerControlComponent).interact_timer.start()
	active = false
#	object.world.process_mode = PROCESS_MODE_INHERIT
	if window:
		window.queue_free()
		window = null
