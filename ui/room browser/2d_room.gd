extends Node2D

class_name RoomBox2D

const COLOR_SPLERP_HALF_LIFE = 4.0

@export var unknown_color_1: Color
@export var unknown_color_2: Color
@export var unknown_color_3: Color
@export var unknown_color_4: Color
@export var unknown_color_coords: Color
@export var unknown_color_shadow: Color
@export var unknown_color_outline: Color
@export var grid_line_color: Color
@export var grid_player_color: Color

@export var grid_div_1: int
@export var grid_div_2: int

@export var noise: FastNoiseLite

@onready var texture_rect: TextureRect = %ColorRect
@onready var label: Label = %Label
@onready var label_shadow: Label = %LabelShadow

@onready var rect_holder: Node2D = %RectHolder
@onready var label_holder: Node2D = %LabelHolder
@onready var color_rect_shadow: ColorRect = $ColorRectShadow

@onready var show_label_timer: Timer = $ShowLabelTimer
@onready var color_rect_outline: ColorRect = %ColorRectOutline
@onready var h_bar: ColorRect = $HBar
@onready var v_bar: ColorRect = $VertBar

@onready var floor_texture: Sprite2D = %FloorTexture

@onready var player_room_indicator: Sprite2D = %PlayerRoomIndicator
@onready var bookmark_indicator: Sprite2D = %BookmarkIndicator
@onready var dialogue_indicator: Sprite2D = %DialogueIndicator
@onready var door_indicator: Sprite2D = %DoorIndicator
@onready var music_indicator: Sprite2D = %MusicIndicator
@onready var object_indicator: Sprite2D = %ObjectIndicator
@onready var indicators: Node2D = %Indicators

@onready var close_timer: Timer = $CloseTimer

var coords
var memory: VisitedRoomMemory

var selected = false

var player_room = false

var vertical_offset = 0.0

var mat: ShaderMaterial
var set_col_1: Callable
var set_col_2: Callable
var set_col_3: Callable
var set_col_4: Callable

var old_color_1: Color = Color.BLACK
var old_color_2: Color = Color.BLACK
var old_color_3: Color = Color.BLACK
var old_color_4: Color = Color.BLACK

var t = 0.0

var is_bookmarked = false
var has_dialogue = false
var has_door = false
var has_music = false
var has_object = false


func _ready():
	t = randf() * 1000
	#label.text = ""
	#label_shadow.text = ""
#
	floor_texture.texture = ImageTexture.new()

	#label.text = "%s,%s" % [coords.x, coords.y]
	#label_shadow.text = label.text

	mat = texture_rect.material
	
	dialogue_indicator.material = mat
	door_indicator.material = mat
	music_indicator.material = mat
	object_indicator.material = mat

	assert(grid_div_1 <= grid_div_2)
	
	h_bar.color = grid_line_color
	v_bar.color = grid_line_color

	#PersistentData.room_memory_updated.connect(update_memory)
	#PersistentData.player_location_changed.connect(update_player_room)
	#PersistentData.bookmarks_updated.connect(update_bookmark)
	update()
	
	label_holder.hide()

func initialize() -> void:
	var new_color_1 = unknown_color_1
	var new_color_2 = unknown_color_2
	var new_color_3 = unknown_color_3
	var new_color_4 = unknown_color_4
	var new_shadow_color = unknown_color_shadow
	var new_outline_color = unknown_color_outline

	set_col(1, unknown_color_1)
	set_col(2, unknown_color_2)
	set_col(3, unknown_color_3)
	set_col(4, unknown_color_4)
	
	color_rect_shadow.color =  new_shadow_color
	color_rect_outline.color = new_outline_color

func set_col(index: int, color: Color):
	mat.set_shader_parameter("col_%s" % index, color)
	set("old_color_%s" % index, color)

func close_anim():
	close_timer.start()
	indicators.visible = false
	await close_timer.timeout
	indicators.visible = true

func open_anim():
	show_label_timer.start()
	indicators.visible = false
	await show_label_timer.timeout
	indicators.visible = true

#
#func _process(delta: float) -> void:
	#if is_visible_in_tree():
		#
		#var can_show_labels = close_timer.is_stopped() and show_label_timer.is_stopped()
		#player_room_indicator.visible = player_room and can_show_labels
		#bookmark_indicator.visible = is_bookmarked and can_show_labels
		#dialogue_indicator.visible = has_dialogue and can_show_labels
		#door_indicator.visible = has_door and can_show_labels
		#music_indicator.visible = has_music and can_show_labels
		#object_indicator.visible = has_object and can_show_labels

func update_display() -> void:
	
	var new_color_1 = unknown_color_1
	var new_color_2 = unknown_color_2
	var new_color_3 = unknown_color_3
	var new_color_4 = unknown_color_4
	var new_label_color = unknown_color_coords
	var new_shadow_color = unknown_color_shadow
	var new_outline_color = unknown_color_outline
	

	if memory != null:
		new_color_1 = memory.most_used_color.color_1.lerp(memory.most_used_color.color_2, 0.5)
		new_color_2 = memory.most_used_color.color_2
		new_color_3 = memory.most_used_color.color_3
		new_color_4 = memory.most_used_color.color_4
		new_shadow_color = memory.most_used_color.color_4
	
	
	set_col(1, new_color_1)
	set_col(2, new_color_2)
	set_col(3, new_color_3)
	set_col(4, new_color_4)
	color_rect_shadow.color = new_shadow_color
	
	floor_texture.visible = memory and memory.image
	player_room_indicator.visible = player_room
	bookmark_indicator.visible = is_bookmarked
	dialogue_indicator.visible = has_dialogue
	door_indicator.visible = has_door
	music_indicator.visible = has_music
	object_indicator.visible = has_object
	player_room_indicator.visible = player_room
	
	var target_pos = Vector2(0, vertical_offset)



func select():
	selected = true
	vertical_offset = -1
	var tween = create_tween()
	tween.tween_property(rect_holder, "position:y", vertical_offset, 0.1)

func deselect():
	selected = false
	vertical_offset = 0
	var tween = create_tween()
	tween.tween_property(rect_holder, "position:y", vertical_offset, 0.1)

func update():
	update_player_room()
	update_memory()
	update_bookmark()

func update_player_room():

	var new_player_room = PersistentData.player_room_coords == coords

	#if player_room == new_player_room:
		#return
	player_room = new_player_room

	update_display()

func update_memory():
	if coords == null:
		memory = null
		return
	load_from_memory(PersistentData.get_memory(coords))
	update_display()

func update_bookmark():
	var same_coords = coords in PersistentData.bookmarks
	#if is_bookmarked == same_coords:
		#return
	is_bookmarked = same_coords
	update_display()

func load_from_memory(memory: VisitedRoomMemory):
	
	has_music = memory and memory.has_music()
	has_dialogue = memory and memory.has_dialogue()
	has_door = memory and memory.has_door()
	has_object = memory and memory.has_objects()
	
	if memory and memory.image:
		if is_instance_valid(memory.image):
			floor_texture.texture.set_image(memory.image)
	
	self.memory = memory
