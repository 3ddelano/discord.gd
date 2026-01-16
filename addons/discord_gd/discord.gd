## Main script for discord.gd plugin[br]
## Copyright 2021-present, Delano Lourenco[br]
## MIT License[br]
## [url=https://github.com/3ddelano/discord.gd]Github - discord.gd[/url]
class_name DiscordBot
extends Node
#
#
#
#
#region Constants

const Gateway = preload("./gateway.gd")

const DispatchEvents = Gateway.DispatchEvents

const GUILD_ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]

const ACTIVITY_TYPES = {'GAME': 0, 'STREAMING': 1, 'LISTENING': 2, 'WATCHING': 3, 'COMPETING': 5}

const PRESENCE_STATUS_TYPES = ['ONLINE', 'DND', 'IDLE', 'INVISIBLE', 'OFFLINE']

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

const BASE_DOMAIN = 'https://discord.com'

const API_PATH = '/api/v9'

const API_BASE_URL = BASE_DOMAIN + API_PATH

const CDN_BASE_URL = 'https://cdn.discordapp.com'

#endregion
#
#
#
#
#region Public Variables

var TOKEN: String
var VERBOSE: bool = false
var INTENTS: int = 513

## Websocket connection gateway
var gateway: Gateway

# Caches
var user: User
var application: Dictionary
var guilds = {}
var channels = {}
var users = {}

#endregion
#
#
#
#
#region Signals

signal bot_ready(bot) # bot: DiscordBot
signal guild_create(bot, guild) # bot: DiscordBot, guild: Dictionary
signal guild_update(bot, guild) # bot: DiscordBot, guild: Dictionary
signal guild_delete(bot, guild) # bot: DiscordBot, guild: Dictionary
signal message_create(bot, message, channel) # bot: DiscordBot, message: Message, channel: Dictionary
signal message_delete(bot, message) # bot: DiscordBot, message: Dictionary
signal interaction_create(bot, interaction) # bot: DiscordBot, interaction: DiscordInteraction
signal message_reaction_add(bot, data) # bot: DiscordBot, data: Dictionary
signal message_reaction_remove(bot, data) # bot: DiscordBot, data: Dictionary
signal message_reaction_remove_all(bot, data) # bot: DiscordBot, data: Dictionary
signal message_reaction_remove_emoji(bot, data) # bot: DiscordBot, data: Dictionary
# Looking for more events
# Check the bot.gateway.dispatch_event_received signal!

#endregion
#
#
#
#
#region Private Variables

var _headers: Array

# Count of the number of guilds initially loaded
var _guilds_loaded = 0

#endregion
#
#
#
#
#region Public Functions

func login() -> void:
	_log(func(): return "Logging in...")
	assert(TOKEN.length() > 10, 'ERROR: Unable to login. TOKEN attribute not set.')
	_headers = [
		'Authorization: Bot %s' % TOKEN,
		'User-Agent: discord.gd (https://github.com/3ddelano/discord.gd)'
	]

	var err = gateway.login()

	if err == ERR_INVALID_PARAMETER:
		_log_error(func(): return 'Failed to login: Invalid websocket url')
		return
	
	if err == ERR_ALREADY_IN_USE:
		_log_error(func(): return 'Failed to login: Already logged in or in-progress')
		return
	
	if err != OK:
		_log_error(func(): return 'Failed to login: %s (%s)' % [error_string(err), err])
		return

#endregion
#
#
#
#
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
#
#
#
#
#region threads

func start_thread(message: Message, thread_name: String, duration: int = 60 * 24) -> Dictionary:
	var payload = {'name': thread_name, 'auto_archive_duration': duration}
	var res = await _send_request(
		'/channels/%s/messages/%s/threads' % [message.channel_id, message.id], payload
	)

	return res

#endregion
#
#
#
#
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
	await _parse_message(res)
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
#
#
#
#
#region user

## Returns a [User] object or error Dictionary
func get_user(user_id: String):
	var user_dict = await _send_get("/users/%s" % user_id)
	if user_dict.has("id"):
		return User.new(self, user_dict)
	return user_dict


## See [method get_user]
func get_current_user():
	return await get_user("@me")


## user_data can have username, avatar and banner
## Returns a [User] object or error Dictionary
func update_current_user(user_data: Dictionary):
	var user_dict = await _send_request("/users/@me", user_data, HTTPClient.METHOD_PATCH)
	if user_dict.has("id"):
		return User.new(self, user_dict)
	return user_dict

#endregion
#
#
#
#
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


# Currently only available for tokens from user accounts
# See https://github.com/discord/discord-api-spec/commit/976faf177d21062f258b116bbbb41b50be24fc0f#diff-437c78467c84435ab6de7d67d8d16163c385b59ddf443e7e8e23ade116a89c90R7901
# Available options:
# - content: String - Add filter for messages containing specific text
# - author_id: String | Array[String] - Add filter for messages sent by a user
# - author_type: String | Array[String] : "user" | "bot" | "webhook" | "-user" | "-bot" | "-webhook" - Add filter for messages sent by a user, bot, or webhook (or exclude using the -user, -bot, or -webhook)
# - channel_id: String - Add filter for messages sent in a channel
# - mentions: String | Array[String] - Add filter for messages mentioning a specific user
# - mention_everyone: bool
# - contents: Array[String] - Add filter for messages containing specific strings
#
# - slop: int - Value from 0-100
# - mention_everyone: bool
# - pinned: bool - whether to only include pinned messages
# - cursor
# - has
# - link_hostname
# - embed_provider
# - embed_type
# - attachment_extension
# - attachment_filename
# - command_id: String
# - command_name: String
# - include_nsfw: bool
#
# - sort_by: "timestamp" | "relevance" - Default is timestamp
# - sort_order: "asc" | "desc" - Default is desc
# - offset: int - Default is 0
# - limit: int - Default is no limit
# - min_id: String
# - max_id: String
#
# Examples
# - Search msgs containing 'some text' - { content = "some text" }
#
# - Search msgs containing 'some text' and sent by user with id '123'  - { content = "some text", author_id = "123" }
#
# - Search msgs containing 'some text' sent in channel with id '234' - { content = "some text", channel_id = "234" }
#
# - Search msgs mentioning the user '456' - { mentions = "456" }
func search_guild_messages(guild_id: String, p_opts: Dictionary, p_user_token: String):
	var opts = {
		sort_by = "timestamp",
		sort_order = "desc",
		offset = 0,
	}
	
	for key in p_opts:
		opts[key] = p_opts[key]
	
	var client := HTTPClient.new()
	print(client.query_string_from_dict(opts))
	var headers = ["Authorization: %s" % p_user_token]
	return await _send_get('/guilds/%s/messages/search?%s' % [guild_id, client.query_string_from_dict(opts)], HTTPClient.METHOD_GET, headers)

#endregion
#
#
#
#
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
#
#
#
#
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
#
#
#
#
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
#
#
#
#
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


## [code]
## p_options:
##  - status: String - One of online, dnd, idle, invisible, offline (default online)
##  - afk: bool, whether or not the client is afk,
##  - activity:
##     - type: String - One of playing, streaming, listening, watching, custom, competing
##     - name: String, name of the presence,
##     - url: String, url of the presence,
##     - created_at: int, unix timestamp (in milliseconds) of when activity was added to user's session
## [/code]
func set_presence(p_options: Dictionary) -> void:
	var new_presence = {'status': 'online', 'afk': false, 'activity': {}}

	if p_options.has('status') and Helpers.is_valid_str(p_options.status):
		assert(
			str(p_options.status).to_upper() in PRESENCE_STATUS_TYPES,
			'Invalid Type: status must be one of ' + str(PRESENCE_STATUS_TYPES)
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


func trigger_typing_indicator(p_channel_id: String):
	var res = await _send_request('/channels/%s/typing' % [p_channel_id], {}, HTTPClient.METHOD_POST)
	return res

#endregion
#
#
#
#
#region Inbuilt Functions

func _ready() -> void:
	randomize()

	gateway = Gateway.new(self)
	gateway.name = "DiscordGateway"
	gateway.dispatch_event_received.connect(_on_dispatch_event_received)
	add_child(gateway)

#endregion
#
#
#
#
#region Private Functions

func _on_dispatch_event_received(event_name: String, data: Dictionary):
	match event_name:
		DispatchEvents.READY:
			_on_ready_event(data)
		DispatchEvents.GUILD_CREATE:
			_on_guild_create_event(data)
		DispatchEvents.GUILD_UPDATE:
			_on_guild_update_event(data)
		DispatchEvents.GUILD_DELETE:
			_on_guild_delete_event(data)
		DispatchEvents.GUILD_MEMBER_UPDATE:
			_on_guild_member_update_event(data)
		DispatchEvents.MESSAGE_CREATE:
			_on_message_create_event(data)
		DispatchEvents.MESSAGE_DELETE:
			_on_message_delete_event(data)
		DispatchEvents.MESSAGE_REACTION_ADD:
			_on_message_reaction_add_event(data)
		DispatchEvents.MESSAGE_REACTION_REMOVE:
			_on_message_reaction_remove_event(data)
		DispatchEvents.MESSAGE_REACTION_REMOVE_ALL:
			_on_message_reaction_remove_all_event(data)
		DispatchEvents.MESSAGE_REACTION_REMOVE_EMOJI:
			_on_message_reaction_remove_emoji_event(data)
		DispatchEvents.INTERACTION_CREATE:
			_on_interaction_create_event(data)


func _on_ready_event(data: Dictionary):
	_log(func(): return "Got ready event from Discord")

	application = data.application
	user = User.new(self, data.user)
	
	var _guilds = data.guilds
	_clean_guilds(_guilds)
	for guild in _guilds:
		guilds[guild.id] = guild


func _on_guild_create_event(guild: Dictionary) -> void:
	_clean_guilds([guild])
	
	# Update number of cached guilds
	if guild.has('lazy') and guild.lazy:
		_guilds_loaded += 1
		if _guilds_loaded == guilds.size():
			bot_ready.emit(self)

	if not guilds.has(guild.id):
		# Joined a new guild
		guild_create.emit(self, guild)

	# Update cache
	guilds[guild.id] = guild


func _on_guild_update_event(guild: Dictionary) -> void:
	_clean_guilds([guild])
	guilds[guild.id] = guild
	guild_update.emit(self, guild)


func _on_guild_delete_event(guild: Dictionary) -> void:
	guilds.erase(guild.id)
	guild_delete.emit(self, guild.id)


func _on_guild_member_update_event(member: Dictionary) -> void:
	var guild = guilds[member.guild_id]
	member.erase('guild_id')

	# Update users cache
	var guild_user = member.user
	var user_id = guild_user.id
	member.erase('user')
	users[user_id] = guild_user

	if member.has('pending'):
		var pending = member.pending
		member.erase('pending')
		member.is_pending = pending
	guild.members[user_id] = member


func _on_message_create_event(msg: Dictionary) -> void:
	# Dont respond to webhooks
	if msg.has('webhook_id') and msg.webhook_id:
		return

	if msg.has('sticker_items') and msg.sticker_items and typeof(msg.sticker_items) == TYPE_ARRAY:
		if msg.sticker_items.size() != 0:
			return

	await _parse_message(msg)

	var message = Message.new(msg, self)

	var channel = channels.get(str(message.channel_id))
	message_create.emit(self, message, channel)

func _on_message_delete_event(msg: Dictionary) -> void:
	message_delete.emit(self, msg)

func _on_message_reaction_add_event(data: Dictionary) -> void:
	message_reaction_add.emit(self, data)

func _on_message_reaction_remove_event(data: Dictionary) -> void:
	message_reaction_remove.emit(self, data)

func _on_message_reaction_remove_all_event(data: Dictionary) -> void:
	message_reaction_remove_all.emit(self, data)

func _on_message_reaction_remove_emoji_event(data: Dictionary) -> void:
	message_reaction_remove_emoji.emit(self, data)

func _on_interaction_create_event(data: Dictionary) -> void:
	var interaction = await DiscordInteraction.new(self, data)
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

	_log(func(): return "Sending raw request to Discord slug=%s, method=%d" % [slug, method])

	var err: int = http_client.connect_to_host(BASE_DOMAIN)
	if err != OK:
		_log_error(func(): return "Error connecting to Discord HTTPS server for slug=%s" % slug)
		return null

	while (
		http_client.get_status() == HTTPClient.STATUS_CONNECTING
		or http_client.get_status() == HTTPClient.STATUS_RESOLVING
	):
		http_client.poll()
		await get_tree().process_frame

	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		_log_error(func(): return "Could not connect to Discord HTTPS server for slug=%s" % slug)
		return null
	
	err = http_client.request_raw(method, API_PATH + slug, headers, body)

	while http_client.get_status() == HTTPClient.STATUS_REQUESTING:
		http_client.poll()
		await get_tree().process_frame

	# Request is made, now extract the reponse body
	if not http_client.has_response():
		_log_error(func(): return "Unable to upload file. Got empty response from server for slug=%s" % slug)
		return null
	
	if http_client.get_status() != HTTPClient.STATUS_BODY:
		if http_client.get_response_code() >= 200 and http_client.get_response_code() < 300:
			return true
		
		_log_error(func(): return "Could not get response body for slug=%s, response_code=%d" % [slug, http_client.get_response_code()])
		return false

	var rb = PackedByteArray()
	while http_client.get_status() == HTTPClient.STATUS_BODY:
		# While there is body left to be read
		http_client.poll()
		var chunk = http_client.read_response_body_chunk()
		if chunk.size() != 0:
			rb = rb + chunk # Append to read buffer.

	var response = _from_json(rb.get_string_from_utf8())
	if response == null:
		_log(func(): return "Got null response for slug=%s, response_code=%d" % [slug, http_client.get_response_code()])
		if http_client.get_response_code() >= 200 and http_client.get_response_code() < 300:
			return true
		return false
	if response.has("code"):
		_log(func(): return "Got error response for request with slug=%s. See output window" % slug)
		_log(func(): return "Response: status code %s" % str(http_client.get_response_code()))
		_log(func(): return "Error: " + JSON.stringify(response, "\t"))

	if response.has("retry_after"):
		# We got ratelimited
		_log(func(): return "Request got ratelimited for slug=%s, retrying after %d seconds" % [slug, int(response.retry_after)])
		await get_tree().create_timer(int(response.retry_after)).timeout
		return await _send_raw_request(slug, payload, method)

	return response


func _send_request(slug: String, payload, method = HTTPClient.METHOD_POST):
	var headers = _headers.duplicate(true)

	var json_header = "Content-Type: application/json"
	if headers.find(json_header) == -1:
		headers.append(json_header)

	_log(func(): return "Sending request for slug=%s, method=%d" % [slug, method])
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request.call_deferred(
		API_BASE_URL + slug, headers, method, JSON.stringify(payload)
	)

	var data = await http_request.request_completed
	http_request.queue_free()

	var send_res: int = data[0]
	var response_code: int = data[1]
	var response_body: PackedByteArray = data[3]
	
	if send_res != HTTPRequest.RESULT_SUCCESS:
		_log_error(func(): return "Failed to send request: Failed to connect to Discord HTTPS server for slug=%s" % slug)
		return null

	var response = _from_json(response_body.get_string_from_utf8())
	if response == null:
		_log(func(): return "Got null response for request with slug=%s, response_code=%s" % [slug, response_code])
		if response_code >= 200 and response_code < 300:
			return true
		return false

	if response.has("code"):
		# Got an error
		_log(func(): return "Got error response for request with slug=%s. See output window" % slug)
		_log(func(): return "Response code: %s" % response_code)
		_log(func(): return "Error: " + JSON.stringify(response, "\t"))

	if method != HTTPClient.METHOD_DELETE:
		if response.has("code"):
			_log_error(func(): return "Error sending request for slug=%s\n%s" % [slug, str(response)])

	if response.has("retry_after"):
		# We got ratelimited
		_log(func(): return "Request got ratelimited for slug=%s, retrying after %d seconds" % [slug, int(response.retry_after)])
		await get_tree().create_timer(int(response.retry_after)).timeout
		return await _send_request(slug, payload, method)

	return response


func _get_dm_channel(channel_id: String) -> Dictionary:
	assert(Helpers.is_valid_str(channel_id), "Invalid Type: channel_id must be a valid String")
	var data = await _send_get("/channels/%s" % channel_id)
	if typeof(data) == TYPE_DICTIONARY:
		_clean_channel(data)
	return data

func _send_get(slug: String, method = HTTPClient.METHOD_GET, additional_headers = []):
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var headers = _headers.duplicate()
	if additional_headers:
		for head in additional_headers:
			var split = head.split(":")
			if split.size() != 2:
				_log_error(func(): return "Invalid HTTP header: %s" % head)
				continue
			var key = split[0].strip_edges().to_lower()
			_remove_header_from_array(headers, key)
			headers.append(head)

	_log(func(): return "Sending HTTP request for slug=%s, method=%d" % [slug, method])
	http_request.request.call_deferred(API_BASE_URL + slug, headers, method)

	var data = await http_request.request_completed
	http_request.queue_free()

	var send_res: int = data[0]
	var response_code: int = data[1]
	var response_body: PackedByteArray = data[3]

	if send_res != HTTPRequest.RESULT_SUCCESS:
		_log(func(): return "Failed to send HTTP request for slug=%s, method=%d. Got result_code=%d" % [slug, method, send_res])
		return null
	
	if method == HTTPClient.METHOD_GET:
		var response = _from_json(response_body.get_string_from_utf8())
		if response != null and response.has('code'):
			# Got an error
			_log_error(func(): return "Method %d: status code %d" % [method, response_code])
			_log_error(func(): return "Error sending HTTP request method=%d: " % method + JSON.stringify(response, '\t'))
		return response

	else: # Maybe a PUT/DELETE for reaction
		return data[1]


func _send_get_cdn(slug) -> PackedByteArray:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	_log(func(): return "Sending GET CDN request for slug=%s" % slug)
	if slug.find('/') == 0:
		http_request.request(CDN_BASE_URL + slug, _headers)
	else:
		http_request.request(slug, _headers)

	var data = await http_request.request_completed
	http_request.queue_free()

	var send_res: int = data[0]
	var response_code: int = data[1]
	var response_body: PackedByteArray = data[3]

	# Check for errors
	if send_res != HTTPRequest.RESULT_SUCCESS:
		_log(func(): return "Failed to send GET CDN request: HTTP Failed")
		return PackedByteArray()

	if response_code != 200:
		_log(func(): return "HTTPS GET CDN Error: Status Code: %s" % response_code)
		return PackedByteArray()

	_log(func(): return "Got CDN response for slug=%s" % slug)
	return response_body


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
		slug = '/channels/%s/messages' % str(messageorchannelid.channel_id)
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
		if content.length() > 2048:
			_log(func(): return "Message content must be less than 2048 characters, trimming down excess.")
			content = content.substr(0, 2048)
		payload.content = content

	elif typeof(content) == TYPE_DICTIONARY: # Check if the content is the options dictionary
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

		if options.has("content") and Helpers.is_str(options.content):
			if options.content.length() > 2048:
				_log(func(): return "Message content must be less than 2048 characters, trimming down excess.")
				options.content = options.content.substr(0, 2048)
			payload.content = options.content

		if options.has("tts") and options.tts:
			payload.tts = true

		if options.has("embeds") and options.embeds.size() > 0:
			for embed in options.embeds:
				if embed is Embed:
					if payload.embeds == null:
						payload.embeds = []
					payload.embeds.append(embed._to_dict())

		if options.has("components") and options.components.size() > 0:
			if options.components.size() > 5:
				_log(func(): return "Message can have a max of 5 MessageActionRow components, trimming down excess.")
				options.components = options.components.substr(0, 5)
			for component in options.components:
				if component is not MessageActionRow:
					_log(func(): return "Parent component must be a MessageActionRow.")
				if payload.components == null:
					payload.components = []
				payload.components.append(component._to_dict())

		if options.has("allowed_mentions") and options.allowed_mentions:
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

		if options.has("message_reference") and options.message_reference:
			"""
			message_reference {
				message_id: id of originating msg,
				channel_id? *: optional
				guild_id?: optional
				fail_if_not_exists?: bool, whether to error
			}
			"""
			payload.message_reference = options.message_reference

		if options.has("files") and options.files:
			if typeof(options.files) != TYPE_ARRAY:
				_log(func(): return "Invalid Type: files in message options must be an array")
				return null

			if options.files.size() > 0:
				# Loop through each file
				for file in options.files:
					if not file.has('name') or not Helpers.is_valid_str(file.name):
						_log(func(): return "Missing name for file in files")
						return null

					if not file.has('media_type') or not Helpers.is_valid_str(file.media_type):
						_log(func(): return "Missing media_type for file in files")
						return null

					if not file.has('data') or not file.data:
						_log(func(): return "Missing data for file in files")
						return null

					if not (file.data is PackedByteArray):
						_log(func(): return "Invalid Type: data of file in files must be PackedByteArray")
						return null

			var json_payload = payload.duplicate(true)
			var new_payload = {
				files = options.files,
				payload_json = json_payload
			}
			payload = new_payload

	var res
	if payload.has("files") and payload.files and typeof(payload.files) == TYPE_ARRAY:
		# Send raw post request using multipart/form-data
		res = await _send_raw_request(slug, payload, method)
	else:
		res = await _send_request(slug, payload, method)

	if not res:
		return res
	
	if method == HTTPClient.METHOD_DELETE:
		return res
	else:
		await _parse_message(res)
		
		if res.has("code") and res.has("errors"):
			# its an error
			return res
		if not res.has("id"):
			return res

		var msg = Message.new(res)
		return msg


func _update_presence(new_presence: Dictionary) -> void:
	var status = new_presence.status
	var activity = new_presence.activity

	var payload = {
		op = 3, # Presence update
		d = {
			since = new_presence if new_presence.has('since') else null,
			status = new_presence.status,
			afk = new_presence.afk,
			activities = [new_presence.activity]
		}
	}
	gateway.send_payload(payload)


# Helper functions

# Convert JSON-string to a Godot type eg. Dictionary/Array/float/string
func _from_json(data: String) -> Variant:
	var json = JSON.new()
	var result = json.parse(data)
	
	if not data:
		return null
	
	if result != OK:
		_log_error(func(): return "Failed to parse json: Error at line %s with msg %s for data %s" % [json.get_error_line(), json.get_error_message(), data])
		return null
	
	return json.data


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


func _parse_message(message) -> void:
	if typeof(message) == TYPE_OBJECT and message is Message:
		return
	
	if typeof(message) != TYPE_DICTIONARY:
		_log_error(func(): return "_parse_message expeceted object of type Dictionary")
		return
	
	_float_to_int(message, "type")
	_float_to_int(message, "flags")

	if message.has("channel_id") and message.channel_id:
		# Check if channel is cached
		var channel = channels.get(str(message.channel_id))

		if not channel:
			# Try to check if it is a DM channel
			_log(func(): return "Fetching DM channel with id=%s from api" % message.channel_id)

			channel = await _get_dm_channel(message.channel_id)
			_clean_channel(channel)

			channels[str(message.channel_id)] = channel

	if message.has("author") and typeof(message.author) == TYPE_DICTIONARY:
		# Get the cached author of the message
		message.author = User.new(self, message.author)

	return


func _remove_header_from_array(headers: Array, key: String):
	for i in range(headers.size()):
		if headers[i].to_lower().begins_with(key + ": "):
			headers.remove_at(i)
			break


func _float_to_int(dict, key):
	if dict.has(key) and typeof(dict[key]) == TYPE_FLOAT:
		dict[key] = int(dict[key])


func _log(message_func: Callable) -> void:
	if VERBOSE:
		var message = str(message_func.call())
		var start = "[color=DARK_OLIVE_GREEN][DiscordBot][/color] "
		print_rich(start + ("\n" + start).join(message.split("\n")))

func _log_error(message_func: Callable) -> void:
	var message = str(message_func.call())
	var start = "[color=RED][DiscordBot][/color] "
	print_rich(start + ("\n" + start).join(message.split("\n")))

#endregion
