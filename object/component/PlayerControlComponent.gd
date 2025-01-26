extends BaseComponent

class_name PlayerControlComponent

signal screenshot_intent

var intent: CharacterIntentComponent
var dialogue_box: DialogueBoxComponent

var busy := false
var interact_timer: Timer

func _ready():
	interact_timer = Timer.new()
	interact_timer.wait_time = 0.1
	interact_timer.one_shot = true
	add_child.call_deferred(interact_timer)

func setup():
	intent = get_component(CharacterIntentComponent)
	dialogue_box = get_component(DialogueBoxComponent)

func _physics_process(delta):
	if intent == null:
		return
	
	if Input.is_action_just_pressed("tertiary"):
		screenshot_intent.emit()

	if dialogue_box.active:
		intent.reset()
		return

	intent.move_dir = Utils.bools_to_vector2(Input.is_action_pressed("move_left"), Input.is_action_pressed("move_right"), Input.is_action_pressed("move_up"), Input.is_action_pressed("move_down")).normalized()
	intent.aim_global = get_global_mouse_position()
	intent.interact = Input.is_action_just_pressed("primary") if interact_timer.is_stopped() else false

	Debug.dbg("interact", intent.interact)
	
	if busy:
		intent.reset()

	PersistentData.player_room_position = object.global_position
