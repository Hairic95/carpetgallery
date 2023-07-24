shader_type canvas_item;

uniform bool flash = false;
const vec4 color = vec4(1.,1.,1., 1.0);

void fragment() {
	if (flash) {
		COLOR.rgb = color.rgb;
	}

}