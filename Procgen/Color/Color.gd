extends Node

class_name ColorGen

const MIN_LUMINANCE = 0.0125

static func generate_gradient(rng: BetterRng, brightness=NAN) -> ColorGradient:
		var grad = ColorGradient.new()
		var min_luminance = MIN_LUMINANCE if rng.percent(50) else 0.0
		var low := 0.0
		if is_nan(brightness):
			low = clampf(rng.randfn(-0.5, 0.25), min_luminance, 1.0)
		else:
			low = clampf(rng.randfn(brightness, 0.1), min_luminance, 1.0)
		
		var high := clampf(rng.randfn(0.5, 0.1), low, 1.0)
		var start := random_color(rng, low)
		var end = random_color(rng, high)

		var start_vec := ColorUtils.color_to_vector3(start)
		start_vec = ColorUtils.rgb_to_hsl(start_vec)
		var end_vec := ColorUtils.color_to_vector3(end)
		end_vec = ColorUtils.rgb_to_hsl(end_vec)
		
		var mid1 = ColorUtils.vector3_to_color(ColorUtils.hsl_to_rgb(ColorUtils.hsl_lerp(start_vec, end_vec, 1.0/3.0)))
		var mid2 = ColorUtils.vector3_to_color(ColorUtils.hsl_to_rgb(ColorUtils.hsl_lerp(start_vec, end_vec, 2.0/3.0)))
		
		grad.color_1 = start
		grad.color_2 = mid1
		grad.color_3 = mid2
		grad.color_4 = end
		grad.highlight_1 = random_highlight(rng)
		grad.highlight_2 = random_highlight(rng)
		grad.highlight_3 = random_highlight(rng)
		
		return grad

static func random_highlight(rng: BetterRng) -> Color:
	var luminance = clamp(rng.randfn(0.5, 0.1), 0.0, 1.0)
	return (random_color(rng, luminance))

static func random_color(rng: BetterRng, luminance: float=NAN) -> Color:
	var h = rng.randf_range(0.0, 1.0)
	var s = clamp(rng.randfn(0.9, 0.3), 0.0, 1.0)
	#var s = 1.0
	var l = luminance if !is_nan(luminance) else rng.randf_range(0.0, 1.0)
	var rgb = ColorUtils.hsl_to_rgb(Vector3(h, s, l))
	return Color(rgb.x, rgb.y, rgb.z)
