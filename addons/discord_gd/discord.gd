tool
extends HTTPRequest
class_name DiscordBot

# Public Variables
var TOKEN: String
var VERBOSE = false
var INTENTS = 513


# Caches
var user: User
var application: Dictionary
var guilds = {}
var channels = {}
var dm_channels = {}
var users = {}


# Signals
signal bot_ready
signal guild_create
signal guild_delete
signal message_create
signal message_delete





# Private Variables
var _gateway_base = 'wss://gateway.discord.gg/?v=9&encoding=json'
var _https_base = 'https://discord.com/api/v9'
var _cdn_base = 'https://cdn.discordapp.com'
var _headers: Array
var _client: WebSocketClient
var _sess_id: String
var _last_seq: float
var _invalid_session_is_resumable: bool
var _heartbeat_interval: int
var _heartbeat_ack_received = true

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





# Public Functions
func login():
	assert(TOKEN.length() > 2, 'ERROR: Unable to login. TOKEN attribute not set.')
	_headers = ['Authorization: Bot %s' % TOKEN, 'User-Agent: discord.gd (localhost, 1.0)']
	var err = _client.connect_to_url(_gateway_base)
	if err != OK:
		print('Unable to connect')
		set_process(false)
	else:
		match err:
			ERR_UNAUTHORIZED:
				print('Login Error: Unauthorized')
			ERR_UNAVAILABLE:
				print('Login Error: Unavailable')
			FAILED:
				print('Login Error: Failed (Generic)')
		return

func send(message: Message, content, options: Dictionary = {}):
	var res = yield(_send_message_request(message, content, options), 'completed')
	return res

func reply(message: Message, content, options: Dictionary = {}):
	options.message_reference = {
		'message_id': message.id
	}
	var res = yield(_send_message_request(message, content, options), 'completed')
	return res

func edit(message: Message, content, options: Dictionary = {}):
	var res = yield(_send_message_request(message, content, options, HTTPClient.METHOD_PATCH), 'completed')
	return res

func start_thread(message, thread_name, duration = 60 * 24):
	var payload = {
		'name': thread_name,
		'auto_archive_duration': duration
	}
	var res = yield(_send_request('/channels/%s/messages/%s/threads' % [message.channel_id, message.id], payload), 'completed')

	return res


func get_guild_icon(guild_id: String, size: int = 256) -> ImageTexture:
	assert(Helpers.is_valid_str(guild_id), 'guild_id must be a valid guild id')

	var guild = guilds.get(str(guild_id))

	assert(guild, 'Guild not cached. Fetch guild first')
	assert(guild.icon, 'Guild has no icon set.')

	if size != 256:
		assert(size in GUILD_ICON_SIZES, 'Invalid guild icon size provided')

	var png_bytes = yield(
		_send_get_cdn('/icons/%s/%s.png?size=%s' % [guild.id, guild.icon, size]),
		'completed'
	)
	return _bytes_to_png(png_bytes)

func set_presence():
	pass



# Private Functions
func _ready():
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

func _generate_timer_nodes():
	var heart_beat_timer = Timer.new()
	heart_beat_timer.name = 'HeartbeatTimer'
	add_child(heart_beat_timer)

	var invalid_session_timer = Timer.new()
	invalid_session_timer.name = 'InvalidSessionTimer'
	add_child(invalid_session_timer)

func _connection_closed(was_clean_close: bool):
	if was_clean_close:
		if VERBOSE:
			print('WSS connection closed cleanly')
	else:
		if VERBOSE:
			print('WSS connection closed unexpectedly')

func _connection_error():
	if VERBOSE:
		print('WSS connection error')

func _connection_established(protocol: String):
	if VERBOSE:
		print('Connected with protocol: ', protocol)

func _data_received():
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
					'properties':
					{'$os': 'linux', '$browser': 'discord.gd', '$device': 'discord.gd'}
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

func _process(_delta):
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

func _send_heartbeat(): # Send heartbeat OP code 1
	if not _heartbeat_ack_received:
		_client.disconnect_from_host(1002)
		return
	var response_payload = {'op': 1, 'd': _last_seq}
	_send_dict_wss(response_payload)
	_heartbeat_ack_received = false
	if VERBOSE:
		print('Heartbeat sent!')

func _handle_events(dict: Dictionary):
	_last_seq = dict.s
	var event_name = dict.t

	match event_name:
		'READY':
			_sess_id = dict.d.session_id
			var d = dict.d

			var _application = d.application
			var _guilds = d.guilds
			_clean_guilds(guilds)

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

func _send_request(slug: String, payload: Dictionary, method = HTTPClient.METHOD_POST):
	if _headers.find('Content-Type: application/json') == -1:
		_headers.append('Content-Type: application/json')

	var http_request = HTTPRequest.new()
	add_child(http_request)
#	http_request.use_threads = true

	http_request.call_deferred('request', _https_base + slug, _headers, false, method, JSON.print(payload))

	var data = yield(http_request, 'request_completed')
	http_request.queue_free()

	# Check for errors
	assert(data[0] == HTTPRequest.RESULT_SUCCESS, 'Error sending request: HTTP Failed')

	var response = _jsonstring_to_dict(data[3].get_string_from_utf8())

	if response.has('code'):
		# Got an error
		print('Response: status code ', str(data[1]))
		print('Error: ' + JSON.print(response, '\t'))

	assert(not response.has('code'), 'Error sending request. See output window')

	return response

func _get_dm_channel(channel_id: String) -> Dictionary:
	assert(Helpers.is_valid_str(channel_id), 'channel_id must be a valid String')
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
		'file': null,
		'embeds': null,
		'payload_json': null,
		'allowed_mentions': null,
		'message_reference': null
	}

	if not message is Message:
		assert(false, 'stop')


	if typeof(content) == TYPE_STRING and content.length() > 0:
		assert(content.length() < 2048, 'Message content must be less than 2048 characters')
		payload.content = content

	elif typeof(content) == TYPE_DICTIONARY:
		options = content
		content = null

	if typeof(options) == TYPE_DICTIONARY:
		"""parse the message options - refer to discord api docs
		options {
			tts: bool,
			file: file contents,
			embeds: array,
			payload_json: string,
			allowed_mentions: object,
			message_reference: object,
			components: TODO
		}
		"""
		if options.has('tts') && options.tts:
			payload.tts = true

		if options.has('file') && options.file:
			payload.tts = options.file

		if options.has('embeds') && options.embeds.size() > 0:
			for embed in options.embeds:
				if embed is Embed:
					if payload.embeds == null:
						payload.embeds = []
					payload.embeds.append(embed._to_dict())

		if options.has('payload_json') && options.payload_json:
			payload.payload_json = options.payload_json

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

		# TODO: handle sending message components

	var res
	# Handle edit message
	if method == HTTPClient.METHOD_PATCH:
		res = yield(_send_request('/channels/%s/messages/%s' % [str(message.channel_id), str(message.id)], payload, method), 'completed')
	else:
		res = yield(_send_request('/channels/%s/messages' % str(message.channel_id), payload, method), 'completed')



	var coroutine = _parse_message(res)
	if typeof(coroutine) == TYPE_OBJECT:
		print('waiting to parse message')
		coroutine = yield(coroutine, 'completed')

	var msg = Message.new(res)
	return msg




# Helper functions
func _jsonstring_to_dict(data: String) -> Dictionary:
	var json_parsed = JSON.parse(data)
	return json_parsed.result

func _setup_heartbeat_timer(interval):
	# Setup heartbeat timer and start it
	_heartbeat_interval = int(interval) / 1000
	var timer = $HeartbeatTimer
	timer.wait_time = _heartbeat_interval
	timer.start()

func _send_dict_wss(d: Dictionary):
	var payload = to_json(d)
	_client.get_peer(1).put_packet(payload.to_utf8())

func _clean_guilds(guilds):
	for guild in guilds:
		# converts the unavailable property to available
		if guild.has('unavailable'):
			guild.available = not guild.unavailable
		else:
			guild.available = true
		guild.erase('unavailable')

func _clean_channel(channel):
	if channel.has('type') and str(channel.type) in CHANNEL_TYPES.keys():
		channel.type = CHANNEL_TYPES.get(str(channel.type))


func _parse_message(message: Dictionary):
	assert(typeof(message) == TYPE_DICTIONARY, 'message to be parsed must be a Dictionary')

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

#	if message.has('channel_id'):
#		var channel = channels.get(str(message.channel_id))
#		if channel:
#			message.channel = channel
#		else:
#			# check if channel is a dm channel
#			channel = dm_channels.get(str(message.channel_id))
#
#			if channel:
#				message.channel = channel
#			else:
#				# try fetcing the dm channel from api
#				if VERBOSE:
#					print('Fetching DM channel: %s from api' % message.channel_id)
#
#				channel = yield(_get_dm_channel(message.channel_id), 'completed')
#				_clean_channel(channel)
#
#				if channel and channel.has('type') and channel.type == 'DM':
#					if VERBOSE:
#						print('Caching a new DM channel:', channel.id)
#					dm_channels[str(message.channel_id)] = channel
#				else:
#					return null
#					# not a valid channel, it might be a thread
#
#			message.channel = channel
#		message.erase('channel_id')

#	if message.has('author') and typeof(message.author) == TYPE_DICTIONARY:
#		# get the cached author of the message
#		var user = users.get(str(message.author.id))
#		if user:
#			message.author = user
#		else:
#			message.author = User.new(self, message.author)

#	if message.type == 19: # TODO: Don't hard code the message type
#		if message.has('message_reference') and message.message_reference:
#			# message was a reply to another message
#			message.guild = guilds.get(str(message.message_reference.guild_id))

#	if message.has('guild_id'):
#		message.guild = guilds.get(str(message.guild_id))
#		message.erase('guild_id')

	return 1

func _bytes_to_png(bytes: PoolByteArray) -> ImageTexture:
	var image: Image = Image.new()
	image.load_png_from_buffer(bytes)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	texture.set_data(image)
	return texture
