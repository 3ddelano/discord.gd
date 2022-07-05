class_name DiscordUitls


static func get_or_default(obj, property, default):
	if property in obj and obj[property] != null:
		return obj[property]
	return default


static func set_if_not_null(obj, property, value):
	if value != null:
		obj[property] = value
