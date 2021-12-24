class_name DiscordInteraction
"""
Represents a Discord interaction.
"""

var bot
var replied = false
var deferred = false
var ephemeral = false

# Compulsory
var id: String
var application_id: String
var type: String
var token: String

# Optional
var message: Message
var channel_id: String
var guild_id: String
var member: Dictionary
var data: Dictionary

var RESPONSE_TYPES = {
	'CHANNEL_MESSAGE_WITH_SOURCE': 4,
	'DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE': 5,
	'DEFERRED_UPDATE_MESSAGE': 6,
	'UPDATE_MESSAGE': 7,
	'APPLICATION_COMMAND_AUTOCOMPLETE_RESULT': 8
}

var TYPES = {
	1: 'PING',
	2: 'APPLICATION_COMMAND',
	3: 'MESSAGE_COMPONENT',
	4: 'APPLICATION_COMMAND_AUTOCOMPLETE'
}
#= {'2': 'APPLICATION_COMMAND', '3': 'MESSAGE_COMPONENT', '4': 'AUTOCOMPLETE'}

func is_command() -> bool:
	return type == 'APPLICATION_COMMAND'


func is_autocomplete() -> bool:
	return type == 'APPLICATION_COMMAND_AUTOCOMPLETE'


func is_message_component() -> bool:
	return type == 'MESSAGE_COMPONENT'


func is_button() -> bool:
	return is_message_component() and data.component_type == 2


func is_select_menu() -> bool:
	return is_message_component() and data.component_type == 3


func in_guild() -> bool:
	return guild_id != '' and member != {}


func respond_autocomplete(choices: Array):
	var payload = {
		'type': RESPONSE_TYPES['APPLICATION_COMMAND_AUTOCOMPLETE_RESULT'],
		'data': {
			'choices': choices
		}
	}
	var res = yield(
		bot._send_request('/interactions/%s/%s/callback' % [id, token], payload), 'completed'
	)
	return res


func fetch_reply(message_id: String = '@original'):
	#assert(not ephemeral, 'Unable to fetch ephemeral Interaction reply.')
	if ephemeral:
		push_error('Unable to fetch ephemeral reply.')
		return yield()

	var msg = yield(
		bot._send_get('/webhooks/%s/%s/messages/%s' % [application_id, token, message_id]),
		'completed'
	)
	var coroutine = bot._parse_message(msg)
	if typeof(coroutine) == TYPE_OBJECT:
		coroutine = yield(coroutine, 'completed')

	return Message.new(msg)


func reply(options: Dictionary):
	if replied or deferred:
		push_error('Already replied to Interaction.')
		return yield()

	options.type = RESPONSE_TYPES['CHANNEL_MESSAGE_WITH_SOURCE']
	var res = yield(
		_send_request('/interactions/%s/%s/callback' % [id, token], options), 'completed'
	)
	replied = true

	return res


func edit_reply(options: Dictionary):
	if (not replied) and (not deferred):
		push_error('Unable to edit Interaction. Not replied.')
		return yield()

	var res = yield(_edit_message('@original', options), 'completed')
	replied = true
	return res


func delete_reply():
	if ephemeral:
		push_error('Unable to delete ephemeral Interaction reply.')
		return yield()

	return yield(_delete_message(), 'completed')


func defer_reply(options: Dictionary = {}):
	if replied or deferred:
		push_error('Already replied to Interaction.')
		return yield()

	options.type = RESPONSE_TYPES['DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE']
	var res = yield(
		_send_request('/interactions/%s/%s/callback' % [id, token], options), 'completed'
	)
	deferred = true
	return res


func update(options: Dictionary):
	if replied or deferred:
		push_error('Already replied to Interaction.')
		return yield()

	options.type = RESPONSE_TYPES['UPDATE_MESSAGE']
	var msg = yield(
		_send_request('/interactions/%s/%s/callback' % [id, token], options), 'completed'
	)
	replied = true
	return msg


func defer_update(options: Dictionary = {}):
	if replied or deferred:
		push_error('Already replied to Interaction.')
		return yield()

	options.type = RESPONSE_TYPES['DEFERRED_UPDATE_MESSAGE']
	var res = yield(
		_send_request('/interactions/%s/%s/callback' % [id, token], options), 'completed'
	)
	deferred = true
	return res


func follow_up(options: Dictionary):
	options.type = RESPONSE_TYPES['CHANNEL_MESSAGE_WITH_SOURCE']
	var res = yield(
		_send_request(
			'/webhooks/%s/%s' % [application_id, token], options, HTTPClient.METHOD_POST, true
		),
		'completed'
	)
	return res


func edit_follow_up(msg: Message, options: Dictionary):
#	options.type = RESPONSE_TYPES['CHANNEL_MESSAGE_WITH_SOURCE']
#	var res = yield(_send_request('/webhooks/%s/%s/messages/%s' % [application_id, token, message.id], options, HTTPClient.METHOD_PATCH, true), 'completed')
#	return res
	var res = yield(_edit_message(msg.id, options), 'completed')
	return res


func delete_follow_up(msg: Message):
	var res = yield(_delete_message(msg.id), 'completed')
	return res


func has(attribute):
	return true if self[attribute] else false


func _delete_message(message_id: String = '@original'):
	var res = yield(
		bot._send_get(
			'/webhooks/%s/%s/messages/%s' % [application_id, token, message_id],
			HTTPClient.METHOD_DELETE
		),
		'completed'
	)
	return res


func _edit_message(message_id: String, options: Dictionary):
	options.type = RESPONSE_TYPES['CHANNEL_MESSAGE_WITH_SOURCE']
	var msg = yield(
		_send_request(
			'/webhooks/%s/%s/messages/%s' % [application_id, token, message_id],
			options,
			HTTPClient.METHOD_PATCH
		),
		'completed'
	)
	return msg


func _send_request(
	slug: String, options: Dictionary, method = HTTPClient.METHOD_POST, is_follow_up = false
):
	var files = []
	if options.has('files'):
		files = options.files
		options.erase('files')

	var _type = options.type
	options.erase('type')

	options.attachments = message.attachments if message != null else []

	if options.has('ephemeral') and typeof(options.ephemeral) == TYPE_BOOL:
		ephemeral = options.ephemeral
		options.erase('ephemeral')

	var _fetch_reply = false
	if options.has('fetch_reply'):
		_fetch_reply = options.fetch_reply
		options.erase('fetch_reply')

	var _embeds = []
	if options.has('embeds') and options.embeds.size() > 0:
		for embed in options.embeds:
			if typeof(embed) == TYPE_DICTIONARY:
				_embeds.append(embed)
			else:
				_embeds.append(embed._to_dict())

	var _components = []
	if options.has('components') and options.components.size() > 0:
		for component in options.components:
			if typeof(component) == TYPE_DICTIONARY:
				_components.append(component)
			else:
				_components.append(component._to_dict())

	var payload = {
		'type': _type,
		'data':
		{
			'tts': options.tts if options.has('tts') else false,
			'content': options.content if options.has('content') else null,
			'embeds': _embeds,
			'allowed_mentions': options.allowed_mentions if options.has('allowed_mentions') else {},
			'attachments': options.attachments if options.has('attachments') else [],
			'flags': MessageFlags.new('EPHEMERAL') if ephemeral else null,
			'components': _components
		}
	}

	if _type == RESPONSE_TYPES['UPDATE_MESSAGE']:
		# Append the message parts from the original message if the options doesnt contain that part
		if not options.has('tts'):
			payload.data.tts = message.tts
		if not options.has('content'):
			payload.data.content = message.content
		if not options.has('embeds'):
			payload.data.embeds = message.embeds
		if not options.has('components'):
			payload.data.components = message.components

	if method == HTTPClient.METHOD_PATCH or is_follow_up:
		payload = payload.data

	var res
	var coroutine = yield(
		bot._send_raw_request(slug, {'payload': payload, 'files': files}, method), 'completed'
	)

	if typeof(coroutine) == TYPE_OBJECT:
		res = yield(coroutine, 'completed')
	else:
		res = coroutine

	if is_follow_up:
		coroutine = bot._parse_message(res)
		if typeof(coroutine) == TYPE_OBJECT:
			coroutine = yield(coroutine, 'completed')

		return Message.new(res)

	if _fetch_reply:
		return yield(fetch_reply('@original'), 'completed')
	else:
		return true


func _init(_bot, interaction: Dictionary):
	bot = _bot
	assert(Helpers.is_valid_str(interaction.id), 'Interaction must have an id')
	assert(
		Helpers.is_valid_str(interaction.application_id), 'Interaction must have an application id'
	)
	assert(Helpers.is_valid_str(interaction.token), 'Interaction must have a token')
	assert(interaction.has('type'), 'Interaction must have a type')
	assert(Helpers.is_num(interaction.version), 'Interaction must have a version')

	id = interaction.id
	application_id = interaction.application_id
	token = interaction.token
	type = TYPES[int(interaction.type)]

	if interaction.has('message'):
		var coroutine = bot._parse_message(interaction.message)
		if typeof(coroutine) == TYPE_OBJECT:
			coroutine = yield(coroutine, 'completed')

		message = Message.new(interaction.message)

	if interaction.has('member'):
		member = interaction.member
		# Try to parse the member permissions
		if member.has('permissions'):
			member.permissions = Permissions.new(member.permissions)

		# Try to parse the member user
		if member.has('user'):
			member.user = User.new(bot, member.user)

	if interaction.has('guild_id'):
		guild_id = interaction.guild_id

	if interaction.has('channel_id'):
		channel_id = interaction.channel_id

	if interaction.has('data'):
		data = interaction.data
		if type == 'APPLICATION_COMMAND':
			data.type = ApplicationCommand._COMMAND_TYPES[int(data.type)]
			data = _parse_data_options(interaction.data)

func _parse_data_options(data, option = false):
	if option and data.has('type'):
		data.type = ApplicationCommand._OPTION_TYPES[int(data.type)]

	if data.has('options'):
		for i in range(len(data.options)):
			data.options[i] = _parse_data_options(data.options[i], true)
	return data

func _to_string(pretty: bool = false) -> String:
	return JSON.print(_to_dict(), '\t') if pretty else JSON.print(_to_dict())


func print():
	print(_to_string(true))


func _to_dict() -> Dictionary:
	return {
		'version': 1,
		'type': type,
		'token': token,
		'message': message._to_string() if message is Message else {},
		'member': member,
		'id': id,
		'guild_id': guild_id,
		'data': data,
		'channel_id': channel_id,
		'application_id': application_id,
	}
