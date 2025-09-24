class_name DiscordBot
extends Node

"""
Main script for discord.gd plugin
Copyright 2021-present, Delano Lourenco
For Copyright and License: See LICENSE.md
"""


#region Public Variables

var TOKEN: String
var VERBOSE: bool = false
var INTENTS: int = 513

# Caches
var user: User
var application: Dictionary
var guilds = {}
var channels = {}
var users = {}

#endregion



#region Signals

signal bot_ready(bot)  # bot: DiscordBot
signal guild_create(bot, guild)  # bot: DiscordBot, guild: Dictionary
signal guild_update(bot, guild)  # bot: DiscordBot, guild: Dictionary
signal guild_delete(bot, guild)  # bot: DiscordBot, guild: Dictionary
signal message_create(bot, message, channel)  # bot: DiscordBot, message: Message, channel: Dictionary
signal message_delete(bot, message)  # bot: DiscordBot, message: Dictionary
signal interaction_create(bot, interaction)  # bot: DiscordBot, interaction: DiscordInteraction
signal message_reaction_add(bot, data) # bot: DiscordBot, data: Dictionary
signal message_reaction_remove(bot, data) # bot: DiscordBot, data: Dictionary
signal message_reaction_remove_all(bot, data) # bot: DiscordBot, data: Dictionary
signal message_reaction_remove_emoji(bot, data) # bot: DiscordBot, data: Dictionary

#endregion




#region Private Variables
var _gateway_base = 'wss://gateway.discord.gg/?v=9&encoding=json'
var _https_domain = 'https://discord.com'
var _api_slug = '/api/v9'
var _https_base = _https_domain + _api_slug
var _cdn_base = 'https://cdn.discordapp.com'
var _headers: Array
var _client: WebSocketPeer
var _sess_id: String
var _last_seq: float
var _invalid_session_is_resumable: bool
var _heartbeat_interval: int
var _heartbeat_ack_received = true

#endregion



# Count of the number of guilds initially loaded
var guilds_loaded = 0

const CHANNEL_TYPES = {
	'0': 'GUILD_TEXT',
	'1': 'DM',
	'2': 'GUILD_VOICE',
	'3': 'GROUP_DM',
	'4': 'GUILD_CATEGORY',
	'5': 'GUILD_NEWS',
	'10': 'GUILD_NEWS_THREAD',
	'11': 'GUILD_PUBLIC_THREAD',
	'12': 'GUILD_PRIVATE_THREAD',
	'13': 'GUILD_STAGE_VOICE',
	'14': 'GUILD_DIRECTORY',
	'15': 'GUILD_FORUM',
	'16': 'GUILD_MEDIA',
}

var GUILD_ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]

var ACTIVITY_TYPES = {'GAME': 0, 'STREAMING': 1, 'LISTENING': 2, 'WATCHING': 3, 'COMPETING': 5}

var PRESENCE_STATUS_TYPES = ['ONLINE', 'DND', 'IDLE', 'INVISIBLE', 'OFFLINE']

# Public Functions
func login() -> void:
	if VERBOSE:
		print("Logging in...")
	assert(TOKEN.length() > 10, 'ERROR: Unable to login. TOKEN attribute not set.')
	_headers = [
		'Authorization: Bot %s' % TOKEN,
		'User-Agent: discord.gd (https://github.com/3ddelano/discord.gd)'
	]

	var err = _client.connect_to_url(_gateway_base)

	if err == ERR_INVALID_PARAMETER:
		if VERBOSE:
			print('Login Error: Invalid ws url')
		return
	
	if err == ERR_ALREADY_IN_USE:
		if VERBOSE:
			print('Login Error: Already logged in or logging in')
		return
	
	if err != OK:
		if VERBOSE:
			print('Login Error: %s (%s)' % [error_string(err), err])
		return



#region messages

func send(messageorchannelid, content, options: Dictionary = {}) -> Message:
	# channel
	var res = await _send_message_request(messageorchannelid, content, options)
	return res


func reply(message: Message, content, options: Dictionary = {}) -> Message:
	options.message_reference = {'message_id': message.id}
	var res = await _send_message_request(message, content, options)
	return res


func edit(message: Message, content, options: Dictionary = {}) -> Message:
	var res = await _send_message_request(message, content, options, HTTPClient.METHOD_PATCH)
	return res


func delete(message: Message):
	var res = await _send_message_request(message, '', {}, HTTPClient.METHOD_DELETE)
	return res

#endregion



#region threads

func start_thread(message: Message, thread_name: String, duration: int = 60 * 24) -> Dictionary:
	var payload = {'name': thread_name, 'auto_archive_duration': duration}
	var res = await _send_request(
		'/channels/%s/messages/%s/threads' % [message.channel_id, message.id], payload
	)

	return res

#endregion



#region channels

# See https://discord.com/developers/docs/resources/guild#create-guild-channel
# All parameters are optional and nullable excluding data.name
func create_channel(guild_id: String, data: Dictionary) -> Dictionary:
	var res = await _send_request('/guilds/%s/channels' % guild_id, data)
	return res


# See https://discord.com/developers/docs/resources/channel#get-channel
func get_channel(channel_id: String) -> Dictionary:
	var res = await _send_get('/channels/%s' % channel_id)
	return res


# See https://discord.com/developers/docs/resources/channel#modify-channel
func update_channel(channel_id: String, data: Dictionary) -> Dictionary:
	var res = await _send_request('/channels/%s' % channel_id, data, HTTPClient.METHOD_PATCH)
	return res


# See https://discord.com/developers/docs/resources/channel#deleteclose-channel
func delete_channel(channel_id: String):
	var res = await _send_request('/channels/%s' % channel_id, {}, HTTPClient.METHOD_DELETE)
	return res


# See https://discord.com/developers/docs/resources/message#get-channel-messages
# The before, after, and around parameters are mutually exclusive, only one may be passed at a time.
func get_channel_messages(channel_id: String, limit := 50, filter_type := "", filter_value := ""):
	if filter_type != "":
		assert(filter_type in ["before", "after", "around"], "Invalid filter type: %s, Expected: before, after, around" % filter_type)
		assert(filter_value != "", "Filter value must not be empty")
		return await _send_get('/channels/%s/messages?limit=%s&%s=%s' % [channel_id, limit, filter_type, filter_value])
	return await _send_get('/channels/%s/messages?limit=%s' % [channel_id, limit])


# See https://discord.com/developers/docs/resources/message#get-channel-message
func get_channel_message(channel_id: String, message_id: String) -> Message:
	var res = await _send_get('/channels/%s/messages/%s' % [channel_id, message_id])
	_parse_message(res)
	return Message.new(res)


func create_dm_channel(user_id: String) -> Dictionary:
	var res = await _send_request('/users/@me/channels', {'recipient_id': user_id})
	if typeof(res) == TYPE_DICTIONARY:
		_clean_channel(res)
	return res


func permissions_in(channel_id: String):
	# Permissions for the bot in a channel
	return permissions_for(user.id, channel_id)

#endregion



#region guilds

func get_guild_icon(guild_id: String, size: int = 256) -> PackedByteArray:
	assert(Helpers.is_valid_str(guild_id), 'Invalid Type: guild_id must be a valid String')

	var guild = guilds.get(str(guild_id))

	if not guild:
		push_error('Guild not found.')
		return PackedByteArray()

	if not guild.icon:
		push_error('Guild has no icon set.')
		return PackedByteArray()

	if size != 256:
		assert(size in GUILD_ICON_SIZES, 'Invalid size for guild icon provided')

	var png_bytes = await _send_get_cdn('/icons/%s/%s.png?size=%s' % [guild.id, guild.icon, size])
	return png_bytes


func get_guild_emojis(guild_id: String) -> Array:
	var res = await _send_get('/guilds/%s/emojis' % guild_id)
	return res


func get_guild_member(guild_id: String, member_id: String) -> Dictionary:
	var member = await _send_get('/guilds/%s/members/%s' % [guild_id, member_id])
	return member

#endregion



#region guild member

func remove_member_role(guild_id: String, user_id: String, role_id: String):
	var res = await _send_get('/guilds/%s/members/%s/roles/%s' % [guild_id, user_id, role_id], HTTPClient.METHOD_DELETE)
	return res


func add_member_role(guild_id: String, user_id: String, role_id: String):
	var res = await _send_request('/guilds/%s/members/%s/roles/%s' % [guild_id, user_id, role_id], {}, HTTPClient.METHOD_PUT)
	return res


func ban_member(guild_id: String, user_id: String, opts = {delete_message_seconds = 0}):
	var res = await _send_request('/guilds/%s/bans/%s' % [guild_id, user_id], opts, HTTPClient.METHOD_PUT)
	return res


func unban_member(guild_id: String, user_id: String):
	var res = await _send_request('/guilds/%s/bans/%s' % [guild_id, user_id], {}, HTTPClient.METHOD_DELETE)
	return res


func permissions_for(user_id: String, channel_id: String):
	# Permissions for a user in a channel
	if not channels.has(channel_id):
		push_error('Channel with the id' + channel_id + ' not found.')
		return Permissions.new(Permissions.new().ALL)

	var channel = channels[channel_id]
	var guild = guilds[channel.guild_id]

	# Check for guild owner
	if user_id == guild.owner_id:
		return Permissions.new(Permissions.new().ALL)

	# @everyone base role
	var permissions = Permissions.new(guild.roles[guild.id].permissions)
	if not guild.members.has(user_id):
		push_warning('Member not found in cached members. Make sure the GUILD_MEMBERS intent is setup.')
		return permissions

	var role_ids = guild.members[user_id].roles

	# Apply member global roles
	for role_id in role_ids:
		permissions.add(guild.roles[role_id].permissions)

	if permissions.has('ADMINISTRATOR'):
		return Permissions.new(Permissions.new().ALL)

	var overwrites = channel.permission_overwrites

	# Apply @everyone overwrite
	for overwrite in overwrites:
		if overwrite.id == guild.id:
			permissions.remove(overwrite.deny)
			permissions.add(overwrite.allow)
			break

	# Apply member roles overwrite
	for overwrite in overwrites:
		if overwrite.id in role_ids:
			permissions.remove(overwrite.deny)
	for overwrite in overwrites:
		if overwrite.id in role_ids:
			permissions.add(overwrite.allow)

	# Apply user overwrite
	for overwrite in overwrites:
		if overwrite.id == user_id:
			permissions.remove(overwrite.deny)
			permissions.add(overwrite.allow)
			break

	return permissions

#endregion



#region roles

func create_role(guild_id: String, p_opts: Dictionary):
	var opts = {
		name = "new role",
		permissions = Permissions.DEFAULT, # Permissions object
		color = 0,
		hoist = false,
		icon = null, # String
		unicode_emoji = null, # String
		mentionable = false
	}
	
	for key in p_opts:
		opts[key] = p_opts[key]
	
	if opts.permissions is Permissions:
		opts.permissions = opts.permissions.value_of()
	var res = await _send_request('/guilds/%s/roles' % [guild_id], opts, HTTPClient.METHOD_POST)
	return res


func update_role(guild_id: String, role_id: String, opts: Dictionary):
	if opts.has("permissions") and opts.permissions is Permissions:
		opts.permissions = opts.permissions.value_of()
	
	var res = await _send_request('/guilds/%s/roles/%s' % [guild_id, role_id], opts, HTTPClient.METHOD_PATCH)
	return res


func delete_role(guild_id: String, role_id: String):
	var res = await _send_request('/guilds/%s/roles/%s' % [guild_id, role_id], {}, HTTPClient.METHOD_DELETE)
	return res

#endregion



#region reactions

# ONLY custom emojis will work, pass in only the Id of the emoji to the custom_emoji
func create_reaction(messageordict, custom_emoji: String) -> int:
	assert(Helpers.is_valid_str(custom_emoji), 'Invalid Type: custom_emoji must be a String')
	custom_emoji = 'a:' + custom_emoji
	assert(messageordict is Message or typeof(messageordict) == TYPE_DICTIONARY, 'Invalid type: Expected a Message or Dictionary')

	if typeof(messageordict) == TYPE_DICTIONARY and messageordict.has('message_id'):
		messageordict.id = messageordict.message_id

	var status_code = await _send_get('/channels/%s/messages/%s/reactions/%s/@me' % [messageordict.channel_id, messageordict.id, custom_emoji], HTTPClient.METHOD_PUT, ['Content-Length:0'])
	return status_code


func delete_reaction(messageordict, custom_emoji: String, userid: String = '@me') -> int:
	assert(Helpers.is_valid_str(custom_emoji), 'Invalid Type: custom_emoji must be a String')
	custom_emoji = 'a:' + custom_emoji
	assert(messageordict is Message or typeof(messageordict) == TYPE_DICTIONARY, 'Invalid type: Expected a Message or Dictionary')

	if typeof(messageordict) == TYPE_DICTIONARY and messageordict.has('message_id'):
		messageordict.id = messageordict.message_id

	var status_code = await _send_get('/channels/%s/messages/%s/reactions/%s/%s' % [messageordict.channel_id, messageordict.id, custom_emoji, userid], HTTPClient.METHOD_DELETE, ['Content-Length:0'])

	return status_code


func delete_reactions(messageordict, custom_emoji = '') -> int:
	assert(messageordict is Message or typeof(messageordict) == TYPE_DICTIONARY, 'Invalid type: Expected a Message or Dictionary')
	if typeof(messageordict) == TYPE_DICTIONARY and messageordict.has('message_id'):
		messageordict.id = messageordict.message_id

	var status_code
	if custom_emoji != '':
		custom_emoji = 'a:' + custom_emoji
		status_code = await _send_get('/channels/%s/messages/%s/reactions/%s' % [messageordict.channel_id, messageordict.id, custom_emoji], HTTPClient.METHOD_DELETE, ['Content-Length:0'])
	else:
		status_code = await _send_get('/channels/%s/messages/%s/reactions' % [messageordict.channel_id, messageordict.id], HTTPClient.METHOD_DELETE, ['Content-Length:0'])

	return status_code


func get_reactions(messageordict, custom_emoji: String):
	assert(Helpers.is_valid_str(custom_emoji), 'Invalid Type: custom_emoji must be a String')
	custom_emoji = 'a:' + custom_emoji
	assert(messageordict is Message or typeof(messageordict) == TYPE_DICTIONARY, 'Invalid type: Expected a Message or Dictionary')
	if typeof(messageordict) == TYPE_DICTIONARY and messageordict.has('message_id'):
		messageordict.id = messageordict.message_id

	var ret = await _send_get('/channels/%s/messages/%s/reactions/%s' % [messageordict.channel_id, messageordict.id, custom_emoji])
	return ret

#endregion



#region commands

func register_command(command: ApplicationCommand, guild_id: String = '') -> ApplicationCommand:
	var slug = '/applications/%s' % application.id

	if Helpers.is_valid_str(guild_id):
		# Registering a guild command
		slug += '/guilds/%s' % guild_id

	slug += '/commands'
	var res = await _send_request(slug, command._to_dict(true))
	return ApplicationCommand.new(res)


func register_commands(commands: Array, guild_id: String = '') -> Array:
	for i in range(len(commands)):
		if commands[i] is ApplicationCommand:
			commands[i] = commands[i]._to_dict(true)

	var slug = '/applications/%s' % application.id

	if Helpers.is_valid_str(guild_id):
		# Registering guild commands
		slug += '/guilds/%s' % guild_id

	slug += '/commands'
	var res = await _send_request(slug, commands, HTTPClient.METHOD_PUT)
	if typeof(res) == TYPE_ARRAY:
		for i in range(len(res)):
			res[i] = ApplicationCommand.new(res[i])
	return res


func delete_command(command_id: String, guild_id: String = '') -> int:
	var slug = '/applications/%s' % application.id

	if Helpers.is_valid_str(guild_id):
		# Deleting a guild command
		slug += '/guilds/%s' % guild_id

	slug += '/commands/%s' % command_id
	var res = await _send_get(slug, HTTPClient.METHOD_DELETE)
	return res


func delete_commands(guild_id: String = '') -> int:
	var slug = '/applications/%s' % application.id

	if Helpers.is_valid_str(guild_id):
		# Deleting guild commands
		slug += '/guilds/%s' % guild_id

	slug += '/commands'
	var res = await _send_request(slug, [], HTTPClient.METHOD_PUT)
	return res


func get_command(command_id: String, guild_id: String = '') -> ApplicationCommand:
	var slug = '/applications/%s' % application.id

	if Helpers.is_valid_str(guild_id):
		# Getting a guild command
		slug += '/guilds/%s' % guild_id

	slug += '/commands/%s' % command_id

	var cmd = await _send_get(slug)
	cmd = ApplicationCommand.new(cmd)
	return cmd


func get_commands(guild_id: String = '') -> Array:
	var slug = '/applications/%s' % application.id

	if Helpers.is_valid_str(guild_id):
		# Getting guild commands
		slug += '/guilds/%s' % guild_id

	slug += '/commands'

	var cmds = await _send_get(slug)
	for i in range(len(cmds)):
		cmds[i] = ApplicationCommand.new(cmds[i])
	return cmds

#endregion


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

	var new_presence = {'status': 'online', 'afk': false, 'activity': {}}

	assert(p_options, 'Missing options for set_presence')
	assert(
		typeof(p_options) == TYPE_DICTIONARY,
		'Invalid Type: options in set_presence must be a Dictionary'
	)

	if p_options.has('status') and Helpers.is_valid_str(p_options.status):
		assert(
			str(p_options.status).to_upper() in PRESENCE_STATUS_TYPES,
			'Invalid Type: status must be one of PRESENCE_STATUS_TYPES'
		)
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
			new_presence.activity.created_at = Time.get_unix_time_from_system() * 1000

		if p_options.activity.has('type') and Helpers.is_valid_str(p_options.activity.type):
			assert(
				str(p_options.activity.type).to_upper() in ACTIVITY_TYPES,
				'Invalid Type: type must be one of ACTIVITY_TYPES'
			)
			new_presence.activity.type = ACTIVITY_TYPES[str(p_options.activity.type).to_upper()]

	_update_presence(new_presence)



#region Inbuilt Functions

func _ready() -> void:
	randomize()

	# Generate needed nodes
	_generate_timer_nodes()

	# Setup web socket client
	_client = WebSocketPeer.new()

	$HeartbeatTimer.timeout.connect(_send_heartbeat)


func _process(_delta) -> void:
	if not _client:
		return
	
	_client.poll()
	
	var state = _client.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			var packet = _client.get_packet()
			_data_received(packet.get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		_connection_closed(code, reason)
		set_process(false) # Stop processing.

#endregion



#region Private Functions


func _generate_timer_nodes() -> void:
	var heart_beat_timer = Timer.new()
	heart_beat_timer.name = 'HeartbeatTimer'
	add_child(heart_beat_timer)

	var invalid_session_timer = Timer.new()
	invalid_session_timer.name = 'InvalidSessionTimer'
	add_child(invalid_session_timer)


func _connection_closed(code: int, reason: String) -> void:
	if VERBOSE:
		print('WSS connection closed with code=%s, reason=%s' % [code, reason])


func _data_received(msg: String) -> void:
	#if VERBOSE:
		#print("Got packet: ", msg)
	var data := msg
	var dict = _jsonstring_to_dict(data)
	var op = str(int(dict.op))  # OP Code Received
	var d = dict.d  # Data Received
	
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
			timer.wait_time = randi_range(1, 5)
			timer.start()
		'0':
			# Event Dispatched
			_handle_events(dict)


func _send_heartbeat() -> void:  # Send heartbeat OP code 1
	if not _heartbeat_ack_received:
		_client.close(1002)
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

		'GUILD_CREATE':
			var guild = dict.d
			_clean_guilds([guild])
			# Update number of cached guilds
			if guild.has('lazy') and guild.lazy:
				guilds_loaded += 1
				if guilds_loaded == guilds.size():
					bot_ready.emit(self)

			if not guilds.has(guild.id):
				# Joined a new guild
				guild_create.emit(self, guild)

			# Update cache
			guilds[guild.id] = guild

		'GUILD_UPDATE':
			var guild = dict.d
			_clean_guilds([guild])
			guilds[guild.id] = guild
			guild_update.emit(self, guild)

		'GUILD_DELETE':
			var guild = dict.d
			guilds.erase(guild.id)
			guild_delete.emit(self, guild.id)

		# 'GUILD_MEMBER_ADD':
		# 	print('-----------guild member add')
		# 	var member = dict.d
		# 	print(member)

		# 'GUILD_MEMBER_UPDATE':
		# 	print('--------guild_member update')
		# 	var data = dict.d

		# 	var guild = guilds[data.guild_id]
		# 	data.erase('guild_id')

		# 	# Update users cache
		# 	var user = data.user
		# 	var user_id =  user.id
		# 	data.erase('user')
		# 	users[user_id] = user

		# 	if data.has('pending'):
		# 		var pending = data.pending
		# 		data.erase('pending')
		# 		data.is_pending = pending
		# 	guild.members[user_id] = data

		# 'GUILD_MEMBER_DELETE':
		# 	print('-----------guild member delete')
		# 	var member = dict.d
		# 	print(member)

		# 'GUILD_MEMBERS_CHUNK':
		# 	print('-----------guild member chunk')
		# 	var member = dict.d
		# 	print(member)


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

			var coroutine = await _parse_message(d)
			if coroutine == null:
				# message might be a thread
				# TODO: Handle sending messages in threads
				return

			d = Message.new(d)

			var channel = channels.get(str(d.channel_id))
			message_create.emit(self, d, channel)

		'MESSAGE_DELETE':
			var d = dict.d
			message_delete.emit(self, d)

		'MESSAGE_REACTION_ADD':
			var d = dict.d

			message_reaction_add.emit(self, d)

		'MESSAGE_REACTION_REMOVE':
			var d = dict.d
			message_reaction_remove.emit(self, d)

		'MESSAGE_REACTION_REMOVE_ALL':
			var d = dict.d
			message_reaction_remove_all.emit(self, d)

		'MESSAGE_REACTION_REMOVE_EMOJI':
			var d = dict.d
			message_reaction_remove_emoji.emit(self, d)

		'INTERACTION_CREATE':
			var d = dict.d

			var id = d.id
			var data = d.data
			var token = d.token

			var interaction = await DiscordInteraction.new(self, d)
			interaction_create.emit(self, interaction)


func _send_raw_request(slug: String, payload: Dictionary, method = HTTPClient.METHOD_POST):
	var headers = _headers.duplicate(true)
	var multipart_header = 'Content-Type: multipart/form-data; boundary="boundary"'
	if headers.find(multipart_header) == -1:
		headers.append(multipart_header)

	var http_client = HTTPClient.new()

	var body = PackedByteArray()

	# Add the payload_json to the form
	body.append_array('--boundary\r\n'.to_utf8_buffer())
	body.append_array('Content-Disposition: form-data; name="payload_json"\r\n'.to_utf8_buffer())
	body.append_array('Content-Type: application/json\r\n\r\n'.to_utf8_buffer())

	if payload.has('payload_json'):
		body.append_array(JSON.stringify(payload.payload_json).to_utf8_buffer())
	elif payload.has('payload'):
		body.append_array(JSON.stringify(payload.payload).to_utf8_buffer())

	var count = 0
	for file in payload.files:
		# Extract the name, media_type and data of each file
		var file_name = file.name
		var media_type = file.media_type
		var data = file.data
		# Add the file to the form
		body.append_array('\r\n--boundary\r\n'.to_utf8_buffer())
		body.append_array(
			('Content-Disposition: form-data; name="file' + str(count) + '"; filename="' + file_name + '"').to_utf8_buffer()
		)
		body.append_array(('\r\nContent-Type: ' + media_type + '\r\n\r\n').to_utf8_buffer())
		body.append_array(data)
		count += 1

	# End the form-data
	body.append_array('\r\n--boundary--'.to_utf8_buffer())
	var err = http_client.connect_to_host(_https_domain)
	assert(err == OK, 'Error connecting to Discord HTTPS server')

	while (
		http_client.get_status() == HTTPClient.STATUS_CONNECTING
		or http_client.get_status() == HTTPClient.STATUS_RESOLVING
	):
		http_client.poll()
		await get_tree().process_frame

	assert(
		http_client.get_status() == HTTPClient.STATUS_CONNECTED,
		'Could not connect to Discord HTTPS server'
	)
	err = http_client.request_raw(method, _api_slug + slug, headers, body)

	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		await get_tree().process_frame

	# Request is made, now extract the reponse body
	assert(
		(
			http_client.get_status() == HTTPClient.STATUS_BODY
			or http_client.get_status() == HTTPClient.STATUS_CONNECTED
		)
	)

	if http_client.has_response():
		headers = http_client.get_response_headers_as_dictionary()

		var rb = PackedByteArray()
		while http_client.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			http_client.poll()
			var chunk = http_client.read_response_body_chunk()
			if chunk.size() == 0:
				# Got nothing, wait for buffers to fill a bit.
				OS.delay_usec(1000)
			else:
				rb = rb + chunk  # Append to read buffer.

		var response = _jsonstring_to_dict(rb.get_string_from_utf8())
		if response == null:
			if http_client.get_response_code() == 204:
				return true
			return false
		if response.has('code'):
			print('Response: status code ', str(http_client.get_response_code()))
			print(JSON.stringify(response, '\t'))

		assert(not response.has('code'), 'Error sending request. See output window')

		if response.has('retry_after'):
			# We got ratelimited
			await get_tree().create_timer(int(response.retry_after)).timeout
			response = await _send_raw_request(slug, payload, method)

		return response
	else:
		assert(false, 'Unable to upload file. Got empty response from server')


func _send_request(slug: String, payload, method = HTTPClient.METHOD_POST):
	var headers = _headers.duplicate(true)

	var json_header = 'Content-Type: application/json'
	if headers.find(json_header) == -1:
		headers.append(json_header)

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request.call_deferred(
		_https_base + slug, headers, method, JSON.stringify(payload)
	)

	var data = await http_request.request_completed
	http_request.queue_free()

	# Check for errors
	assert(data[0] == HTTPRequest.RESULT_SUCCESS, 'Error sending request: HTTP Failed')
	var response = _jsonstring_to_dict(data[3].get_string_from_utf8())
	if response == null:
		if data[1] == 204:
			return true
		return false

	if response and response.has('code'):
		# Got an error
		print('Response: status code ', str(data[1]))
		print('Error: ' + JSON.stringify(response, '\t'))

	if method != HTTPClient.METHOD_DELETE:
		if response.has('code'):
			push_error('Error sending request. See output window')

	if response.has('retry_after'):
		# We got ratelimited
		await get_tree().create_timer(int(response.retry_after)).timeout
		response = await _send_request(slug, payload, method)

	return response


func _get_dm_channel(channel_id: String) -> Dictionary:
	assert(Helpers.is_valid_str(channel_id), 'Invalid Type: channel_id must be a valid String')
	var data = await _send_get('/channels/%s' % channel_id)
	if typeof(data) == TYPE_DICTIONARY:
		_clean_channel(data)
	return data


func _send_get(slug, method = HTTPClient.METHOD_GET, additional_headers = []):
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var headers = _headers + additional_headers
	http_request.request.call_deferred(_https_base + slug, headers, method)

	var data = await http_request.request_completed
	http_request.queue_free()

	assert(data[0] == HTTPRequest.RESULT_SUCCESS)
	if method == HTTPClient.METHOD_GET:
		var response = _jsonstring_to_dict(data[3].get_string_from_utf8())
		if response != null and response.has('code'):
			# Got an error
			print('GET: status code ', str(data[1]))
			print('Error sending GET request: ' + JSON.stringify(response, '\t'))
			push_error('Error sending GET request. See output window')
		return response

	else:  # Maybe a PUT/DELETE for reaction
		return data[1]


func _send_get_cdn(slug) -> PackedByteArray:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	if slug.find('/') == 0:
		http_request.request(_cdn_base + slug, _headers)
	else:
		http_request.request(slug, _headers)

	var data = await http_request.request_completed
	http_request.queue_free()

	# Check for errors
	assert(data[0] == HTTPRequest.RESULT_SUCCESS, 'Error sending GET cdn request: HTTP Failed')

	if data[1] != 200:
		print('HTTPS GET cdn Error: Status Code: %s' % data[1])
	assert(data[1] == 200, 'HTTPS GET cdn Error: Status code ' + str(data[1]))

	return data[3]


func _send_message_request(
	messageorchannelid, content, options := {}, method := HTTPClient.METHOD_POST
):
	var payload = {
		'content': null,
		'tts': false,
		'embeds': null,
		'components': null,
		'allowed_mentions': null,
		'message_reference': null
	}

	var slug
	if messageorchannelid is Message:
		slug ='/channels/%s/messages' % str(messageorchannelid.channel_id)
	else:
		assert(messageorchannelid.length() > 16, 'channel_id is not valid')
		slug = '/channels/%s/messages' % str(messageorchannelid)

	# Handle edit message or delete message
	if method == HTTPClient.METHOD_PATCH or method == HTTPClient.METHOD_DELETE:
		slug += '/' + str(messageorchannelid.id)

	if method == HTTPClient.METHOD_PATCH:
		if typeof(messageorchannelid) == TYPE_OBJECT and typeof(messageorchannelid.attachments) == TYPE_ARRAY:
			if messageorchannelid.attachments.size() == 0:
				payload.attachments = null
			else:
				# Add the attachments to keep to the payload
				payload.attachments = messageorchannelid.attachments

	# Check if the content is only a string
	if typeof(content) == TYPE_STRING and content.length() > 0:
		assert(content.length() <= 2048, 'Message content must be less than 2048 characters')
		payload.content = content

	elif typeof(content) == TYPE_DICTIONARY:  # Check if the content is the options dictionary
		options = content
		content = null

	# Parse the options
	if typeof(options) == TYPE_DICTIONARY:
		"""parse the message options - refer https://discord.com/developers/docs/resources/channel#create-message-jsonform-params
		options {
			tts: bool,
			embeds: Array,
			components: Array,
			files: Array,
			allowed_mentions: object,
			message_reference: object,
		}
		"""

		if options.has('content') and Helpers.is_str(options.content):
			assert(
				options.content.length() <= 2048,
				'Message content must be less than 2048 characters'
			)
			payload.content = options.content

		if options.has('tts') and options.tts:
			payload.tts = true

		if options.has('embeds') and options.embeds.size() > 0:
			for embed in options.embeds:
				if embed is Embed:
					if payload.embeds == null:
						payload.embeds = []
					payload.embeds.append(embed._to_dict())

		if options.has('components') and options.components.size() > 0:
			assert(
				options.components.size() <= 5,
				'Message can have a max of 5 MessageActionRow components.'
			)
			for component in options.components:
				assert(
					component is MessageActionRow, 'Parent component must be a MessageActionRow.'
				)
				if payload.components == null:
					payload.components = []
				payload.components.append(component._to_dict())

		if options.has('allowed_mentions') and options.allowed_mentions:
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

		if options.has('message_reference') and options.message_reference:
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
			assert(
				typeof(options.files) == TYPE_ARRAY,
				'Invalid Type: files in message options must be an array'
			)

			if options.files.size() > 0:
				# Loop through each file
				for file in options.files:
					assert(
						file.has('name') and Helpers.is_valid_str(file.name),
						'Missing name for file in files'
					)
					assert(
						file.has('media_type') and Helpers.is_valid_str(file.media_type),
						'Missing media_type for file in files'
					)
					assert(file.has('data') and file.data, 'Missing data for file in files')
					assert(
						file.data is PackedByteArray,
						'Invalid Type: data of file in files must be PackedByteArray'
					)

			var json_payload = payload.duplicate(true)
			var new_payload = {'files': options.files, 'payload_json': json_payload}
			payload = new_payload

	var res
	if payload.has('files') and payload.files and typeof(payload.files) == TYPE_ARRAY:
		# Send raw post request using multipart/form-data
		var coroutine = await _send_raw_request(slug, payload, method)
		if typeof(coroutine) == TYPE_OBJECT:
			res = await coroutine
		else:
			res = coroutine

	else:
		res = await _send_request(slug, payload, method)

	if method == HTTPClient.METHOD_DELETE:
		return res
	else:
		await _parse_message(res)
		
		if res.has("code") and res.has("errors"):
			# its an error
			return res

		var msg = Message.new(res)
		return msg


func _update_presence(new_presence: Dictionary) -> void:
	var status = new_presence.status
	var activity = new_presence.activity

	var response_d = {
		'op': 3,  # Presence update
	}
	response_d['d'] = {
		'since': new_presence if new_presence.has('since') else null,
		'status': new_presence.status,
		'afk': new_presence.afk,
		'activities': [new_presence.activity]
	}
	_send_dict_wss(response_d)


# Helper functions
func _jsonstring_to_dict(data: String):
	var json = JSON.new()
	var result = json.parse(data)
	
	if not data:
		return {}
	
	if result != OK:
		if VERBOSE:
			print("Failed to parse json: error at line %s with msg %s for data %s" % [json.get_error_line(), json.get_error_message(), data])
		return {}
	
	return json.data


func _setup_heartbeat_timer(interval: int) -> void:
	# Setup heartbeat timer and start it
	_heartbeat_interval = int(interval) / 1000
	var timer = $HeartbeatTimer
	timer.wait_time = _heartbeat_interval
	timer.start()


func _send_dict_wss(d: Dictionary) -> void:
	var payload = JSON.stringify(d)
	var err = _client.put_packet(payload.to_utf8_buffer())
	if OK != err:
		if VERBOSE:
			print("Failed to send packet: error=%s (%s)" % [error_string(err), err])


func _clean_guilds(guilds: Array) -> void:
	for guild in guilds:
		# Converts the unavailable property to available
		if guild.has('unavailable'):
			guild.available = not guild.unavailable
		else:
			guild.available = true
		guild.erase('unavailable')

		if guild.has('channels'):
			for channel in guild.channels:
				_clean_channel(channel)
				channel.guild_id = guild.id
				channels[channel.id] = channel

		if guild.has('members') and typeof(guild.members) == TYPE_ARRAY:
			# Parse the guild members
			var members = {}
			for member in guild.members:
				var member_id = member.user.id
				users[member_id] = member.user
				member.erase('user')
				members[member_id] = member
			guild.members = members

		if guild.has('roles') and typeof(guild.roles) == TYPE_ARRAY:
			# Parse the guild roles
			var roles = {}
			for role in guild.roles:
				var role_id = role.id
				role.erase('id')
				roles[role_id] = role
			guild.roles = roles


func _clean_channel(channel: Dictionary) -> void:
	_float_to_int(channel, "type")
	_float_to_int(channel, "flags")
	if channel.has('type') and typeof(channel.type) == TYPE_INT:
		channel.type = CHANNEL_TYPES.get(str(channel.type))


func _parse_message(message):
	if typeof(message) == TYPE_OBJECT and message is Message:
		return message
	
	if typeof(message) != TYPE_DICTIONARY:
		printerr("_parse_message error: Type of message must be dictionary")
		return null
	
	_float_to_int(message, "type")
	_float_to_int(message, "flags")

	if message.has('channel_id') and message.channel_id:
		# Check if channel is cached
		var channel = channels.get(str(message.channel_id))

		if not channel:
			# Try to check if it is a DM channel
			if VERBOSE:
				print('Fetching DM channel: %s from api' % message.channel_id)

			channel = await _get_dm_channel(message.channel_id)
			_clean_channel(channel)

			if channel and channel.has('type') and channel.type == 'DM':
				channels[str(message.channel_id)] = channel
			else:
				# not a valid channel, it might be a thread
				return null

	if message.has('author') and typeof(message.author) == TYPE_DICTIONARY:
		# get the cached author of the message
		message.author = User.new(self, message.author)

	return 1


func _float_to_int(dict, key):
	if dict.has(key) and typeof(dict[key]) == TYPE_FLOAT:
		dict[key] = int(dict[key])

#endregion
