extends GameScene

class_name Game

@export_file() var start: String

@onready var game_world_layer: CanvasLayer = %GameWorldLayer

func load_level(level_path: StringName) -> Variant:
	print("loading level: " + level_path)
	var progress = [0]
	var level: Variant
	ResourceLoader.load_threaded_request(level_path)
	while true:
		var status = ResourceLoader.load_threaded_get_status(level_path, progress)
		match status:
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				level = ResourceLoader.load_threaded_get(level_path).instantiate()
				add_level.call_deferred(level)
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
				continue
		await get_tree().process_frame
	return level

func add_level(level: Variant):
	game_world_layer.add_child(level)

func _ready() -> void:
	pass

func load_scene_data(scene_data: Dictionary):
	var level = start
	if scene_data.has("level"):
		level = (scene_data.level)

	var startup_level = await load_level(level)
	assert(startup_level != null)
	setup_level(startup_level)

func setup_level(level: Variant) -> void:
	pass

func get_level():
	return game_world_layer.get_child(0)
