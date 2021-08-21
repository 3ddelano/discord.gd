class_name DiscordInteraction

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
	'UPDATE_MESSAGE': 7
}


func is_message_component() -> bool:
	return type == 'MESSAGE_COMPONENT'


func is_button() -> bool:
	return is_message_component() and data.component_type == 2


func is_select_menu() -> bool:
	return is_message_component() and data.component_type == 3


func in_guild() -> bool:
	return guild_id != '' and member != {}


func fetch_reply(message_id: String = '@original'):
	#assert(not ephemeral, 'Unable to fetch ephemeral Interaction reply.')
	return yield(_fetch_message(message_id), 'completed')


func reply(options: Dictionary):
	assert(not (replied or deferred), 'Already replied to Interaction.')
	#assert(not(options.fetch_reply and options.ephemeral), 'Unable to fetch reply of ephemeral Interaction.')

	options.type = RESPONSE_TYPES['CHANNEL_MESSAGE_WITH_SOURCE']
	var res = yield(
		_send_request('/interactions/%s/%s/callback' % [id, token], options), 'completed'
	)
	replied = true

	return res


func edit_reply(options: Dictionary):
	assert(deferred or replied, 'Unable to edit Interaction. Not replied.')
	var res = yield(_edit_message('@original', options), 'completed')
	replied = true
	return res


func delete_reply():
	assert(not ephemeral, 'Unable to delete Interaction reply.')
	return yield(_delete_message(), 'completed')


func defer_reply(options: Dictionary = {}):
	assert(not (replied or deferred), 'Already replied to Interaction.')
	#assert(not(options.fetch_reply and options.ephemeral), 'Unable to fetch reply of ephemeral Interaction.')

	options.type = RESPONSE_TYPES['DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE']
	var res = yield(
		_send_request('/interactions/%s/%s/callback' % [id, token], options), 'completed'
	)
	deferred = true
	return res


func update(options: Dictionary):
	if replied or deferred:
		push_error('Already replied to Interaction.')
	options.type = RESPONSE_TYPES['UPDATE_MESSAGE']
	var msg = yield(
		_send_request('/interactions/%s/%s/callback' % [id, token], options), 'completed'
	)
	replied = true
	return msg


func defer_update(options: Dictionary = {}):
	assert(not (replied or deferred), 'Already replied to Interaction.')
	#assert(not(options.fetch_reply and options.ephemeral), 'Unable to fetch reply of ephemeral Interaction.')

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


func _fetch_message(message_id: String = '@original'):
	var msg = yield(
		bot._send_get('/webhooks/%s/%s/messages/%s' % [application_id, token, message_id]),
		'completed'
	)
	var coroutine = bot._parse_message(msg)
	if typeof(coroutine) == TYPE_OBJECT:
		coroutine = yield(coroutine, 'completed')

	var ret = Message.new(msg)
	message = ret
	return ret


func _delete_message(message_id: String = '@original'):
	var res = yield(
		bot._send_get(
			'/webhooks/%s/%s/messages/%s' % [application_id, token, message_id],
			HTTPClient.METHOD_DELETE
		),
		'completed'
	)


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

	options.attachments = message.attachments

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
			_embeds.append(embed._to_dict())

	var _components = []
	if options.has('components') and options.components.size() > 0:
		for component in options.components:
			_components.append(component._to_dict())

	var payload = {
		'type': _type,
		'data':
		{
			'tts': options.tts if options.has('tts') else message.tts,
			'content': options.content if options.has('content') else message.content,
			'embeds': _embeds,
			'allowed_mentions': options.allowed_mentions if options.has('allowed_mentions') else {},
			'attachments': options.attachments if options.has('attachments') else [],
			'flags': MessageFlags.new('EPHEMERAL') if ephemeral else null,
			'components': _components
		}
	}

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


#func is_command() -> bool:
#	return true

#func is_context_menu() -> bool:
#	return


func _init(_bot, interaction: Dictionary):
	bot = _bot
	assert(Helpers.is_valid_str(interaction.id), 'Interaction must have an id')
	assert(
		Helpers.is_valid_str(interaction.application_id), 'Interaction must have an application id'
	)
	assert(Helpers.is_valid_str(interaction.token), 'Interaction must have a token')
	assert(Helpers.is_valid_str(interaction.type), 'Interaction must have a type')
	assert(Helpers.is_num(interaction.version), 'Interaction must have a version')

	id = interaction.id
	application_id = interaction.application_id
	token = interaction.token
	type = interaction.type

	if interaction.has('message'):
		var coroutine = bot._parse_message(interaction.message)
		if typeof(coroutine) == TYPE_OBJECT:
			coroutine = yield(coroutine, 'completed')

		message = Message.new(interaction.message)

	if interaction.has('member'):
		member = interaction.member

	if interaction.has('guild_id'):
		guild_id = interaction.guild_id

	if interaction.has('channel_id'):
		channel_id = interaction.channel_id

	if interaction.has('data'):
		data = interaction.data


func _to_string(pretty: bool = false) -> String:
	return JSON.print(_to_dict(), '\t') if pretty else JSON.print(_to_dict())


func print():
	print(_to_string(true))


func _to_dict() -> Dictionary:
	return {
		'version': 1,
		'type': type,
		'token': token,
		'message': message or {},
		'member': member,
		'id': id,
		'guild_id': guild_id,
		'data': data,
		'channel_id': channel_id,
		'application_id': application_id,
	}
