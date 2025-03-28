extends InteractableComponent

class_name RandomFastTravelDoorComponent

const MAX_DIST = 25

var offs: Vector2

func setup():
	offs = object.rng.random_vec(false) * MAX_DIST
	#print(offs)

func be_interacted_with(object: NetworkBody):
	var map_traversal_component: MapTraversalComponent = object.get_component(MapTraversalComponent)
	var coords = Vector3i(object.map_coordinates.x, object.map_coordinates.y, 0) + Vector3i(offs.x, offs.y, 0)
	map_traversal_component.fast_travel_initiated.emit(coords, true)
