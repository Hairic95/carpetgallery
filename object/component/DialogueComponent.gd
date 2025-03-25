extends InteractableComponent

class_name DialogueComponent

@export var dialogue_resource: DialogueResource
@export var starting_title = ""

func _ready():
	if dialogue_resource == null:
		dialogue_resource = DialogueResource.new()

func be_interacted_with(object: NetworkBody):
	if dialogue_resource:
		var dialogue_box_component: DialogueBoxComponent = object.get_component(DialogueBoxComponent)
		if dialogue_box_component:
			dialogue_box_component.start(dialogue_resource, starting_title, [])
		DialogueState.talking_to = self.object

func get_interact_texture():
	return preload("res://ui/talk.png")
