extends NetworkBody
class_name BaseObject2D

var x:
	get:
		return global_position.x
	set(x):
		global_position.x = x

var y:
	get:
		return global_position.y
	set(y):
		global_position.y = y

var xy:
	get:
		return global_position
	set(xy):
		global_position = xy

var hitstopped = false
var hit_tween
var rng = BetterRng.new()
var fx = ObjectFx.new(self)

var auto_setup_components = true

var current_state = "Idle"

var map: BaseMap:
	get:
		return get_parent()

var room: RandomRoom:
	get:
		return map

var world: World:
	get:
		return map.get_parent().get_parent()

var sounds = {}

@export var story_variables = {}

@export var start_flipped = false

@onready var components: ComponentContainer = %Components
@onready var sprite: AnimatedSprite2D = %Sprite
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var flip: Node2D = $"%Flip"

func _ready():
	if start_flipped: set_flip(-1)
	
	if animation_player and animation_player.has_animation("RESET"):
		animation_player.play("RESET")
	if Engine.is_editor_hint():
		set_physics_process(false)
		set_process(false)
		return
	for sound in %Sounds.get_children():
		sounds[sound.name] = sound
	for child in get_children():
		if child is BaseComponent:
			remove_child.call_deferred(child)
			components.add.call_deferred(child)

func reset_rotation():
	flip.rotation = 0

func set_flip(dir):
	if dir < 0:
		flip.scale.x = -1
		components.set_flip(-1)
	elif dir > 0:
		flip.scale.x = 1
		components.set_flip(1)

func follow_body(xy: Vector2):
	self.xy = xy

func add_component(component: BaseComponent) -> void:
	components.add(component)

func get_component(type) -> BaseComponent:
	return components.get_component(type)

func get_components(type) -> Array[BaseComponent]:
	return components.get_components(type)

func play_sound(sound_name: String):
	var sound = sounds[sound_name]
	if sound is VariableSound2D:
		sound.go()
	else:
		sounds[sound_name].play()

func set_story_variable(key, value):
	story_variables[key] = value

func get_story_variable(key):
	if key in story_variables:
		return story_variables[key]
	return false

func get_nearby_object(object_name: String) -> BaseObject2D:
	return map.get_object(object_name)

func stop_sound(sound_name: String):
	sounds[sound_name].stop()

func set_state(state):
	if current_state == state:
		%Sprite.play(state)

func _physics_process(delta):
	pass
	
