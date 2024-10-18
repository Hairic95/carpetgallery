extends RefCounted

class_name VisitedRoomMemory

signal updated

const HAS_DIALOGUE = 1 << 0
const HAS_MUSIC = 1 << 1
const HAS_DOOR = 1 << 2

var most_used_color: ColorGradient
var coords: Vector3i
var amplitude: float
var num_objects: int
var num_people: int
var bools: int = 0
var image: Image
var image_data: Array

static func from_room(room: RandomRoom):
	var desc = VisitedRoomMemory.new()
	desc.most_used_color = room.most_used_color_scheme
	desc.coords = room.room_coords
	desc.amplitude = room.amplitude
	desc.num_objects = room.num_total_objects
	desc.num_people = room.num_total_people
	
	if room.has_dialogue:
		desc.bools |= HAS_DIALOGUE
	if room.music_stream != null:
		desc.bools |= HAS_MUSIC
	if room.has_door:
		desc.bools |= HAS_DOOR
	
	
	return desc

func has_objects():
	return num_objects > 0

func has_dialogue():
	return bools & HAS_DIALOGUE != 0

func has_music():
	return bools & HAS_MUSIC != 0

func has_door():
	return bools & HAS_DOOR != 0
	

func get_save_data() -> Array:
	var arr = [
		coords,
		most_used_color.to_save_dict(),
		amplitude,
		num_objects,
		num_people,
		bools,
		image_data
	]
	
	return arr

func get_image_data(image: Image):
	
	if image == null:
		return []

	var colors = []
	
	var finished = false
	var num_allowed_colors = 255
	
	var height := image.get_height()
	var width := image.get_width()
	
	for y in range(height):
		for x in range(width):
			var color: Color = image.get_pixel(x, y)
			var new = true
			for other in colors:
				if color.is_equal_approx(other):
					color = other
					new = false
					break
			if new:
				colors.append(color)
			if colors.size() >= num_allowed_colors:
				finished = true
			if finished:
				break
		if finished:
			break

	var indices = {
	}

	for i in range(colors.size()):
		indices[colors[i]] = i

	var byte_array = PackedByteArray()
	byte_array.resize((width * height) / 2)

	for y in range(height):
		for x in range(0, width, 2):
			var color1 = image.get_pixel(x, y)
			var color2 = image.get_pixel(x+1, y)
			var offset = (y * width/2) + (x/2)
			var cs = 0
			
			if color1 in indices:
				cs |= (indices[color1] << 4)
			
			if color2 in indices:
				cs |= indices[color2]
			
			byte_array.encode_u8(offset, cs)
	return [
		colors,
		byte_array.compress(FileAccess.COMPRESSION_GZIP),
	]

func load_image_data(data: Array) -> Image:
	if data.is_empty():
		return null
	var colors: Array = data[0]
	var image = Image.create_empty(26, 18, false, Image.FORMAT_RGB8)
	image.decompress()
	#var offset = 0
	var width = image.get_width()
	var height = image.get_height()
	var bytes: PackedByteArray = data[1].decompress(width * height, FileAccess.COMPRESSION_GZIP)
	for y in height:
		for x in range(0, width, 2):
			var offset = (y * width/2) + (x/2)
			var cs := bytes.decode_u8(offset)
			var color1 : Color = colors[cs >> 4]
			var color2 : Color = colors[cs & 0b00001111]
			#var color1: Color = colors[bytes.decode_u8(offset)]
			#var color2: Color = colors[bytes.decode_u8(offset+1)]
			image.set_pixel(x, y, color1)
			image.set_pixel(x+1, y, color2)
		await GlobalState.get_tree().process_frame
			#offset += 1
	return image

static func from_save_data(data: Array):
	var memory = VisitedRoomMemory.new()
	memory.load_save_data(data)
	return memory

func set_image(image: Image):
	image.convert(Image.FORMAT_RGBA8)
	image_data = get_image_data(image)
	self.image = image
	#image.save_png("user://test.png")
	#self.image = load_image_data(image_data)
	#self.image.save_png("user://test2.png")
	updated.emit()

func load_save_data(data: Array):
	coords.x = data[0].x
	coords.y = data[0].y
	coords.z = data[0].z
	most_used_color = ColorGradient.from_save_dict(data[1]) 
	amplitude = data[2]
	num_objects = data[3]
	num_people = data[4]
	bools = data[5]
	if data.get(6) != null:
		#image = Image.create_from_data(30,22, false, Image.FORMAT_RGBA8, image_data)
		image = await load_image_data(data[6])
		image_data = get_image_data(image)
		updated.emit()
	#print(JSON.stringify(data))
