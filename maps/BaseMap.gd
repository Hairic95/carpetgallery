extends TileMap

class_name BaseMap

var entrances = {}

var world

func _ready():
	for child in get_children():
		if child is MapEntrance:
			entrances[child.name] = child
