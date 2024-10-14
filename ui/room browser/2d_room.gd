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

func _ready():
	t = randf() * 1000
	#label.text = ""
	#label_shadow.text = ""
#
	#label.text = "%s,%s" % [coords.x, coords.y]
	#label_shadow.text = label.text

	mat = texture_rect.material
	
	# what the fuck am i doing
	set_col_1 = func(col): 
		mat.set_shader_parameter("col_1", col)
		old_color_1 = col
	set_col_2 = func(col): 
		mat.set_shader_parameter("col_2", col)
		old_color_2 = col
	set_col_3 = func(col): 
		mat.set_shader_parameter("col_3", col)
		old_color_3 = col
	set_col_4 = func(col): 
		mat.set_shader_parameter("col_4", col)
		old_color_4 = col
		
	assert(grid_div_1 <= grid_div_2)
	
	h_bar.color = grid_line_color
	v_bar.color = grid_line_color

	PersistentData.room_memory_updated.connect(update_memory)
	PersistentData.player_notes_updated.connect(update_notes)
	update()
	
	label_holder.hide()

func initialize() -> void:
	var new_color_1 = unknown_color_1
	var new_color_2 = unknown_color_2
	var new_color_3 = unknown_color_3
	var new_color_4 = unknown_color_4
	var new_shadow_color = unknown_color_shadow
	var new_outline_color = unknown_color_outline

	set_col_1.call(unknown_color_1)
	set_col_2.call(unknown_color_2)
	set_col_3.call(unknown_color_3)
	set_col_4.call(unknown_color_4)
	
	color_rect_shadow.color =  new_shadow_color
	color_rect_outline.color = new_outline_color


func _process(delta: float) -> void:
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
		new_label_color = memory.most_used_color.color_4
		new_shadow_color = memory.most_used_color.color_4
		new_outline_color = memory.most_used_color.color_3


	if (new_color_1 != old_color_1 or new_color_2 != old_color_2 or new_color_3 != old_color_3 or new_color_4 != old_color_4) and visible:
		
		set_col_1.call(Math.splerp_color(old_color_1, new_color_1, delta, COLOR_SPLERP_HALF_LIFE))
		set_col_2.call(Math.splerp_color(old_color_2, new_color_2, delta, COLOR_SPLERP_HALF_LIFE))
		set_col_3.call(Math.splerp_color(old_color_3, new_color_3, delta, COLOR_SPLERP_HALF_LIFE))
		set_col_4.call(Math.splerp_color(old_color_4, new_color_4, delta, COLOR_SPLERP_HALF_LIFE))

		color_rect_shadow.color =  Math.splerp_color(color_rect_shadow.color, new_shadow_color, delta, COLOR_SPLERP_HALF_LIFE)
		color_rect_outline.color = Math.splerp_color(color_rect_outline.color, new_outline_color, delta, COLOR_SPLERP_HALF_LIFE)
	
	#var show_label = (selected) and show_label_timer.is_stopped()
	#label_holder.modulate.a = Math.splerp(label_holder.modulate.a, (1.0 if show_label else 0.0), delta, 1 if show_label_timer.is_stopped() else 0.)
#
	#var label_color = label.get("theme_override_colors/font_color")
	#if new_label_color != label_color and visible:
		#label.set("theme_override_colors/font_color", Math.splerp_color(label_color, new_label_color, delta, COLOR_SPLERP_HALF_LIFE))
	#
	
	player_room = PersistentData.player_room_coords == coords
	
	
	
	var target_pos = Vector2(0, vertical_offset)
	rect_holder.position = Math.splerp_vec(rect_holder.position, target_pos, delta, 2.0)
	
	t += delta

func select():
	selected = true
	vertical_offset = -1

func deselect():
	selected = false
	vertical_offset = 0

func update():
	update_memory()
	update_notes()

func update_memory():
	if coords == null:
		return
	load_from_memory(PersistentData.get_memory(coords))

func update_notes():
	if coords == null:
		return

func load_from_memory(memory: VisitedRoomMemory):
	if memory == self.memory:
		return

	#if memory:
		#var tex = ImageTexture.create_from_image(memory.room_picture)
		#floor_texture.texture = tex
	#else:
		#floor_texture.texture = null


	self.memory = memory
