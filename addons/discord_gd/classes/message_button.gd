class_name MessageButton
"""
Represents a Discord message button.
"""

var _STYLES = {0: 'DEFAULT', 1: 'PRIMARY', 2: 'SECONDARY', 3: 'SUCCESS', 4: 'DANGER', 5: 'LINK'}

enum STYLES { DEFAULT, PRIMARY, SECONDARY, SUCCESS, DANGER, LINK }

var label: String setget set_label, get_label
var custom_id: String setget set_custom_id, get_custom_id
var url: String setget set_url, get_url
var disabled: bool = false setget set_disabled, get_disabled
var emoji: Dictionary

var _style setget set_style, get_style
var type: int = 2


func set_style(style_number: int):
	_style = style_number
	return self


func get_style() -> String:
	return _STYLES[_style]


func set_label(new_label: String):
	assert(new_label.length() <= 80, 'label of MessageButton must be max 80 characters.')
	label = new_label
	return self


func get_label() -> String:
	return label


func set_custom_id(new_custom_id):
	assert(new_custom_id.length() <= 80, 'custom_id of MessageButton must be max 100 characters.')
	custom_id = new_custom_id
	return self


func get_custom_id() -> String:
	return custom_id


func set_url(new_url):
	url = new_url
	return self


func get_url() -> String:
	return url


func set_disabled(new_value: bool):
	disabled = new_value
	return self


func get_disabled() -> bool:
	return disabled


func set_emoji(new_emoji: Dictionary):
	emoji = new_emoji
	return self

func get_emoji() -> Dictionary:
	return emoji


func _init():
	return self


func _to_string(pretty: bool = false) -> String:
	return JSON.print(_to_dict(), '\t') if pretty else JSON.print(_to_dict())


func print():
	print(_to_string(true))


func _to_dict() -> Dictionary:
	# Default style is primary
	if _style == 0:
		_style = 1

	if _style == STYLES.LINK:
		# Must have a url
		assert(Helpers.is_valid_str(url), 'A LINK MessageButton must have a url.')
		return {'type': type, 'style': _style, 'label': label, 'url': url, 'disabled': disabled}
	else:
		assert(Helpers.is_valid_str(custom_id), 'A button must have a custom_id.')
		return {
			'type': type,
			'style': _style,
			'label': label,
			'custom_id': custom_id,
			'disabled': disabled,
			'emoji': emoji
		}
