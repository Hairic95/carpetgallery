extends Resource

class_name ColorGradient

@export var color_1: Color
@export var color_2: Color
@export var color_3: Color
@export var color_4: Color
@export var highlight_1: Color
@export var highlight_2: Color
@export var highlight_3: Color

func generate_material() -> ShaderMaterial:
	var material = ShaderMaterial.new()
	material.shader = preload("res://screen_palette.gdshader")
	material.set_shader_parameter("col_1", color_1)
	material.set_shader_parameter("col_2", color_2)
	material.set_shader_parameter("col_3", color_3)
	material.set_shader_parameter("col_4", color_4)
	material.set_shader_parameter("col_highlight", highlight_1)
	material.set_shader_parameter("col_highlight2", highlight_2)
	material.set_shader_parameter("col_highlight3", highlight_3)
	return material
