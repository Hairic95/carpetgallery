extends Node2D

class_name BookmarkViewer

const DIST = 14

signal option_selected(option)

@onready var options_holder: Node2D = $OptionsHolder
@onready var select_arrow: Sprite2D = $SelectArrow

var options = [

]

var coords = [
	
]

var selected_option = 0

var is_open = false


func _ready():
	hide()
	pass


func open():
	show()
	setup_options.call_deferred()

	selected_option = 0
	is_open = true

func setup_options():
	var option_names = [
	]

	for option in options_holder.get_children():
		option.free()
		options.clear()
	coords.clear()
	
	var c = 0
	for cell in PersistentData.bookmarks:
		if !is_open:
			return

		var map_option = preload("res://ui/room browser/bookmark_option.tscn").instantiate()
		map_option.name = PersistentData.bookmarks[cell]
		
		coords.append(cell)
		options_holder.add_child(map_option)

		options.append(map_option)
		
		c += 1
		if c % 1 == 0:
			await get_tree().process_frame

	for i in range(options.size()):
		options[i].position.y = i * DIST

func close():
	#hide()

	selected_option = 0
	is_open = false

func _process(delta: float) -> void:
	position.x = Math.splerp(position.x, (-200 if !is_open else -100), delta, 2.0)
	if position.x <= -150 and !is_open:
		hide()
	position.y = get_parent().offset.y
	options_holder.position.y = Math.splerp(options_holder.position.y, -selected_option * DIST, delta, 0.5)
	for option in options_holder.get_children():
		option.position.x = Math.splerp(option.position.x, -5 if option == options[selected_option] else -10.0, delta, 0.5)
	
	
	if is_open and options.size() > 0:
		if Input.is_action_just_pressed("primary"):
			var coord = coords[selected_option]
			option_selected.emit(coord)
			close()
		elif Input.is_action_just_pressed("secondary"):
			option_selected.emit(null)
		if Input.is_action_just_pressed("move_up"):
			selected_option -= 1
		if Input.is_action_just_pressed("move_down"):
			selected_option += 1
		selected_option = posmod(selected_option, options.size())
		#selected_option = clamp(selected_option, 0, options.size() - 1)
		var option = options[selected_option]
		select_arrow.global_position.y = Math.splerp(select_arrow.global_position.y, option.global_position.y, delta, 1.0)
