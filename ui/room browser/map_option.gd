@tool

extends Node2D

@onready var label: Label = %Label

func _ready():
	label.text = name.capitalize().to_lower()
