extends Area2D

class_name MapExit

@export var map: String
@export var entrance: String

@onready var shape = $CollisionShape2D
