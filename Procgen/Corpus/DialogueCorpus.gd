extends Resource

class_name DialogueCorpus

@export var name: String
@export_range(1, 2000, 1.00000000000001) var weight: float = 1000
@export_multiline var dialogues: String

var _lines: PackedStringArray
var lines: PackedStringArray:
	get:
		if _lines.is_empty():
			_lines = dialogues.split("\n", false)
		return _lines
