# Represents a Discord message action row
#
# An Action Row is a non-interactive container component for other types of components.
# It has a `type: 1` and a sub-array of components of other types.
#
# - You can have up to 5 Action Rows per message
# - An Action Row cannot contain another Action Row
class_name MessageActionRow extends Dataclass

var type: int # [MessageComponentTypes] The type of message component
var components: Array # [Array] of components of other types


# @hidden
func _init().("MessageActionRow"): return self


# @hidden
func from_dict(p_dict: Dictionary):
	.from_dict(p_dict)

	components = []
	for data in p_dict.components:
		match data.type:
			MessageComponentTypes.BUTTON:
				components.append(MessageButton.new().from(data))
			MessageComponentTypes.SELECT_MENU:
				components.append(MessageSelectMenu.new().from(data))
			MessageComponentTypes.TEXT_INPUT:
				components.append(MessageTextInput.new().from(data))


	return self


# @hidden
func to_dict() -> Dictionary:
	var dict = .to_dict().duplicate(true)

	for i in components.size():
		dict.components[i] = components[i].to_dict()

	return dict