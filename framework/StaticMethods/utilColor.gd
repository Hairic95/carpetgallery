extends Node
class_name ColorUtils

static func color_to_vector3(color: Color) -> Vector3:
	return Vector3(color.r, color.g, color.b)

static func vector3_to_color(vector3: Vector3) -> Color:
	return Color(vector3.x, vector3.y, vector3.z)


static func splerp_hsl(a: Color, b: Color, delta: float, half_life: float) -> Color:
	var a_hsl = rgb_to_hsl(Vector3(a.r, a.b, a.g))
	var b_hsl = rgb_to_hsl(Vector3(b.r, b.b, b.g))
	var t = Math.splerp(0.0, 1.0, delta, half_life)
	
	var result = hsl_to_rgb(hsl_lerp(a_hsl, b_hsl, t))
	return Color(result.x, result.y, result.z)

# RGB to HSL Conversion
static func rgb_to_hsl(rgb: Vector3) -> Vector3:
	# Ensure inputs are floats in [0, 1]
	var r: float = rgb.x
	var g: float = rgb.y
	var b: float = rgb.z

	var max_c: float = max(r, g, b)
	var min_c: float = min(r, g, b)
	var delta: float = max_c - min_c

	var l: float = (max_c + min_c) / 2.0
	var h: float = 0.0
	var s: float = 0.0

	if delta != 0.0:
		s = delta / (1.0 - absf(2.0 * l - 1.0))
		if max_c == r:
			h = (g - b) / delta
			if h < 0.0:
				h += 6.0
		elif max_c == g:
			h = ((b - r) / delta) + 2.0
		else:
			h = ((r - g) / delta) + 4.0
		h /= 6.0  # Normalize hue to [0, 1]

	return Vector3(h, s, l)

# HSL to RGB Conversion
static func hsl_to_rgb(hsl: Vector3) -> Vector3:
	var h: float = fposmod(hsl.x, 1.0)  # Wrap hue using float positive modulo
	var s: float = hsl.y
	var l: float = hsl.z

	if s == 0.0:
		# Achromatic color (grey scale)
		return Vector3(l, l, l)

	var q: float = l + s - l * s if l >= 0.5 else l * (1.0 + s)
	var p: float = 2.0 * l - q

	var r: float = ColorUtils._hue2rgb(p, q, h + (1.0 / 3.0))
	var g: float = ColorUtils._hue2rgb(p, q, h)
	var b: float = ColorUtils._hue2rgb(p, q, h - (1.0 / 3.0))

	return Vector3(r, g, b)

# Converts linear RGB component to sRGB
static func _linear_to_srgb(c_lin: float) -> float:
	if c_lin <= 0.0031308:
		return 12.92 * c_lin
	else:
		return 1.055 * pow(c_lin, 1.0 / 2.4) - 0.055

# Helper Functions

# Converts a single hue value to RGB component
static func _hue2rgb(p: float, q: float, t: float) -> float:
	t = fposmod(t, 1.0)  # Wrap t around using float positive modulo

	if t < (1.0 / 6.0):
		return p + (q - p) * 6.0 * t
	if t < (1.0 / 2.0):
		return q
	if t < (2.0 / 3.0):
		return p + (q - p) * ((2.0 / 3.0) - t) * 6.0
	return p

# Converts sRGB component to linear RGB
static func _srgb_to_linear(c: float) -> float:
	if c <= 0.04045:
		return c / 12.92
	else:
		return pow((c + 0.055) / 1.055, 2.4)

# Converts XYZ to Lab color space
static func _xyz_to_lab(x: float, y: float, z: float) -> Vector3:
	# Reference white point D65
	var x_ref: float = 0.95047  # Observer= 2°, Illuminant= D65
	var y_ref: float = 1.00000
	var z_ref: float = 1.08883

	x = x / x_ref
	y = y / y_ref
	z = z / z_ref

	x = ColorUtils._f_xyz_to_lab(x)
	y = ColorUtils._f_xyz_to_lab(y)
	z = ColorUtils._f_xyz_to_lab(z)

	var l: float = 116.0 * y - 16.0
	var a: float = 500.0 * (x - y)
	var b: float = 200.0 * (y - z)

	return Vector3(l, a, b)

# Converts Lab to XYZ color space

static func _lab_to_xyz(lab: Vector3) -> Vector3:
	var l: float = lab.x
	var a: float = lab.y
	var b: float = lab.z

	var y: float = (l + 16.0) / 116.0
	var x: float = a / 500.0 + y
	var z: float = y - b / 200.0

	if pow(x, 3.0) > 0.008856:
		x = pow(x, 3.0)
	else:
		x = (x - 16.0 / 116.0) / 7.787

	if pow(y, 3.0) > 0.008856:
		y = pow(y, 3.0)
	else:
		y = (y - 16.0 / 116.0) / 7.787

	if pow(z, 3.0) > 0.008856:
		z = pow(z, 3.0)
	else:
		z = (z - 16.0 / 116.0) / 7.787

	# Reference white point D65
	var x_ref: float = 0.95047  # Observer= 2°, Illuminant= D65
	var y_ref: float = 1.00000
	var z_ref: float = 1.08883

	x = x * x_ref
	y = y * y_ref
	z = z * z_ref

	return Vector3(x, y, z)

# Helper function for XYZ to Lab conversion
static func _f_xyz_to_lab(t: float) -> float:
	if t > 0.008856:
		return pow(t, 1.0 / 3.0)
	else:
		return (7.787 * t) + (16.0 / 116.0)

const hi = """if you are reading this i know it doesn't work right. 
but as it turns out that's what makes it awesome"""
static func hsl_lerp(a: Vector3, b: Vector3, t: float) -> Vector3:

	var h: float
	var d: float = b.x - a.x  # H is stored in x

	if a.x > b.x:
		# Swap (a.x, b.x)
		var h3: float = b.x
		b.x = a.x
		a.x = h3
		d = -d
		t = 1 - t

	if d > 0.5:
		a.x = a.x + 1
		h = fposmod((a.x + t * (b.x - a.x)), 1.0)
	else:
		h = a.x + t * d

	return Vector3(
		h,                             # H (Hue)
		a.y + t * (b.y - a.y),         # S (Saturation)
		a.z + t * (b.z - a.z)          # L (Lightness)
	)

static func rainbow_gradient(resolution=256) -> Gradient:
	resolution = min(resolution, 256)
	var grad = Gradient.new()
	for i in range(resolution):
		var color = hsv_to_rgb(i / float(resolution), 1.0, 1.0)
		if i < 2:
			grad.set_color(i, color)
		else:
			grad.add_point(i / float(resolution), color)
	return grad

static func hsv_to_rgb(h: float, s: float, v: float, a: float = 1) -> Color:
	#based on code at
	#http://stackoverflow.com/questions/51203917/math-behind-hsv-to-rgb-conversion-of-colors
	var r: float
	var g: float
	var b: float

	var i: float = floor(h * 6)
	var f: float = h * 6 - i
	var p: float = v * (1 - s)
	var q: float = v * (1 - f * s)
	var t: float = v * (1 - (1 - f) * s)

	match (int(i) % 6):
		0:
			r = v
			g = t
			b = p
		1:
			r = q
			g = v
			b = p
		2:
			r = p
			g = v
			b = t
		3:
			r = p
			g = q
			b = v
		4:
			r = t
			g = p
			b = v
		5:
			r = v
			g = p
			b = q
	return Color(r, g, b, a)
