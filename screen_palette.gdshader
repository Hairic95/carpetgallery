shader_type canvas_item;

uniform vec4 col_1 : source_color;
uniform vec4 col_2 : source_color;
uniform vec4 col_3 : source_color;
uniform vec4 col_4 : source_color;
uniform vec4 col_highlight : source_color;
uniform vec4 col_highlight2 : source_color;
uniform vec4 col_highlight3 : source_color;

uniform int tile = 1;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

const vec4 OLD_HIGHLIGHT = vec4(1.0, 0.0, 0.0, 1.0);
const vec4 OLD_HIGHLIGHT2 = vec4(0.0, 1.0, 0.0, 1.0);
const vec4 OLD_HIGHLIGHT3 = vec4(0.0, 0.0, 1.0, 1.0);
const float COLOR_DISTANCE = 0.01;

bool same_color(vec4 color1, vec4 color2) {
	return distance(color1, color2) < COLOR_DISTANCE;
}

vec4 replace_color(vec4 color) {
	//color.a = step(0.0, color.a);
	if (same_color(color, OLD_HIGHLIGHT))
		return col_highlight;
	if (same_color(color, OLD_HIGHLIGHT2))
		return col_highlight2;
	if (same_color(color, OLD_HIGHLIGHT3))
		return col_highlight3;

	float v = (color.r + color.g + color.b) / 3.0;
	if (v > 0.9)
		return col_4;
	else if (v > 0.5)
		return col_3;
	else if (v > 0.2)
		return col_2;
	else
		return col_1;
}

void fragment() {
	COLOR.rgb = replace_color(texture(TEXTURE, UV * float(tile))).rgb;
}
