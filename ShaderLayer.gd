@tool
extends CanvasLayer

const COLOR_FADE_DURATION = 0.4

@onready var world: World = %Game.world
@onready var color_rect = $ColorRect


var col_1: Color = Color.BLACK:
	set(c):
		col_1 = c
		color_rect.material.set_shader_parameter("col_1", c)

var col_2: Color = Color.BLUE:
	set(c):
		col_2 = c
		color_rect.material.set_shader_parameter("col_2", c)

var col_3: Color = Color.GREEN:
	set(c):
		col_3 = c
		color_rect.material.set_shader_parameter("col_3", c)

var col_4: Color = Color.WHITE:
	set(c):
		col_4 = c
		color_rect.material.set_shader_parameter("col_4", c)

var col_highlight: Color = Color.RED:
	set(c):
		col_highlight = c
		color_rect.material.set_shader_parameter("col_highlight", c)


func _ready():
	if Engine.is_editor_hint():
		return
	world.started_map_transition.connect(on_active_map_changed)
	on_active_map_changed(world.active_map, world.active_map)

func on_active_map_changed(old: BaseMap, new: BaseMap):
	if old == new:
		col_1 = old.map_colors.col_1
		col_2 = old.map_colors.col_2
		col_3 = old.map_colors.col_3
		col_4 = old.map_colors.col_4
		col_highlight = old.map_colors.col_highlight
		return
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(fade_colors.bind(old, new), 0.0, 1.0, COLOR_FADE_DURATION)

func fade_colors(t: float, old_map: BaseMap, new_map: BaseMap):
	for col in ["col_1", "col_2", "col_3", "col_4"]:
		var old_c: Color = old_map.map_colors.get(col)
		var new_c: Color = new_map.map_colors.get(col)
		var fade_c = old_c.lerp(new_c, t)
		set(col, fade_c)
