@tool
extends Node2D

const BG_DRAW_PADDING = 16

var map:
	get:
		return get_parent()

var draw_pos = Vector2()
var draw_thread = Thread.new()

var prev_cells_rect = Rect2i()

signal thread_finished()

func _ready():
	if not map is TileMap:
		return
	if Engine.is_editor_hint():
		map.changed.connect(on_map_changed)
		on_map_changed()

func on_map_changed():
#	if draw_thread and draw_thread.is_started():
#		await thread_finished
#	draw_thread = Thread.new()
#	draw_thread.start(get_top_left_corner)
	get_top_left_corner()
	
func get_top_left_corner():
	var min_x = INF
	var min_y = INF
	for layer in map.get_layers_count():
		for cell in map.get_used_cells(layer):
			if cell.x < min_x:
				min_x = cell.x
			if cell.y < min_y:
				min_y = cell.y
	draw_pos = Vector2(min_x * map.tile_set.tile_size.x, min_y * map.tile_set.tile_size.y) - Vector2.ONE * BG_DRAW_PADDING / 2
#	on_thread_finished.call_deferred()
#
#func on_thread_finished():
#	draw_thread.wait_to_finish()
#	thread_finished.emit()

func _process(delta):
	if Engine.is_editor_hint():
		queue_redraw()

func _draw():
	if not map is TileMap:
		return
	if Engine.is_editor_hint():
		
		var cells_rect = map.get_used_rect()
		if prev_cells_rect != cells_rect:
			on_map_changed()
		prev_cells_rect = cells_rect
		var world_rect = cells_rect
		world_rect.size.x *= map.tile_set.tile_size.x
		world_rect.size.y *= map.tile_set.tile_size.y
		world_rect.size += Vector2i.ONE * BG_DRAW_PADDING
		world_rect.position = Vector2i(draw_pos)
		var col = Color.BLACK
		col.a = 0.9
		draw_rect(world_rect, col, true)
