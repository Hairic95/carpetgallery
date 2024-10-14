extends Node

class_name Utils

const cardinal_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const diagonal_dirs: Array[Vector2i] = [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]
const all_dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, -1), Vector2i(-1, 1)]

static func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.free()
		
static func clear_children_deferred(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()



static func enum_string(value: int, enum_) -> String:
	return enum_.keys()[value].capitalize().to_lower()

static func sort_node_array_by_distance(arr: Array, from:Vector2):
	arr.sort_custom(func(a, b): return \
		from.distance_squared_to(a.global_position) < \
		from.distance_squared_to(b.global_position))

static func node_distance(node1: Node, node2: Node) -> float:
	return node1.global_position.distance_to(node2.global_position)

static func sort_array_by_distance(arr: Array[Vector2], from: Vector2):
	arr.sort_custom(func(a, b): return \
		from.distance_squared_to(a) < \
		from.distance_squared_to(b))

static func get_first_dict_key_below_number(dict: Dictionary, num: int):
	var highest = -INF
	for key in dict:
		if key > num:
			return highest
		if key > highest:
			highest = key
	return highest

static func dict_max(dict: Dictionary):
	var keys = dict.keys()
	var max = -INF
	var max_key = null
	for key in keys:
		var value = dict[key]
		if value > max:
			max = value
			max_key = key
	return max_key

static func load_resource_threaded(resource_path: StringName, await_callback: Callable, progress_callback:Callable = func(progress: Array) -> void: return) -> Resource:
	#print(resource_path) 

	var progress: Array[int] = [0]
	var resource: Resource

	ResourceLoader.load_threaded_request(resource_path)
	
	while true:
		var status = ResourceLoader.load_threaded_get_status(resource_path, progress)
		var signal_ = await_callback.call()
		if signal_ == null:
			break
		await signal_
		if is_instance_valid(progress_callback):
			progress_callback.call(progress)
		match status:
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
				resource = ResourceLoader.load_threaded_get(resource_path)
				break
			ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
				continue
	return resource

static func tree_set_all_process(p_node: Node, p_active: bool, p_self_too: bool = false) -> void:
	if not p_node:
		push_error("p_node is empty")
		return
	var p = p_node.is_processing()
	var pp = p_node.is_physics_processing()
	p_node.propagate_call("set_process", [p_active])
	p_node.propagate_call("set_physics_process", [p_active])
	if not p_self_too:
		p_node.set_process(p)
		p_node.set_physics_process(pp)

static func get_angle_to_target(node: Node2D, target_position: Vector2) -> float:
	var target = node.get_angle_to(target_position)
	target = target if abs(target) < PI else target + TAU * -sign(target)
	return target
	
static func comma_sep(number: int) -> String:
	var string = str(number)
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	return res

static func bools_to_axis(negative: bool, positive: bool) -> float:
	return (-1.0 if negative else 0) + (1.0 if positive else 0)

static func bools_to_vector2(left: bool, right: bool, up: bool, down: bool) -> Vector2:
	return Vector2(bools_to_axis(left, right), bools_to_axis(up, down))
	
static func bools_to_vector2i(left: bool, right: bool, up: bool, down: bool) -> Vector2i: 
	return Vector2i(bools_to_axis(left, right), bools_to_axis(up, down))
	
static func remove_duplicates(array: Array) -> Array:
	var seen = []
	var new = []
	for i in array.size():
		var value = array[i]
		if value in seen:
			continue
		seen.append(value)
		new.append(value)
	return new

static func queue_free_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
		
static func free_children(node: Node) -> void:
	for child in node.get_children():
		child.free()

static func dicts_to_percents(dict: Dictionary) -> Dictionary:
	var new_dict = {}
	var sum = 0
	for value in dict.values():
		sum += value
	var ratio = 100.0 / sum
	for key in dict:
		new_dict[key] = dict[key] * ratio
	return new_dict

static func print_dict(dict: Dictionary):
	for key in dict:
		print(str(key) + ": " + str(dict[key]))
