class_name ApplicationCommand
"""
Represents a Discord application command.
"""

enum COMMAND_TYPES {
	__,
	CHAT_INPUT,
	USER,
	MESSAGE
}

const _COMMAND_TYPES = {
	1: 'CHAT_INPUT',
	2: 'USER',
	3: 'MESSAGE'
}

enum OPTION_TYPES {
	__,
	SUB_COMMAND,
	SUB_COMMAND_GROUP,
	STRING,
	INTEGER,
	BOOLEAN,
	USER,
	CHANNEL,
	ROLE,
	MENTIONABLE,
	NUMBER
}

const _OPTION_TYPES = {
	1: 'SUB_COMMAND',
	2: 'SUB_COMMAND_GROUP',
	3: 'STRING',
	4: 'INTEGER',
	5: 'BOOLEAN',
	6: 'COMMAND',
	7: 'CHANNEL',
	8: 'ROLE',
	9: 'MENTIONABLE',
	10: 'NUMBER',
}

const _CHANNEL_TYPES = {
	'GUILD_TEXT': 0,
	'DM': 1,
	'GUILD_VOICE': 2,
	'GROUP_DM': 3,
	'GUILD_CATEGORY': 4,
	'GUILD_NEWS': 5,
	'GUILD_STORE': 6,
	'GUILD_NEWS_THREAD': 10,
	'GUILD_PUBLIC_THREAD': 11,
	'GUILD_PRIVATE_THREAD': 12,
	'GUILD_STAGE_VOICE': 13
}

var id: String setget , get_id
var type: int = 1
var application_id: String setget , get_application_id
var guild_id: String setget , get_guild_id
var name: String setget set_name, get_name
var description: String setget set_description, get_description

var options: Array setget set_options, get_options
var default_permission: bool = true
var version: String

func get_id() -> String:
	return id

func set_type(p_type: String):
	type = COMMAND_TYPES[p_type]
	return self

func get_type():
	return _OPTION_TYPES[type]

func get_application_id() -> String:
	return application_id

func set_name(new_name: String):
	name = new_name
	return self

func get_name() -> String:
	return name

func set_description(new_description: String):
	description = new_description
	return self

func get_description() -> String:
	return description

func get_guild_id() -> String:
	return guild_id

func set_options(new_options: Array):
	options = new_options
	return self

func get_options() -> Array:
	return options

func add_option(option_data: Dictionary) -> ApplicationCommand:
	# Generic method to add an option to the command
	assert(option_data.has('type'), 'ApplicationCommand option must have a type')
	assert(option_data.has('name') and Helpers.is_valid_str(option_data.name), 'ApplicationCommand option must have a name')
	assert(option_data.has('description') and Helpers.is_valid_str(option_data.description), 'ApplicationCommand option must have a description')
	options.append(option_data)
	return self

static func sub_command_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.SUB_COMMAND, name, description, data)

static func sub_command_group_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.SUB_COMMAND_GROUP, name, description, data)

static func string_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.STRING, name, description, data)

static func integer_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.INTEGER, name, description, data)

static func boolean_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.BOOLEAN, name, description, data)

static func user_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.USER, name, description, data)

static func channel_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.CHANNEL, name, description, data)

static func role_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.ROLE, name, description, data)

static func mentionable_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.MENTIONABLE, name, description, data)

static func number_option(name: String, description: String, data: Dictionary = {}) -> Dictionary:
	return _make_option(OPTION_TYPES.NUMBER, name, description, data)

static func choice(name: String, value) -> Dictionary:
	return {
		'name': name,
		'value': value
	}

static func _make_option(type: int, name: String, description: String, data: Dictionary = {}) -> Dictionary:
	if data.has('channel_types'):
		for i in range(len(data.channel_types)):
			if _CHANNEL_TYPES.has(data.channel_types[i]):
				data.channel_types[i] = _CHANNEL_TYPES[data.channel_types[i]]

	return {
		'type': type,
		'name': name,
		'description': description,
		# Optional data
		'required': data.required if data.has('required') else null,
		'choices': data.choices if data.has('choices') else null,
		'options': data.options if data.has('options') else null,
		'channel_types': data.channel_types if data.has('channel_types') else null,
		'min_value': data.min_value if data.has('min_value') else null,
		'max_value': data.max_value if data.has('max_value') else null,
		'autocomplete': data.autocomplete if data.has('autocomplete') else false
	}

func _init(data: Dictionary = {}):
	id = data.id if data.has('id') else ''
	type = data.type if data.has('type') else 1
	application_id = data.application_id if data.has('application_id') else ''

	guild_id = data.guild_id if data.has('guild_id') else ''
	name = data.name if data.has('name') else ''
	description = data.description if data.has('description') else ''
	options = data.options if data.has('options') else []
	default_permission = data.default_permission if data.has('default_permission') else true
	version = data.version if data.has('version') else ''

	return self

func _to_string(pretty: bool = false) -> String:
	return JSON.print(_to_dict(), '\t') if pretty else JSON.print(_to_dict())

func print():
	print(_to_string(true))

func _to_dict(is_register = false) -> Dictionary:
	if is_register:
		return {
			'name': name,
			'type': type,
			'description': description,
			'default_permission': default_permission,
			'options': options
		}

	return {
		'id': id,
		'type': type,
		'application_id': application_id,
		'guild_id': '',
		'name': name,
		'description': description,
		'options': options,
		'default_permission': default_permission,
		'version': version
	}
