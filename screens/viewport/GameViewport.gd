extends SubViewport

func take_screenshot() -> Texture2D:
	var dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).path_join("carpet gallery")
	if !DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)
	var texture = get_texture()
	var image = texture.get_image()
	#image.convert(Image.FORMAT_RGBA8)
	var tex = ImageTexture.create_from_image(image)
	image.resize(image.get_width() * Config.screenshot_pixel_size, image.get_height() * Config.screenshot_pixel_size, Image.INTERPOLATE_NEAREST)
	#image.resize(30, 22, Image.INTERPOLATE_NEAREST)
	if OS.get_name() == "Web":
		var buf = image.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buf, str(PersistentData.player_room_coords_2d) + ".png")
	else:
		image.save_png(dir.path_join(str(PersistentData.player_room_coords_2d) + ".png")) # TODO: 3d
	return tex
