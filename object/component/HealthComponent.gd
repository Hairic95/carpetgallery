extends BaseComponent

class_name HealthComponent

signal health_zero()
signal damaged(amount)
signal healed(amount)

@export var max_health: int = 10

var health = max_health
var dead = false

func _ready():
	health_zero.connect(on_health_zero)

func adjust_health(amount):
	health += amount
	if health > max_health:
		health = max_health
	if health < 0:
		health = 0

func heal(amount):
	adjust_health(amount)
	healed.emit(amount)

func damage(amount):
	adjust_health(-amount)
	damaged.emit(amount)
	if health <= 0:
		health_zero.emit()
	object.fx.hit_effect()

func on_health_zero():
	object.change_state("Die")
	dead = true
