@tool

extends Resource

class_name ColorResource

#@export_tool_button("Generate Gradients", "Callable")
#var _gen_gradients = generate_gradients

@export var gradients: Array[ColorGradient]

@export var highlights: Array[Color]

#func generate_gradients():
	#gradients.clear()
	#highlights.clear()
	#var rng := BetterRng.new()
	#for i in range(1000):
		#gradients.append(generate_gradient(rng))
#
		#var luminance = clamp(rng.randfn(0.5, 0.1), 0.0, 1.0)
		#highlights.append(random_color(rng, luminance))
