tool
extends HTTPRequest
class_name DiscordBot

"""
Main script for discord.gd plugin
Copyright 2021, Delano Lourenco
For Copyright and License: See LICENSE.md
"""

# Public Variables
var TOKEN: String
var VERBOSE: bool = false
var INTENTS: int = 513


# Caches
var user: User
var application: Dictionary
var guilds = {}
var channels = {}
var users = {}


# Signals
signal bot_ready(bot) # bot: DiscordBot
signal guild_create(bot, guild) # bot: DiscordBot, guild: Dictionary
signal guild_delete(bot, guild) # bot: DiscordBot, guild: Dictionary
signal message_create(bot, message, channel) # bot: DiscordBot, message: Message, channel: Dictionary
signal message_delete(bot, message) # bot: DiscordBot, message: Dictionary





# Private Variables
var _gateway_base = 'wss://gateway.discord.gg/?v=9&encoding=json'
var _https_domain = 'https://discord.com'
var _api_slug = '/api/v9'
var _https_base = _https_domain + _api_slug
var _cdn_base = 'https://cdn.discordapp.com'
var _headers: Array
var _client: WebSocketClient
var _sess_id: String
var _last_seq: float
var _invalid_session_is_resumable: bool
var _heartbeat_interval: int
var _heartbeat_ack_received = true
var _login_error

# Count of the number of guilds initially loaded
var guilds_loaded = 0

var CHANNEL_TYPES = {
	'0': 'GUILD_TEXT',
	'1': 'DM',
	'2': 'GUILD_VOICE',
	'3': 'GROUP_DM',
	'4': 'GUILD_CATEGORY',
	'5': 'GUILD_NEWS',
	'6': 'GUILD_STORE',
	'10': 'GUILD_NEWS_THREAD',
	'11': 'GUILD_PUBLIC_THREAD',
	'12': 'GUILD_PRIVATE_THREAD',
	'13': 'GUILD_STAGE_VOICE'
}

var GUILD_ICON_SIZES = [16,32,64,128,256,512,1024,2048]

var ACTIVITY_TYPES = {
	'GAME': 0,
	'STREAMING': 1,
	'LISTENING': 2,
	'WATCHING': 3,
	'COMPETING': 5
}

var PRESENCE_STATUS_TYPES = ['ONLINE', 'DND', 'IDLE', 'INVISIBLE', 'OFFLINE']


# Public Functions
func login() -> void:
	assert(TOKEN.length() > 2, 'ERROR: Unable to login. TOKEN attribute not set.')
	_headers = ['Authorization: Bot %s' % TOKEN, 'User-Agent: discord.gd (https://github.com/3ddelano/discord.gd)']
	_login_error = _client.connect_to_url(_gateway_base)

	# No internet?
	if _login_error == ERR_INVALID_PARAMETER:
		print('Trying to reconnect in 5s')
		yield(get_tree().create_timer(5), 'timeout')
		var coroutine = self.login()
	else:
		match _login_error:
			ERR_UNAUTHORIZED:
				print('Login Error: Unauthorized')
			ERR_UNAVAILABLE:
				print('Login Error: Unavailable')
			FAILED:
				print('Login Error: Failed (Generic)')

	return


func send(message: Message, content, options: Dictionary = {}) -> Message:
	var res = yield(_send_message_request(message, content, options), 'completed')
	return res


func reply(message: Message, content, options: Dictionary = {}) -> Message:
	options.message_reference = {
		'message_id': message.id
	}
	var res = yield(_send_message_request(message, content, options), 'completed')
	return res


func edit(message: Message, content, options: Dictionary = {}) -> Message:
	var res = yield(_send_message_request(message, content, options, HTTPClient.METHOD_PATCH), 'completed')
	return res


func delete(message: Message):
	var res = yield(_send_message_request(message, '', {}, HTTPClient.METHOD_DELETE), 'completed')
	return res

func start_thread(message: Message, thread_name: String, duration: int = 60 * 24) -> Dictionary:
	var payload = {
		'name': thread_name,
		'auto_archive_duration': duration
	}
	var res = yield(_send_request('/channels/%s/messages/%s/threads' % [message.channel_id, message.id], payload), 'completed')

	return res


func get_guild_icon(guild_id: String, size: int = 256) -> PoolByteArray:
	assert(Helpers.is_valid_str(guild_id), 'Invalid Type: guild_id must be a valid String')

	var guild = guilds.get(str(guild_id))

	assert(guild, 'Guild not cached. Fetch guild first')
	assert(guild.icon, 'Guild has no icon set.')

	if size != 256:
		assert(size in GUILD_ICON_SIZES, 'Invalid size for guild icon provided')

	var png_bytes = yield(
		_send_get_cdn('/icons/%s/%s.png?size=%s' % [guild.id, guild.icon, size]),
		'completed'
	)
	return png_bytes


func set_presence(p_options: Dictionary) -> void:
	"""
		p_options {
			status: String, text of the presence,
			afk: bool, whether or not the client is afk,

			activity: {
				type: String, type of the presence,
				name: String, name of the presence,
				url: String, url of the presence,
				created_at: int, unix timestamp (in milliseconds) of when activity was added to user's session
			}
		}
	"""

	var new_presence = {
		'status': 'online',
		'afk': false,
		'activity': {}
	}

	assert(p_options, 'Missing options for set_presence')
	assert(typeof(p_options) == TYPE_DICTIONARY, 'Invalid Type: options in set_presence must be a Dictionary')

	if p_options.has('status') and Helpers.is_valid_str(p_options.status):
		assert(str(p_options.status).to_upper() in PRESENCE_STATUS_TYPES, 'Invalid Type: status must be one of PRESENCE_STATUS_TYPES')
		new_presence.status = p_options.status.to_lower()
	if p_options.has('afk') and typeof(p_options.afk) == TYPE_BOOL:
		new_presence.afk = p_options.afk

	# Check if an activity was passed
	if p_options.has('activity') and typeof(p_options.activity) == TYPE_DICTIONARY:
		if p_options.activity.has('name') and Helpers.is_valid_str(p_options.activity.name):
			new_presence.activity.name = p_options.activity.name

		if p_options.activity.has('url') and Helpers.is_valid_str(p_options.activity.url):
			new_presence.activity.url = p_options.activity.url

		if p_options.activity.has('created_at') and Helpers.is_num(p_options.activity.created_at):
			new_presence.activity.created_at = p_options.activity.created_at
		else:
			new_presence.activity.created_at = OS.get_unix_time() * 1000

		if p_options.activity.has('type') and Helpers.is_valid_str(p_options.activity.type):
			assert(str(p_options.activity.type).to_upper() in ACTIVITY_TYPES, 'Invalid Type: type must be one of ACTIVITY_TYPES')
			new_presence.activity.type = ACTIVITY_TYPES[str(p_options.activity.type).to_upper()]


	_update_presence(new_presence)





# Private Functions
func _ready() -> void:
	randomize()
#
	# Generate needed nodes
	_generate_timer_nodes()

	# Setup web socket client
	_client = WebSocketClient.new()
	_client.connect('connection_closed', self, '_connection_closed')
	_client.connect('connection_error', self, '_connection_error')
	_client.connect('connection_established', self, '_connection_established')
	_client.connect('data_received', self, '_data_received')

	$HeartbeatTimer.connect('timeout', self, '_send_heartbeat')

func _generate_timer_nodes() -> void:
	var heart_beat_timer = Timer.new()
	heart_beat_timer.name = 'HeartbeatTimer'
	add_child(heart_beat_timer)

	var invalid_session_timer = Timer.new()
	invalid_session_timer.name = 'InvalidSessionTimer'
	add_child(invalid_session_timer)

func _connection_closed(was_clean_close: bool) -> void:
	if was_clean_close:
		if VERBOSE:
			print('WSS connection closed cleanly')
	else:
		if VERBOSE:
			print('WSS connection closed unexpectedly')

func _connection_error() -> void:
	if VERBOSE:
		print('WSS connection error')

func _connection_established(protocol: String) -> void:
	if VERBOSE:
		print('Connected with protocol: ', protocol)

func _data_received() -> void:
	var packet := _client.get_peer(1).get_packet()
	var data := packet.get_string_from_utf8()

	var dict = _jsonstring_to_dict(data)
	var op = str(dict.op) # OP Code Received
	var d = dict.d # Data Received

	match op:
		'10':
			# Got hello
			_setup_heartbeat_timer(d.heartbeat_interval)

			var response_d = {'op': -1}
			if _sess_id:
				# Resume session
				response_d.op = 6
				response_d['d'] = {'token': TOKEN, 'session_id': _sess_id, 'seq': _last_seq}
			else:
				# Make new session
				response_d.op = 2
				response_d['d'] = {
					'token': TOKEN,
					'intents': INTENTS,
					'properties': {
						'$os': 'linux',
						'$browser': 'discord.gd',
						'$device': 'discord.gd'
					}
				}

			_send_dict_wss(response_d)
		'11':
			# Heartbeat Acknowledged
			_heartbeat_ack_received = true
			if VERBOSE:
				print('Heartbeat ack')
		'9':
			# Opcode 9 Invalid Session
			_invalid_session_is_resumable = d
			var timer = $InvalidSessionTimer
			timer.one_shot = true
			timer.wait_time = rand_range(1, 5)
			timer.start()
		'0':
			# Event Dispatched
			_handle_events(dict)

func _process(_delta) -> void:
	# Run only when in game and not in the editor
	if not Engine.is_editor_hint():
		# Poll the web socket if connected otherwise reconnect
		var is_connected = (
			_client.get_connection_status()
			!= NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED
		)
		if is_connected:
			_client.poll()
		else:
			_client.connect_to_url(_gateway_base)

func _send_heartbeat() -> void: # Send heartbeat OP code 1
	if not _heartbeat_ack_received:
		_client.disconnect_from_host(1002)
		return

	var response_payload = {'op': 1, 'd': _last_seq}
	_send_dict_wss(response_payload)
	_heartbeat_ack_received = false
	if VERBOSE:
		print('Heartbeat sent!')

func _handle_events(dict: Dictionary) -> void:
	_last_seq = dict.s
	var event_name = dict.t

	match event_name:
		'READY':
			_sess_id = dict.d.session_id
			var d = dict.d

			var _application = d.application
			var _guilds = d.guilds
			_clean_guilds(_guilds)

			var _user: User = User.new(self, d.user)
			user = _user
			application = _application

			for guild in _guilds:
				guilds[guild.id] = guild


			# bot_ready is emitted after guilds are loaded
			#emit_signal('bot_ready', self)

		'GUILD_CREATE':
			var guild = dict.d
			_clean_guilds([guild])

			if not guilds.has(guild.id):
				# Joined a new guild
				emit_signal('guild_create', self, guild)

			# update cache
			guilds[guild.id] = guild

			# update number of cached guilds
			if guild.has('lazy') and guild.lazy:
				guilds_loaded += 1
				if guilds_loaded == guilds.size():
					emit_signal('bot_ready', self)

			for channel in guild.channels:
				_clean_channel(channel)
				channel.guild_id = guild.id
				channels[channel.id] = channel

		'GUILD_DELETE':
			var guild = dict.d
			guilds.erase(guild.id)
			emit_signal('guild_delete', self, guild.id)

		'RESUMED':
			if VERBOSE:
				print('Session Resumed')

		'MESSAGE_CREATE':
			var d = dict.d

			# Dont respond to webhooks
			if d.has('webhook_id') and d.webhook_id:
				return

			if d.has('sticker_items') and d.sticker_items and typeof(d.sticker_items) == TYPE_ARRAY:
				if d.sticker_items.size() != 0:
					return

			var coroutine = _parse_message(d)
			if typeof(coroutine) == TYPE_OBJECT:
				coroutine = yield(coroutine, 'completed')
				if coroutine == null:
					# message might be a thread
					# TODO: Handle sending messages in threads
					return

			d = Message.new(d)
			var channel = channels.get(str(d.channel_id))
			emit_signal('message_create', self, d, channel)

		'MESSAGE_DELETE':
			var d = dict.d
			emit_signal('message_delete', self, d)

func _send_raw_request(slug: String, payload: Dictionary, method = HTTPClient.METHOD_POST):
	var headers = _headers.duplicate(true)
	var multipart_header = 'Content-Type: multipart/form-data; boundary="boundary"'
	if headers.find(multipart_header) == -1:
		headers.append(multipart_header)

	var http_client = HTTPClient.new()

	var body = PoolByteArray()

	# Add the payload_json to the form
	body.append_array('--boundary\r\n'.to_utf8())
	body.append_array('Content-Disposition: form-data; name="payload_json"\r\n'.to_utf8())
	body.append_array('Content-Type: application/json\r\n\r\n'.to_utf8())
	body.append_array(JSON.print(payload.payload_json).to_utf8())

	var count = 0
	for file in payload.files:
		# Extract the name, media_type and data of each file
		var file_name = file.name
		var media_type = file.media_type
		var data = file.data
		# Add the file to the form
		body.append_array('\r\n--boundary\r\n'.to_utf8())
		body.append_array(('Content-Disposition: form-data; name="file' + str(count) + '"; filename="'+ file_name +'"').to_utf8())
		body.append_array(('\r\nContent-Type: ' + media_type + '\r\n\r\n').to_utf8())
		body.append_array(data)
		count += 1

	# End the form-data
	body.append_array('\r\n--boundary--'.to_utf8())
	var err = http_client.connect_to_host(_https_domain, -1, true, false)
	assert(err == OK, 'Error connecting to Discord HTTPS server')

	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		yield(get_tree(), 'idle_frame')

	assert(http_client.get_status() == HTTPClient.STATUS_CONNECTED, 'Could not connect to Discord HTTPS server')
	err = http_client.request_raw(method, _api_slug + slug, headers, body)

	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		yield(get_tree(), 'idle_frame')

	# Request is made, now extract the reponse body
	assert(http_client.get_status() == HTTPClient.STATUS_BODY or http_client.get_status() == HTTPClient.STATUS_CONNECTED)

	if http_client.has_response():
		headers = http_client.get_response_headers_as_dictionary()

		var rb = PoolByteArray()
		while http_client.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http_client.poll()
			var chunk = http_client.read_response_body_chunk()
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				OS.delay_usec(1000)
			else:
				rb = rb + chunk # Append to read buffer.

		var response = _jsonstring_to_dict(rb.get_string_from_utf8())
		if response.has('code'):
			print('Response: status code ', str(http_client.get_response_code()))
			print(JSON.print(response, '\t'))

		assert(not response.has('code'), 'Error sending request. See output window')


		if response.has('retry_after'):
			# We got ratelimited
			yield(get_tree().create_timer(int(response.retry_after)), 'timeout')
			response = yield(_send_raw_request(slug, payload, method), 'completed')

		return response
	else:
		assert(false, 'Unable to upload file. Got empty response from server')

func _send_request(slug: String, payload: Dictionary, method = HTTPClient.METHOD_POST):
	var headers = _headers.duplicate(true)

	var json_header = 'Content-Type: application/json'
	if headers.find(json_header) == -1:
		headers.append(json_header)

	var http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.call_deferred('request', _https_base + slug, headers, false, method, JSON.print(payload))

	var data = yield(http_request, 'request_completed')
	http_request.queue_free()

	# Check for errors
	assert(data[0] == HTTPRequest.RESULT_SUCCESS, 'Error sending request: HTTP Failed')

	var response = _jsonstring_to_dict(data[3].get_string_from_utf8())

	if response and response.has('code'):
		# Got an error
		print('Response: status code ', str(data[1]))
		print('Error: ' + JSON.print(response, '\t'))

	if method != HTTPClient.METHOD_DELETE:
		assert(not response.has('code'), 'Error sending request. See output window')

	if response.has('retry_after'):
		# We got ratelimited
		yield(get_tree().create_timer(int(response.retry_after)), 'timeout')
		response = yield(_send_request(slug, payload, method), 'completed')

	return response

func _get_dm_channel(channel_id: String) -> Dictionary:
	assert(Helpers.is_valid_str(channel_id), 'Invalid Type: channel_id must be a valid String')
	var data = yield(_send_get('/channels/%s' % channel_id), 'completed')
	return data

func _send_get(slug) -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
#	http_request.use_threads = true
	http_request.call_deferred('request', _https_base + slug, _headers)
	var data = yield(http_request, 'request_completed')
	http_request.queue_free()

	assert(data[0] == HTTPRequest.RESULT_SUCCESS)

	var response = _jsonstring_to_dict(data[3].get_string_from_utf8())
	if response.has('code'):
		# Got an error
		print('GET: status code ', str(data[1]))
		print('Error sending GET request: ' + JSON.print(response, '\t'))
	assert(not response.has('code'), 'Error sending GET request. See output window')

	return response

func _send_get_cdn(slug) -> PoolByteArray:
	var http_request = HTTPRequest.new()
	add_child(http_request)
#	http_request.use_threads = true
	http_request.request(_cdn_base + slug, _headers)
	var data = yield(http_request, 'request_completed')
	http_request.queue_free()

	# Check for errors
	assert(data[0] == HTTPRequest.RESULT_SUCCESS, 'Error sending GET cdn request: HTTP Failed')

	if data[1] != 200:
		print('HTTPS GET cdn Error: Status Code: %s' % data[1])
	assert(data[1] == 200, 'HTTPS GET cdn Error: Status code ' + str(data[1]))

	return data[3]

func _send_message_request(message: Message, content, options := {}, method := HTTPClient.METHOD_POST):
	var payload = {
		'content': null,
		'tts': false,
		'embeds': null,
		'allowed_mentions': null,
		'message_reference': null
	}

	var slug = '/channels/%s/messages' % str(message.channel_id)
	# Handle edit message or delete message
	if method == HTTPClient.METHOD_PATCH or method == HTTPClient.METHOD_DELETE:
		slug += '/' + str(message.id)
		if typeof(message.attachments) == TYPE_ARRAY:
			if message.attachments.size() == 0:
				payload.attachments = null
			else:
				# Add the attachments to keep to the payload
				payload.attachments = message.attachments

	if not message is Message:
		assert(false, 'Invalid Type: message must be a valid Message')

	# Check if the content is only a string
	if typeof(content) == TYPE_STRING and content.length() > 0:
		assert(content.length() < 2048, 'Message content must be less than 2048 characters')
		payload.content = content

	# Check if the content is the options dictionary
	elif typeof(content) == TYPE_DICTIONARY:
		options = content
		content = null

	# Parse the options
	if typeof(options) == TYPE_DICTIONARY:
		"""parse the message options - refer https://discord.com/developers/docs/resources/channel#create-message-jsonform-params
		options {
			tts: bool,
			embeds: array,
			allowed_mentions: object,
			message_reference: object,
			files: Array
		}
		"""
		if options.has('tts') && options.tts:
			payload.tts = true

		if options.has('embeds') && options.embeds.size() > 0:
			for embed in options.embeds:
				if embed is Embed:
					if payload.embeds == null:
						payload.embeds = []
					payload.embeds.append(embed._to_dict())

		if options.has('allowed_mentions') && options.allowed_mentions:
			if typeof(options.allowed_mentions) == TYPE_DICTIONARY:
				"""
				allowedMentions {
					parse: array of mention types ['roles', 'users', 'everyone']
					roles: array of role_ids
					users: array of user_ids
					replied_user: bool, whether to mention author of msg
				}
				"""
				payload.allowed_mentions = options.allowed_mentions

		if options.has('message_reference') && options.message_reference:
			"""
			message_reference {
				message_id: id of originating msg,
				channel_id? *: optional
				guild_id?: optional
				fail_if_not_exists?: bool, whether to error
			}
			"""
			payload.message_reference = options.message_reference

		if options.has('files') and options.files:
			assert(typeof(options.files) == TYPE_ARRAY, 'Invalid Type: files in message options must be an array')

			if options.files.size() > 0:
				# Loop through each file
				for file in options.files:
					assert(file.has('name') and Helpers.is_valid_str(file.name), 'Missing name for file in files')
					assert(file.has('media_type') and Helpers.is_valid_str(file.media_type), 'Missing media_type for file in files')
					assert(file.has('data') and file.data, 'Missing data for file in files')
					assert(file.data is PoolByteArray, 'Invalid Type: data of file in files must be PoolByteArray')


			var json_payload = payload.duplicate(true)
			var new_payload = {
				'files': options.files,
				'payload_json': json_payload
			}
			payload = new_payload


	var res
	if payload.has('files') and payload.files and typeof(payload.files) == TYPE_ARRAY:
		# Send raw post request using multipart/form-data
		var coroutine = _send_raw_request(slug, payload, method)
		if typeof(coroutine) == TYPE_OBJECT:
			res = yield(coroutine, 'completed')
		else:
			res = coroutine

	else:
		res = yield(_send_request(slug, payload, method), 'completed')


	if method == HTTPClient.METHOD_DELETE:
		return res
	else:
		var coroutine = _parse_message(res)
		if typeof(coroutine) == TYPE_OBJECT:
			coroutine = yield(coroutine, 'completed')

		var msg = Message.new(res)
		return msg

func _update_presence(new_presence: Dictionary) -> void:
	var status = new_presence.status
	var activity = new_presence.activity

	var response_d = {
		'op': 3, # Presence update
	}
	response_d['d'] = {
		'since': new_presence if new_presence.has('since') else null,
		'status': new_presence.status,
		'afk': new_presence.afk,
		'activities': [new_presence.activity]
	}
	_send_dict_wss(response_d)



# Helper functions
func _jsonstring_to_dict(data: String) -> Dictionary:
	var json_parsed = JSON.parse(data)
	return json_parsed.result

func _setup_heartbeat_timer(interval: int) -> void:
	# Setup heartbeat timer and start it
	_heartbeat_interval = int(interval) / 1000
	var timer = $HeartbeatTimer
	timer.wait_time = _heartbeat_interval
	timer.start()

func _send_dict_wss(d: Dictionary) -> void:
	var payload = to_json(d)
	_client.get_peer(1).put_packet(payload.to_utf8())

func _clean_guilds(guilds: Array) -> void:
	for guild in guilds:
		# converts the unavailable property to available
		if guild.has('unavailable'):
			guild.available = not guild.unavailable
		else:
			guild.available = true
		guild.erase('unavailable')

func _clean_channel(channel: Dictionary) -> void:
	if channel.has('type') and str(channel.type) in CHANNEL_TYPES.keys():
		channel.type = CHANNEL_TYPES.get(str(channel.type))

func _parse_message(message: Dictionary):
	assert(typeof(message) == TYPE_DICTIONARY, 'Invalid Type: message must be a Dictionary')

	if message.has('channel_id') and message.channel_id:
		# Check if channel is cached
		var channel = channels.get(str(message.channel_id))

		if not channel:
			# Try to check if it is a DM channel
			if VERBOSE:
				print('Fetching DM channel: %s from api' % message.channel_id)

			channel = yield(_get_dm_channel(message.channel_id), 'completed')
			_clean_channel(channel)

			if channel and channel.has('type') and channel.type == 'DM':
				channels[str(message.channel_id)] = channel
			else:
				# not a valid channel, it might be a thread
				return null

	if message.has('author') and typeof(message.author) == TYPE_DICTIONARY:
		# get the cached author of the message
		var user = users.get(str(message.author.id))
		if user:
			message.author = user
		else:
			message.author = User.new(self, message.author)

	return 1
