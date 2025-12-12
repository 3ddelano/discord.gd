extends Node


#region Enums
enum OpCodes {
	## (Receive) An event was dispatched.
	DISPATCH = 0,
	## (Send/Receive) Fired periodically by the client to keep the connection alive.
	HEARTBEAT = 1,
	## (Receive) You should attempt to reconnect and resume immediately.
	RECONNECT = 7,
	## (Receive) The session has been invalidated. You should reconnect and identify/resume accordingly.
	INVALID_SESSION = 9,
	## (Receive) Sent immediately after connecting, contains the heartbeat_interval to use.
	HELLO = 10,
	## (Receive) Sent in response to receiving a heartbeat to acknowledge that it has been received.
	HEARTBEAT_ACK = 11,

	## (Send) Starts a new session during the initial handshake.
	IDENTIFY = 2,
	## (Send) Update the client's presence.
	PRESENCE_UPDATE = 3,
	## (Send) Used to join/leave or move between voice channels.
	VOICE_STATE_UPDATE = 4,
	## (Send) Resume a previous session that was disconnected.
	RESUME = 6,
	## (Send) Request information about offline guild members in a large guild.
	REQUEST_GUILD_MEMBERS = 8,
	## (Send) Request information about soundboard sounds in a set of guilds.
	REQUEST_SOUNDBOARD_SOUNDS = 31,
}

enum CloseCodes {
	## We're not sure what went wrong. Try reconnecting?
	UNKNOWN_ERROR = 4000,
	## You sent an invalid Gateway opcode or an invalid payload for an opcode. Don't do that!
	UNKNOWN_OPCODE = 4001,
	## You sent an invalid payload to Discord. Don't do that!
	DECODE_ERROR = 4002,
	## You sent us a payload prior to identifying, or this session has been invalidated.
	NOT_AUTHENTICATED = 4003,
	## The account token sent with your identify payload is incorrect.
	AUTHENTICATION_FAILED = 4004,
	## You sent more than one identify payload. Don't do that!
	ALREADY_AUTHENTICATED = 4005,
	## The sequence sent when resuming the session was invalid. Reconnect and start a new session.
	INVALID_SEQ = 4007,
	## Woah nelly! You're sending payloads to us too quickly. Slow it down! You will be disconnected on receiving this.
	RATE_LIMITED = 4008,
	## Your session timed out. Reconnect and start a new one.
	SESSION_TIMED_OUT = 4009,
	## You sent us an invalid shard when identifying.
	INVALID_SHARD = 4010,
	## The session would have handled too many guilds - you are required to shard your connection in order to connect.
	SHARDING_REQUIRED = 4011,
	## You sent an invalid version for the gateway.
	INVALID_API_VERSION = 4012,
	## You sent an invalid intent for a Gateway Intent. You may have incorrectly calculated the bitwise value.
	INVALID_INTENTS = 4013,
	## You sent a disallowed intent for a Gateway Intent. You may have tried to specify an intent that you have not enabled or are not approved for.
	DISALLOWED_INTENTS = 4014,
}

const DispatchEvents = {
	## Defines the heartbeat interval
	HELLO = "HELLO",
	## Contains the initial state information
	READY = "READY",
	## Response to Resume
	RESUMED = "RESUMED",
	## Server is going away, client should reconnect to gateway and resume
	RECONNECT = "RECONNECT",
	## Application was rate limited for a gateway opcode
	RATE_LIMITED = "RATE_LIMITED",
	## Failure response to Identify or Resume or invalid active session
	INVALID_SESSION = "INVALID_SESSION",
	## Application command permissions were updated
	APPLICATION_COMMAND_PERMISSIONS_UPDATE = "APPLICATION_COMMAND_PERMISSIONS_UPDATE",
	## Auto Moderation rule was created
	AUTO_MODERATION_RULE_CREATE = "AUTO_MODERATION_RULE_CREATE",
	## Auto Moderation rule was updated
	AUTO_MODERATION_RULE_UPDATE = "AUTO_MODERATION_RULE_UPDATE",
	## Auto Moderation rule was deleted
	AUTO_MODERATION_RULE_DELETE = "AUTO_MODERATION_RULE_DELETE",
	## Auto Moderation rule was triggered and an action was executed (e.g. a message was blocked)
	AUTO_MODERATION_ACTION_EXECUTION = "AUTO_MODERATION_ACTION_EXECUTION",
	## New guild channel created
	CHANNEL_CREATE = "CHANNEL_CREATE",
	## Channel was updated
	CHANNEL_UPDATE = "CHANNEL_UPDATE",
	## Channel was deleted
	CHANNEL_DELETE = "CHANNEL_DELETE",
	## Message was pinned or unpinned
	CHANNEL_PINS_UPDATE = "CHANNEL_PINS_UPDATE",
	## Thread created, also sent when being added to a private thread
	THREAD_CREATE = "THREAD_CREATE",
	## Thread was updated
	THREAD_UPDATE = "THREAD_UPDATE",
	## Thread was deleted
	THREAD_DELETE = "THREAD_DELETE",
	## Sent when gaining access to a channel, contains all active threads in that channel
	THREAD_LIST_SYNC = "THREAD_LIST_SYNC",
	## Thread member for the current user was updated
	THREAD_MEMBER_UPDATE = "THREAD_MEMBER_UPDATE",
	## Some user(s) were added to or removed from a thread
	THREAD_MEMBERS_UPDATE = "THREAD_MEMBERS_UPDATE",
	## Entitlement was created
	ENTITLEMENT_CREATE = "ENTITLEMENT_CREATE",
	## Entitlement was updated or renewed
	ENTITLEMENT_UPDATE = "ENTITLEMENT_UPDATE",
	## Entitlement was deleted
	ENTITLEMENT_DELETE = "ENTITLEMENT_DELETE",
	## Lazy-load for unavailable guild, guild became available, or user joined a new guild
	GUILD_CREATE = "GUILD_CREATE",
	## Guild was updated
	GUILD_UPDATE = "GUILD_UPDATE",
	## Guild became unavailable, or user left/was removed from a guild
	GUILD_DELETE = "GUILD_DELETE",
	## Guild audit log entry was created
	GUILD_AUDIT_LOG_ENTRY_CREATE = "GUILD_AUDIT_LOG_ENTRY_CREATE",
	## User was banned from a guild
	GUILD_BAN_ADD = "GUILD_BAN_ADD",
	## User was unbanned from a guild
	GUILD_BAN_REMOVE = "GUILD_BAN_REMOVE",
	## Guild emojis were updated
	GUILD_EMOJIS_UPDATE = "GUILD_EMOJIS_UPDATE",
	## Guild stickers were updated
	GUILD_STICKERS_UPDATE = "GUILD_STICKERS_UPDATE",
	## Guild integration was updated
	GUILD_INTEGRATIONS_UPDATE = "GUILD_INTEGRATIONS_UPDATE",
	## New user joined a guild
	GUILD_MEMBER_ADD = "GUILD_MEMBER_ADD",
	## User was removed from a guild
	GUILD_MEMBER_REMOVE = "GUILD_MEMBER_REMOVE",
	## Guild member was updated
	GUILD_MEMBER_UPDATE = "GUILD_MEMBER_UPDATE",
	## Some user(s) were added to or removed from a guild
	GUILD_MEMBERS_CHUNK = "GUILD_MEMBERS_CHUNK",
	## Guild role was created
	GUILD_ROLE_CREATE = "GUILD_ROLE_CREATE",
	## Guild role was updated
	GUILD_ROLE_UPDATE = "GUILD_ROLE_UPDATE",
	## Guild role was deleted
	GUILD_ROLE_DELETE = "GUILD_ROLE_DELETE",
	## Guild scheduled event was created
	GUILD_SCHEDULED_EVENT_CREATE = "GUILD_SCHEDULED_EVENT_CREATE",
	## Guild scheduled event was updated
	GUILD_SCHEDULED_EVENT_UPDATE = "GUILD_SCHEDULED_EVENT_UPDATE",
	## Guild scheduled event was deleted
	GUILD_SCHEDULED_EVENT_DELETE = "GUILD_SCHEDULED_EVENT_DELETE",
	## User subscribed to a guild scheduled event
	GUILD_SCHEDULED_EVENT_USER_ADD = "GUILD_SCHEDULED_EVENT_USER_ADD",
	## User unsubscribed from a guild scheduled event
	GUILD_SCHEDULED_EVENT_USER_REMOVE = "GUILD_SCHEDULED_EVENT_USER_REMOVE",
	## Guild soundboard sound was created
	GUILD_SOUNDBOARD_SOUND_CREATE = "GUILD_SOUNDBOARD_SOUND_CREATE",
	## Guild soundboard sound was updated
	GUILD_SOUNDBOARD_SOUND_UPDATE = "GUILD_SOUNDBOARD_SOUND_UPDATE",
	## Guild soundboard sound was deleted
	GUILD_SOUNDBOARD_SOUND_DELETE = "GUILD_SOUNDBOARD_SOUND_DELETE",
	## Guild soundboard sounds were updated
	GUILD_SOUNDBOARD_SOUNDS_UPDATE = "GUILD_SOUNDBOARD_SOUNDS_UPDATE",
	## Sent when gaining access to a channel, contains all active threads in that channel
	SOUNDBOARD_SOUNDS = "SOUNDBOARD_SOUNDS",
	## Guild integration was created
	INTEGRATION_CREATE = "INTEGRATION_CREATE",
	## Guild integration was updated
	INTEGRATION_UPDATE = "INTEGRATION_UPDATE",
	## Guild integration was deleted
	INTEGRATION_DELETE = "INTEGRATION_DELETE",
	## User used an interaction, such as an Application Command
	INTERACTION_CREATE = "INTERACTION_CREATE",
	## Invite to a channel was created
	INVITE_CREATE = "INVITE_CREATE",
	## Invite to a channel was deleted
	INVITE_DELETE = "INVITE_DELETE",
	## Message was created
	MESSAGE_CREATE = "MESSAGE_CREATE",
	## Message was edited
	MESSAGE_UPDATE = "MESSAGE_UPDATE",
	## Message was deleted
	MESSAGE_DELETE = "MESSAGE_DELETE",
	## Multiple messages were deleted at once
	MESSAGE_DELETE_BULK = "MESSAGE_DELETE_BULK",
	## User reacted to a message
	MESSAGE_REACTION_ADD = "MESSAGE_REACTION_ADD",
	## User removed a reaction from a message
	MESSAGE_REACTION_REMOVE = "MESSAGE_REACTION_REMOVE",
	## All reactions were explicitly removed from a message
	MESSAGE_REACTION_REMOVE_ALL = "MESSAGE_REACTION_REMOVE_ALL",
	## All reactions for a given emoji were explicitly removed from a message
	MESSAGE_REACTION_REMOVE_EMOJI = "MESSAGE_REACTION_REMOVE_EMOJI",
	## User was updated
	PRESENCE_UPDATE = "PRESENCE_UPDATE",
	## Stage instance was created
	STAGE_INSTANCE_CREATE = "STAGE_INSTANCE_CREATE",
	## Stage instance was updated
	STAGE_INSTANCE_UPDATE = "STAGE_INSTANCE_UPDATE",
	## Stage instance was deleted or closed
	STAGE_INSTANCE_DELETE = "STAGE_INSTANCE_DELETE",
	## Premium App Subscription was created
	SUBSCRIPTION_CREATE = "SUBSCRIPTION_CREATE",
	## Premium App Subscription was updated
	SUBSCRIPTION_UPDATE = "SUBSCRIPTION_UPDATE",
	## Premium App Subscription was deleted
	SUBSCRIPTION_DELETE = "SUBSCRIPTION_DELETE",
	## User started typing in a channel
	TYPING_START = "TYPING_START",
	## Properties about the user changed
	USER_UPDATE = "USER_UPDATE",
	## Someone sent an effect in a voice channel the current user is connected to
	VOICE_CHANNEL_EFFECT_SEND = "VOICE_CHANNEL_EFFECT_SEND",
	## Someone joined, left, or moved a voice channel
	VOICE_STATE_UPDATE = "VOICE_STATE_UPDATE",
	## Guild's voice server was updated
	VOICE_SERVER_UPDATE = "VOICE_SERVER_UPDATE",
	## Guild channel webhook was created, update, or deleted
	WEBHOOKS_UPDATE = "WEBHOOKS_UPDATE",
	## User voted on a poll
	MESSAGE_POLL_VOTE_ADD = "MESSAGE_POLL_VOTE_ADD",
	## User removed a vote on a poll
	MESSAGE_POLL_VOTE_REMOVE = "MESSAGE_POLL_VOTE_REMOVE",
}
#endregion




#region Enums
signal packet_received(data: Dictionary)
signal dispatch_event_received(event_name: String, data: Dictionary)
#endregion




#region Constants
const GATEWAY_URL_BASE = 'wss://gateway.discord.gg/'
const GATEWAY_URL_PARAMS = '?v=9&encoding=json'

const RECONNECTABLE_CLOSE_CODES = [
	CloseCodes.UNKNOWN_ERROR,
	CloseCodes.UNKNOWN_OPCODE,
	CloseCodes.DECODE_ERROR,
	CloseCodes.NOT_AUTHENTICATED,
	CloseCodes.ALREADY_AUTHENTICATED,
	CloseCodes.INVALID_SEQ,
	CloseCodes.RATE_LIMITED,
	CloseCodes.SESSION_TIMED_OUT,
]
#endregion




#region Public Variables
## Whether to print verbose debug messages
var VERBOSE := false
#endregion




#region Private Variables
var _client: WebSocketPeer
var _session_id: String
var _last_seq: int = -1
var _resume_gateway_url: String
var _bot: DiscordBot
var _heartbeat_timer: Timer
var _heartbeat_interval: int
var _heartbeat_ack_received := true
var _heartbeat_sent_at: int
var _latencies = [] # list of past 10 latencies
var latency: float
#endregion




func _init(bot) -> void:
	_bot = bot
	_client = WebSocketPeer.new()
	_client.inbound_buffer_size = 4 * 1024 * 1024
	_client.outbound_buffer_size = 4 * 1024 * 1024

func _ready() -> void:
	_heartbeat_timer = Timer.new()
	add_child(_heartbeat_timer)
	_heartbeat_timer.timeout.connect(_heartbeat_timer_timeout)

func _process(_delta: float) -> void:
	_client.poll()
	
	var state = _client.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			var packet = _client.get_packet()
			_packet_received(packet.get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		set_process(false)
		_connection_closed(code, reason)




func login() -> Error:
	set_process(true)
	return _client.connect_to_url(GATEWAY_URL_BASE + GATEWAY_URL_PARAMS)


func send_payload(data: Dictionary) -> void:
	if _client.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_log(func(): return "Failed to send packet, invalid ws state=(%d)" % _client.get_ready_state())
		return
	
	var payload = JSON.stringify(data)
	var err = _client.put_packet(payload.to_utf8_buffer())
	if OK != err:
		_log(func(): return "Failed to send packet: error=%s (%s)" % [error_string(err), err])



#region Private methods

func _packet_received(packet: String) -> void:
	var dict = _bot._from_json(packet)
	if not dict or not dict.has("op"):
		printerr("[DiscordGateway] Failed to parse packet: " + packet)
		return

	var op = int(dict.op)  # OP Code Received
	var d = dict.d  # Data Received
	
	_log(func (): return "\nGot packet with op=%s (%d)" % [OpCodes.find_key(op), op])
	_log(func ():
		if op == OpCodes.DISPATCH:
			return ""
		return packet)
	
	packet_received.emit(dict)
	
	match op:
		OpCodes.DISPATCH:
			_dispatch_received(dict)
		OpCodes.HEARTBEAT:
			_heartbeat_received()
		OpCodes.RECONNECT:
			_resume()
		OpCodes.INVALID_SESSION:
			_invalid_session_received(d)
		OpCodes.HELLO:
			_hello_received(d)
		OpCodes.HEARTBEAT_ACK:
			_heartbeat_acked_received()
		_:
			_log(func(): return "Unhandled op code %s (%d)" % [OpCodes.find_key(op), op])

func _dispatch_received(packet: Dictionary) -> void:
	# Track sequence
	if packet.has("s") and packet.s != null:
		_last_seq = int(packet.s)
	
	var event_name: String = packet.t
	var event_data: Dictionary = packet.d
	
	_log(func(): return "Got dispatch event=%s" % event_name)
	_log(func():
		if event_name == DispatchEvents.GUILD_CREATE:
			return ""
		return event_data)
	

	match event_name:
		DispatchEvents.READY:
			_ready_event(event_data)

	dispatch_event_received.emit(event_name, event_data)

#endregion




#region dispatch event handling

func _ready_event(data: Dictionary):
	_session_id = data.get("session_id", "")
	_resume_gateway_url = data.get("resume_gateway_url", "")


#endregion




#region hello packet handling

func _hello_received(data: Dictionary) -> void:
	_heartbeat_interval = _calculate_heartbeat_secs(data.heartbeat_interval)
	_log(func(): return "Heartbeat interval: %d" % _heartbeat_interval)

	# Start heartbeat timer
	_heartbeat_timer.wait_time = _heartbeat_interval
	_heartbeat_timer.start()
	_send_heartbeat()

	if _session_id:
		_resume()
	else:
		_log(func(): return "Sending new session (identify)")
		send_payload(_make_identify_payload())

func _calculate_heartbeat_secs(interval: int) -> int:
	return (int(interval) / 1000) - 2

func _make_resume_payload() -> Dictionary:
	var seq = null
	if _last_seq != -1:
		seq = _last_seq
	return {
		op = OpCodes.RESUME,
		d = {
			token = _bot.TOKEN,
			session_id = _session_id,
			seq = seq
		}
	}

func _make_identify_payload() -> Dictionary:
	return {
		op = OpCodes.IDENTIFY,
		d = {
			token = _bot.TOKEN,
			intents = _bot.INTENTS,
			properties = {
				"os" = OS.get_name().to_lower(),
				"browser" = "discord.gd",
				"device" = "discord.gd"
			}
		}
	}

#endregion




#region heartbeat handling

func _heartbeat_received() -> void:
	_send_heartbeat()

func _heartbeat_acked_received() -> void:
	_track_latency(Time.get_ticks_msec() - _heartbeat_sent_at)
	_heartbeat_ack_received = true
	_log(func(): return 'Heartbeat ack received at ' + str(Time.get_unix_time_from_system()))

func _heartbeat_timer_timeout() -> void:
	if not _heartbeat_ack_received:
		_log(func(): return "Closing WS because didnt receive heartbeat ack")
		_client.close(1002)
		return

	_send_heartbeat()

func _send_heartbeat() -> void:
	var seq = null
	if _last_seq != -1:
		seq = _last_seq

	var payload = {
		op = OpCodes.HEARTBEAT,
		d = seq
	}
	_heartbeat_sent_at = Time.get_ticks_msec()
	send_payload(payload)
	_heartbeat_ack_received = false
	_log(func(): return 'Sent heartbeat at ' + str(Time.get_unix_time_from_system()))

#endregion




#region connection closed

func _connection_closed(code: int, reason: String) -> void:
	_log(func(): return 'WS Connection closed with code=%d, reason=%s' % [code, reason])
	
	_heartbeat_timer.stop()
	
	if code in RECONNECTABLE_CLOSE_CODES:
		_resume()
		return
	
	_log(func(): return "Trying to reconnect")
	var err = login()
	if err != OK:
		_log(func(): return "Failed to login with code %d" % err)

func _resume():
	_log(func(): return "Trying to resume")

	var can_resume = true
	if not _session_id or _last_seq == -1:
		can_resume = false
	
	if not can_resume:
		_log(func(): return "Could not resume because of missing values. session_id=%s, last_seq=%d" % [_session_id, _last_seq])
		_log(func(): return "Will try to re-login")
		login()
		return

	
	if _client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_log(func(): return "Sending resume with session_id=%s, seq=%d" % [_session_id, _last_seq])
		send_payload(_make_resume_payload())
	else:
		set_process(true)
		var resume_url = _resume_gateway_url + GATEWAY_URL_PARAMS if _resume_gateway_url.ends_with("/") else _resume_gateway_url + "/" + GATEWAY_URL_PARAMS
		_log(func(): return "Connecting to resume_gateway_url=%s" % [resume_url])
		_client.connect_to_url(resume_url)
		

func _invalid_session_received(should_resume: bool):
	if should_resume:
		_resume()
	else:
		_log(func(): return "Got invalid session which cannot be resumed")
	pass

#endregion




#region common

func _track_latency(p_latency: int):
	_latencies.push_back(p_latency)
	while _latencies.size() > 10:
		_latencies.pop_front()
	
	# calc avg
	var sum = 0.0
	for l in _latencies:
		sum += l
	var avg = sum / _latencies.size()
	latency = avg
	_log(func(): return "Latency is %.2f ms" % avg)
	
	

func _log(message_func: Callable) -> void:
	if VERBOSE:
		var message = str(message_func.call())
		var start = "[color=CADET_BLUE][DiscordGateway][/color] "
		print_rich(start + ("\n"+start).join(message.split("\n")))

#endregion
