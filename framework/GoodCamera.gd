extends Camera2D

class_name GoodCamera

@export var default_screenshake_amount := 2.0
@export var default_screenshake_time := 1.0
#@onready var noise = FastNoiseLite.new()
#var noise_y = 0

#var shake_tween
var shake_amount = 0
var rng = BetterRng.new()

var offsets = []
var tweens = []

class Offset extends Object:
	var value:
		get:
			if !random:
				return dir * amount
			else:
				return amount * rng.random_vec()
	var rng: BetterRng
	var dir = Vector2()
	var amount: float = 0
	var random = false
	
func _ready():
	rng.randomize()


func bump(dir:=Vector2(), amount:=default_screenshake_amount, time:=default_screenshake_time):
#	if amount < shake_amount:
#		return
#	if shake_tween is Tween:

		
	var shake_tween = create_tween()
	shake_tween.set_parallel(false)
	shake_tween.set_trans(Tween.TRANS_CIRC)
	shake_tween.set_ease(Tween.EASE_OUT)
	var offs = Offset.new()
	offs.dir = dir
	offs.rng = rng
	
	if dir == Vector2():
		offs.random = true
	
	offsets.append(offs)
	
	shake_tween.tween_property(offs, "amount", amount, 0.0025)
	shake_tween.set_trans(Tween.TRANS_ELASTIC)
	shake_tween.set_ease(Tween.EASE_OUT)
	
#	shake_tween.set_parallel(true)
#	shake_tween.tween_property(self, "shake_amount", 0, time)
	shake_tween.tween_property(offs, "amount", 0.0, time)
#	tweens.append(shake_tween)
	await shake_tween.finished 
	shake_tween.kill()
#	offsets.erase(offs)
	offsets.erase(offs)
	offs.free()


func _process(delta):
	offset = Vector2()
	var offset_values = []
	for offs in offsets:
		offset += offs.value
		offset_values.append(offs.value)
