extends Node2D

class_name MenuScreen

signal option_selected(option: String)

@onready var pointer: Sprite2D = %Pointer
@onready var start: Node2D = %Start
@onready var options: Node2D = %Options
@onready var quit: Node2D = %Quit


@onready var items = [
	start,
	#options,
	quit,
]

var item_selected = 0

var is_open = false

func open():
	show()
	%Blip.play()
	item_selected = 0
	is_open = true

func close():
	hide()
	is_open = false

func _process(delta: float) -> void:
	if !is_open:
		return
	var old = item_selected
	if Input.is_action_just_pressed("move_down"):
		item_selected += 1
	if Input.is_action_just_pressed("move_up"):
		item_selected -= 1
	item_selected = item_selected % items.size()
	var selected = items[item_selected]
	if old != item_selected:
		%Blip.play()

	pointer.position.y = Math.splerp(pointer.position.y, selected.position.y, delta, 0.5)


	if Input.is_action_just_pressed("secondary") or Input.is_action_just_pressed("menu"):
		%Blip.play()
		option_selected.emit("resume")
	if Input.is_action_just_pressed("primary"):
		%Blip.play()
		if selected == start:
			option_selected.emit("resume")

		if selected == quit:
			hide()
			PersistentData.save_game()
			option_selected.emit("quit")
