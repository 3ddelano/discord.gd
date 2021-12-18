class_name MessageActionRow
"""
Represnts a Discord message action row which has components
"""

var components: Array

func _init():
	return self


func add_component(component, index = -1):
	assert(components.size() + 1 <= 5, 'MessageActionRow cannot have more than 5 components.')
	assert(component.type != 1, 'MessageActionRow cannot contain another MessageActionRow.')

	var same_custom_id = false
	for _component in components:
		if Helpers.is_valid_str(_component.get_custom_id()):
			if _component.get_custom_id() == component.get_custom_id():
				same_custom_id = true
				break
	assert(same_custom_id == false, 'MessageActionRow must contain components with unique custom_id')

	if index == -1:
		components.append(component)
	else:
		components.insert(index, component)
	return self


func slice_components(index: int, delete_count: int = 1, replace_components: Array = []):
	var n = components.size()
	assert(Helpers.is_num(index), 'index must be provided to MessageActionRow.slice_components')
	assert(index > -1 and index < n, 'index out of bounds in MessageActionRow.slice_components')

	var max_deletable = n - index
	assert(delete_count <= max_deletable, 'delete_count out of bounds in MessageActionRow.slice_components')

	while delete_count != 0:
		components.remove(index)
		delete_count -= 1

	if replace_components.size() != 0:
		# add components
		for component in replace_components:
			add_component(component, index)
			index += 1

	return self



func _to_string(pretty: bool = false) -> String:
	return JSON.print(_to_dict(), '\t') if pretty else JSON.print(_to_dict())


func print():
	print(_to_string(true))


func _to_dict() -> Dictionary:
	assert(components.size() <= 5, 'MessageActionRow cannot have more than 5 components.')

	var _components = []
	for component in components:
		_components.append(component._to_dict())

	return {
		'type': 1,
		'components': _components
	}
