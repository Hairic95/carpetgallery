extends BaseComponent

class_name InteractComponent

const DISTANCE = 7


@onready var area = $Area2D
@onready var shape = $Area2D/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite

var overlapping = []

var selected = 0

func _ready():
	area.area_entered.connect(on_area_entered)
	area.area_exited.connect(on_area_exited)
	z_index = 1000
	update_sprite_parent.call_deferred()

func _physics_process(delta):
	var intent = get_component(CharacterIntentComponent)
	if intent:
		if intent.move_dir:
			area.position = intent.move_dir * DISTANCE
		if intent.interact:
			interact(get_selected_component())

func _process(delta: float) -> void:
	var component = get_selected_component()

	update_sprite_parent()
	sprite.hide()
	if component and component.object:
		var tex = component.get_interact_texture()
		# TODO: make the texture its own node
		sprite.global_position = (component.object.xy) + Vector2(0, -17)
		sprite.texture = tex
		sprite.z_index = 10
		sprite.show()

func update_sprite_parent():
	if !is_instance_valid(sprite):
		sprite = Sprite2D.new()
	var sprite_parent = sprite.get_parent()
	if sprite.get_parent() != object.map:
		if sprite.get_parent() != null:
			sprite.get_parent().remove_child.call_deferred(sprite)
		object.map.add_child.call_deferred(sprite)

func on_area_entered(area):
	overlapping.append(area)

func on_area_exited(area):
	overlapping.erase(area)

func interact(component: InteractableComponent):
	if component:
		component.be_interacted_with(object)
		body.reset_momentum()

func get_selected_component():
	var invalid = []
	for area in overlapping:
		if !is_instance_valid(area):
			invalid.append(area)
	for area in invalid:
		overlapping.erase(area)
	overlapping.sort_custom(func (a, b): return object.xy.distance_squared_to(a.global_position) < object.xy.distance_squared_to(b.global_position))
	if overlapping:
		return overlapping[0].get_parent()
	return null

func reset():
	await get_tree().physics_frame
	overlapping = area.get_overlapping_areas()
