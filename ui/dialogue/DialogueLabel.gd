extends "res://addons/dialogue_manager/dialogue_label.gd"

@export var pause_multiplier = 15

# Type out the next character(s)
func _type_next(delta: float, seconds_needed: float) -> void:
	if visible_characters == get_total_character_count():
		return

	if _last_mutation_index != visible_characters:
		_last_mutation_index = visible_characters
		_mutate_inline_mutations(visible_characters)

	var additional_waiting_seconds: float = _get_pause(visible_characters)

	# Pause on characters like "."
	if visible_characters > 0 and get_parsed_text()[visible_characters - 1] in pause_at_characters.split():
		if len(get_parsed_text()) >= visible_characters:
			if get_parsed_text()[visible_characters] != get_parsed_text()[visible_characters - 1]:
				additional_waiting_seconds += seconds_per_step * pause_multiplier

	# Pause at literal [wait] directives
	if _last_wait_index != visible_characters and additional_waiting_seconds > 0:
		_last_wait_index = visible_characters
		_waiting_seconds += additional_waiting_seconds
		paused_typing.emit(_get_pause(visible_characters))
	else:
		visible_characters += 1
		if visible_characters <= get_total_character_count():
			spoke.emit(get_parsed_text()[visible_characters - 1], visible_characters - 1, _get_speed(visible_characters))
		# See if there's time to type out some more in this frame
		seconds_needed += seconds_per_step * (1.0 / _get_speed(visible_characters))
		if seconds_needed > delta:
			_waiting_seconds += seconds_needed
		else:
			_type_next(delta, seconds_needed)

func _unhandled_input(event: InputEvent) -> void:
	if self.is_typing and visible_ratio < 1 and visible_characters > 0 and event.is_action_pressed(skip_action):
		get_viewport().set_input_as_handled()

		# Run any inline mutations that haven't been run yet
		for i in range(visible_characters, get_total_character_count()):
			_mutate_inline_mutations(i)
		visible_characters = get_total_character_count()
		self.is_typing = false
		finished_typing.emit()
