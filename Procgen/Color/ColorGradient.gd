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

func to_dict():
	return {
		"1": color_1.to_html(false),
		"2": color_2.to_html(false),
		"3": color_3.to_html(false),
		"4": color_4.to_html(false),
		"h1": highlight_1.to_html(false),
		"h2": highlight_2.to_html(false),
		"h3": highlight_3.to_html(false),
	}

func to_save_dict():
	return {
		"1": color_1.to_html(false),
		"2": color_2.to_html(false),
		"3": color_3.to_html(false),
		"4": color_4.to_html(false),
	}

static func from_dict(dict: Dictionary):
	var grad = ColorGradient.new()
	grad.color_1 = Color(dict["1"])
	grad.color_2 = Color(dict["2"])
	grad.color_3 = Color(dict["3"])
	grad.color_4 = Color(dict["4"])
	grad.highlight_1 = Color(dict.h1)
	grad.highlight_2 = Color(dict.h2)
	grad.highlight_3 = Color(dict.h3)
	return grad

static func from_save_dict(dict: Dictionary):
	var grad = ColorGradient.new()
	grad.color_1 = Color(dict["1"])
	grad.color_2 = Color(dict["2"])
	grad.color_3 = Color(dict["3"])
	grad.color_4 = Color(dict["4"])

	return grad
