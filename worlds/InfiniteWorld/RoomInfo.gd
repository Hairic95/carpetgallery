extends RefCounted

class_name RoomInfo
	
var coords: Vector3i

func _init(coords: Vector3i):
	self.coords = coords

func to_name() -> String:
	return coords_to_name(coords)

static func coords_to_name(coords: Vector3i) -> String:
	return "Room " + str(coords.x) + "_" + str(coords.y) + "_" + str(coords.z)
