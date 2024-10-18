extends Game

func setup_level(level: Variant) -> void:
	level.exit_requested.connect(queue_scene_change.bind("MainMenu"))
