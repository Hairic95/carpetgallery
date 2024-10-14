extends Node

class_name File

static func walk_path(path, absolute=false, filter_file_type="") -> Array:
	var files: Array[String] = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file if !absolute else dir.get_current_dir().path_join(file))
	return files.filter(func(f: String): return f.ends_with(filter_file_type))

static func get_resources_in_dir(path, file_type="") -> Array:
	var arr = []
	for file_path in walk_path(path, true, file_type):
		arr.append(ResourceLoader.load(file_path))
	return arr
