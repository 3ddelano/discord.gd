class_name SelectMenu
"""
Represents a Discord select menu.
"""

var custom_id: String setget set_custom_id, get_custom_id
var placeholder: String setget set_placeholder, get_placeholder
var options: Array setget set_options, get_options

var min_values = 1 setget set_min_values, get_min_values
var max_values = 1 setget set_max_values, get_max_values

var disabled: bool = false setget set_disabled, get_disabled

var type: int = 3


func set_custom_id(new_custom_id):
	Helpers.assert_length(new_custom_id, 100, 'custom_id of SelectMenu cannot be more than 100 characters.')
	custom_id = new_custom_id
	return self

func get_custom_id() -> String:
	return custom_id


func add_option(value: String, label: String, data: Dictionary = {}):
	assert(options.size() <= 25, 'options of SelectMenu cannot have more than 25 options')
	assert(Helpers.is_valid_str(value), 'value of SelectMenu option  must be a valid String')
	Helpers.assert_length(value, 100, 'value of SelectMenu option cannot be more than 100 characters')
	assert(Helpers.is_valid_str(label), 'SelectMenu option must have a label')
	Helpers.assert_length(label, 100, 'label of SelectMenu option cannot be more than 100 characters')

	# Parse data
	#{description: "", emoji: {}, default = false}
	var _data = {
		'value': value,
		'label': label
	}
	if data.has('description'):
		assert(typeof(data.description) == TYPE_STRING, 'description of SelectMenu option must be a String')
		Helpers.assert_length(data.description, 100, 'description of SelectMenu cannot be more than 100 characters')
		_data['description'] = data.description

	if data.has('emoji'):
		assert(typeof(data.emoji) == TYPE_DICTIONARY, 'emoji of SelectMenu option must be a Dictionary')
		_data['emoji'] = data.emoji

	if data.has('default'):
		assert(typeof(data.default) == TYPE_BOOL, 'default of SelectMenu option must be a bool')
		_data['default'] = data.default

	options.append(_data)

	return self

func set_options(new_options: Array):
	options = new_options
	return self

func get_options() -> Array:
	return options


func set_placeholder(new_placeholder: String):
	Helpers.assert_length(new_placeholder, 100, 'placeholder of SelectMenu cannot be more than 100 characters.')
	placeholder = new_placeholder
	return self

func get_placeholder() -> String:
	return placeholder


func set_min_values(new_min_values: int):
	assert(new_min_values <= 25, 'min_values of SelectMenu cannot be more than 25')
	min_values = new_min_values
	return self

func get_min_values() -> int:
	return min_values


func set_max_values(new_max_values: int):
	assert(new_max_values <= 25, 'max_values of SelectMenu cannot be more than 25')
	max_values = new_max_values
	return self

func get_max_values() -> int:
	return max_values


func set_disabled(new_value: bool):
	disabled = new_value
	return self

func get_disabled() -> bool:
	return disabled



func _init():
	return self

func _to_string(pretty: bool = false) -> String:
	return JSON.print(_to_dict(), '\t') if pretty else JSON.print(_to_dict())

func print():
	print(_to_string(true))

func _to_dict() -> Dictionary:
	# Default style is primary
	assert(Helpers.is_valid_str(custom_id), 'A button must have a custom_id.')
	return {
		'type': type,
		'custom_id': custom_id,
		'options': options,
		'placeholder': placeholder,
		'min_values': min_values,
		'max_values': max_values,
		'disabled': disabled,
	}
