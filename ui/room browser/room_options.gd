extends Node2D

const WIDTH = 90
const LINE_SPACING = 10

signal option_selected(option: String)

var room: RoomBox2D

var drawing_line_1_amount = 0.0
var drawing_line_2_amount = 0.0

var active = false

var tween

@onready var coords_label: Label = %CoordsLabel
@onready var amplitude_label: Label = %AmplitudeLabel
@onready var num_objects_label: Label = %NumObjectsLabel
@onready var num_people_label: Label = %NumPeopleLabel
@onready var people_class_label: Label = %PeopleClassLabel
@onready var door_class_label: Label = %DoorClassLabel
@onready var bookmark_label: Label = %BookmarkLabel
@onready var bookmark_sprite: Sprite2D = %BookmarkSprite


func reset():
	drawing_line_1_amount = 0.0
	drawing_line_2_amount = 0.0


func process_room(room: RoomBox2D):
	self.room = room
	reset()
	
	coords_label.text = "%s, %s" % [room.coords.x, room.coords.y]
	amplitude_label.text = "energy: %s" % (("%0.1f" % (pow(room.memory.amplitude, 2) * 100)) if room.memory else "???")
	num_objects_label.text = "bodies: %s" % (("%d" % room.memory.num_objects) if room.memory else "???")
	num_people_label.text = "company: %s" % (("%d" % room.memory.num_people) if room.memory else "???")
	people_class_label.text = "%s" % (("lively" if room.memory.num_people > 0 or room.memory.has_dialogue() else "dormant") if room.memory else "???")
	door_class_label.text = "%s" % (("portalic" if room.memory.has_door() else "euclidean") if room.memory else "???")
	bookmark_label.text = "%s" % PersistentData.bookmarks[room.coords] if PersistentData.bookmarks.has(room.coords) else ""

	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(false)
	tween.tween_property(self, "drawing_line_1_amount", 1.0, 0.05)
	tween.tween_property(self, "drawing_line_2_amount", 1.0, 0.1)
	#tween.tween_property(self, "drawing_line_3_amount", 1.0, 0.1)
	active = true
	await option_selected
	active = false

func _process(delta: float) -> void:
	queue_redraw()
	#if active:
		#if Input.is_action_just_pressed("secondary"):
			#await close_window_animation()
			#option_selected.emit("cancel")

func close():
	close_window_animation()

func close_window_animation():
	if tween:
		tween.kill()
	tween = create_tween()
	#drawing_line_1_amount = 1.0
	#drawing_line_2_amount = 1.0
	tween.set_parallel(false)
	#tween.tween_property(self, "drawing_line_3_amount", 0.0, 0.05)
	tween.tween_property(self, "drawing_line_2_amount", 0.0, 0.05)
	tween.tween_property(self, "drawing_line_1_amount", 0.0, 0.05)
	await tween.finished
	

func _draw():
	if drawing_line_1_amount > 0:
		var roompos = to_local(room.global_position)
		var line_1_offset = Vector2(30, -30)
		var circle_radius = 17

		var line_1_start = roompos + Vector2(18, -15)
		#draw_circle(roompos, circle_radius, Color.WHITE, true, -1.0)
		var line_1_end = (line_1_start + (line_1_offset) * drawing_line_1_amount)
		var line_2_end = (line_1_end + Vector2(WIDTH, 0.0) * drawing_line_2_amount)

		var rect_corner_1 = Vector2(17, -13)
		var rect_end_1 = rect_corner_1 + Vector2(-34, 0) * drawing_line_1_amount
		var rect_end_2 = rect_corner_1 + Vector2(0, 26) * drawing_line_1_amount

		draw_line(line_1_start, (line_1_end), Color.WHITE, -1)
		var c = Color.BLACK
		c.a = 0.5
		draw_rect(Rect2(line_1_end, Vector2(WIDTH * drawing_line_2_amount, 64)), c, true)
		draw_line(rect_corner_1, rect_end_1, Color.WHITE, -1)
		draw_line(rect_corner_1, rect_end_2, Color.WHITE, -1)
		
		if drawing_line_2_amount > 0:
			draw_line(line_1_end, line_2_end, Color.WHITE, -1)
			draw_line(rect_end_1, rect_end_1 + Vector2(1, 26) * drawing_line_2_amount, Color.WHITE, -1)
			draw_line(rect_end_2, rect_end_2 + Vector2(-33, 0) * drawing_line_2_amount, Color.WHITE, -1)
		

		coords_label.visible_ratio = drawing_line_2_amount
		coords_label.position = line_1_end + Vector2(0, 2)
		coords_label.size.x = WIDTH

		amplitude_label.visible_ratio = drawing_line_2_amount
		amplitude_label.position = line_1_end + Vector2(0, 2 + LINE_SPACING)
		
		
		num_objects_label.position = line_1_end + Vector2(0, 2 + LINE_SPACING * 2)
		num_objects_label.visible_ratio = drawing_line_2_amount	
		
		num_people_label.position = line_1_end + Vector2(0, 2 + LINE_SPACING * 3)
		num_people_label.visible_ratio = drawing_line_2_amount
		
		people_class_label.position = line_1_end + Vector2(0, 2 + LINE_SPACING * 4)
		people_class_label.visible_ratio = drawing_line_2_amount
		
		door_class_label.position = line_1_end + Vector2(0, 2 + LINE_SPACING * 5)
		door_class_label.visible_ratio = drawing_line_2_amount
		
		bookmark_label.position = line_1_end + Vector2(0, 0 - LINE_SPACING)
		bookmark_label.visible_ratio = drawing_line_2_amount
		bookmark_sprite.position = line_1_end + Vector2(2, 1)
		bookmark_label.visible = PersistentData.bookmarks.has(room.coords) and bookmark_label.text.strip_edges() != coords_label.text
		#bookmark_sprite.visible = PersistentData.bookmarks.has(room.coords) and drawing_line_2_amount > 0
