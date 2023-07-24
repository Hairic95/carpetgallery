extends RefCounted

class_name ObjectFx

var object: BaseObject2D
var rng = BetterRng.new()

func _init(object: BaseObject2D):
	self.object = object
	rng.randomize()


func flash(b: bool):
	object.sprite.get_material().set_shader_parameter("flash", b)

func squish(time:float=0.25, amount=0.3, frequency = 70.0):
	var squish_tween = object.create_tween()

	var dir = sign(rng.randf() - 0.5)

	var squish_func = func(time: float, amount: float, frequency: float, duration: float):
		var realtime = time * duration
		var t = sin(realtime * frequency * dir)
#		print(t)
		object.flip.scale.x = 1 - t * amount * time
		object.flip.scale.y = 1 + t * amount * time
	squish_tween.tween_method(squish_func.bind(amount, frequency, time), 1.0, 0.0, time)

func hit_effect():
	squish()
	flash(true)
	await object.get_tree().create_timer(0.2)
	flash(false)
