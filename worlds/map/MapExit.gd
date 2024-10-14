@tool

extends Area2D

class_name MapExit

@export var map: String:
	set(s):
		map = s
		update_label()

@export var entrance: String:
	set(s):
		entrance = s
		update_label()

@export var map_color: Color:
	set(s):
		map_color = s
		update_label()
@export var entrance_color: Color:
	set(s):
		entrance_color = s
		update_label()

@onready var shape = $CollisionShape2D
@onready var editor_label = $EditorLabel


func _ready():
	editor_label.visible = Engine.is_editor_hint()
	update_label()

func update_label():
	var text = "[center]< [color=%s]%s[/color] >\n< [color=%s]%s[/color] >" % [map_color.to_html(), map, entrance_color.to_html(), entrance]
	if editor_label:
		#editor_label.clear()
		editor_label.text = text
