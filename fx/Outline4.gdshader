shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_test_disabled, specular_disabled;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest, repeat_disable;

uniform bool is_inverted = false;
uniform float depth_multiplier = 1.5;
uniform float transparency = 1.0;
uniform vec4 outline_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool use_background_color = true;

uniform float line_width = 1.;

float get_linear_depth(vec2 screen_uv, mat4 inv_proj_matrix, float depth) {
	vec4 view = inv_proj_matrix * vec4(screen_uv * 2. - 1., depth, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {

	vec2 pixel_width = vec2(line_width/VIEWPORT_SIZE.x, 0.);
	vec2 pixel_height = vec2(0., line_width/VIEWPORT_SIZE.y);

	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	float depth_neighbor1 = texture(DEPTH_TEXTURE, SCREEN_UV + pixel_width).r;
	float depth_neighbor2 = texture(DEPTH_TEXTURE, SCREEN_UV - pixel_width).r;
	float depth_neighbor3 = texture(DEPTH_TEXTURE, SCREEN_UV + pixel_height).r;
	float depth_neighbor4 = texture(DEPTH_TEXTURE, SCREEN_UV - pixel_height).r;

	float linear_depth = get_linear_depth(SCREEN_UV, INV_PROJECTION_MATRIX, depth); //center
	float linear_depth_neighbor1 = get_linear_depth(SCREEN_UV + pixel_width, INV_PROJECTION_MATRIX, depth_neighbor1); //right
	float linear_depth_neighbor2 = get_linear_depth(SCREEN_UV - pixel_width, INV_PROJECTION_MATRIX, depth_neighbor2); //left
	float linear_depth_neighbor3 = get_linear_depth(SCREEN_UV + pixel_height, INV_PROJECTION_MATRIX, depth_neighbor3); //below
	float linear_depth_neighbor4 = get_linear_depth(SCREEN_UV - pixel_height, INV_PROJECTION_MATRIX, depth_neighbor4); //above

	float diff_neighbor1 = linear_depth - linear_depth_neighbor1; // if negative, right pixel is more distant than center
	float diff_neighbor2 = linear_depth - linear_depth_neighbor2; // if negative, left pixel is more distant than center
	float diff_neighbor3 = linear_depth - linear_depth_neighbor3; // if negative, below pixel is more distant than center
	float diff_neighbor4 = linear_depth - linear_depth_neighbor4; // if negative, above pixel is more distant than center

	float xdiff = diff_neighbor1 + diff_neighbor2;
	float ydiff = diff_neighbor3 + diff_neighbor4;

	float diff = max(xdiff, ydiff);

	float cascades = 2.;
	float line_strength = floor(clamp(diff * depth_multiplier, 0., 1.) * cascades) / cascades * transparency;

	vec3 base_albedo = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	if (use_background_color) {
		base_albedo = background_color.rgb;
	}

	//Use if blend mode is mix
	ALBEDO = mix(base_albedo, outline_color.rgb, line_strength * outline_color.a);


}