extends SubViewportContainer

class_name GameScreen

var pixel_perfect_scaling_enabled := true
	#set(value):
		#Config.pixel_perfect_mode = value
		##pixel_perfect_scaling_enabled = value
		#update_viewport()
	#get:
		#return Config.pixel_perfect_mode

@onready var viewport_size := Vector2i(
			ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"),
		)

@export var update_list: Array[Control] = []
@export var non_pixel_perfect_texture_rect: TextureRect

@export var confine_mouse = false

var sub_viewport: SubViewport

func _ready():
	for child in get_children():
		if child is SubViewport:
			sub_viewport = child
			break

	stretch = true
	sub_viewport.size_2d_override_stretch = true
	get_viewport().size_changed.connect(update_viewport)
	Display.window_mode_changed.connect(update_viewport, CONNECT_DEFERRED)
	update_viewport.call_deferred()


#func _input(event):
	## fix by ArdaE https://github.com/godotengine/godot/issues/17326#issuecomment-431186323
	#for child: SubViewport in get_children():
		#if event is InputEventMouse:
			#var mouseEvent = event.duplicate()
			#mouseEvent.position = get_global_transform_with_canvas().affine_inverse() * event.position
			#child.push_input(mouseEvent)

func _process(delta: float) -> void:
	if confine_mouse and Display.focused:
		var mouse_pos = get_tree().root.get_mouse_position()
		var gpos = global_position
		var s = size
		var end = gpos + s
		if mouse_pos.x < gpos.x or mouse_pos.x > end.x or mouse_pos.y < gpos.y or mouse_pos.y > end.y:
			Input.warp_mouse(Vector2(clampf(mouse_pos.x, global_position.x, global_position.x + size.x), clampf(mouse_pos.y, global_position.y, global_position.y + size.y)))
			

func update_viewport():
	#hide()
	await RenderingServer.frame_post_draw

	var window_size: Vector2i = DisplayServer.window_get_size()
	
	var max_width_scale: int = window_size.x / viewport_size.x
	var max_height_scale: int = window_size.y / viewport_size.y
	#sub_viewport.set_deferred("size", viewport_size)
	sub_viewport.size_2d_override = viewport_size
	var viewport_pixel_scale : int = min(max_width_scale, max_height_scale)
	if pixel_perfect_scaling_enabled:
		size = viewport_size * viewport_pixel_scale
		if non_pixel_perfect_texture_rect:
			non_pixel_perfect_texture_rect.hide()
			modulate.a = 1.0
	else:
		var size_1 = Vector2(window_size.x, window_size.x * 0.5625)
		var size_2 = Vector2(window_size.y * 1.7777777777777778, window_size.y)
		if size_1.x > window_size.x or size_1.y > window_size.y:
			size = size_2
		else:
			size = size_1
		if non_pixel_perfect_texture_rect:
			non_pixel_perfect_texture_rect.show()
			var tex := sub_viewport.get_texture()
			non_pixel_perfect_texture_rect.texture = tex
			modulate.a = 0.0
			#hide()

		#size = window_size
	stretch = true
	stretch_shrink = viewport_pixel_scale
	position = window_size / 2 - Vector2i(size) / 2
	for control in update_list:
		control.position = position
		control.size = size
		pass

	if non_pixel_perfect_texture_rect:
		non_pixel_perfect_texture_rect.set("global_position", global_position)
		non_pixel_perfect_texture_rect.set("size", size)

	DisplayServer.window_set_min_size(viewport_size)
	#await RenderingServer.frame_post_draw
	#show()
