extends Node


#region Enums
enum VoiceOpCodes {
	## (Send) Begin a voice websocket connection.
	IDENTIFY = 0,
	## (Send) Select the voice protocol.
	SELECT_PROTOCOL = 1,
	## (Receive) Complete the websocket handshake.
	READY = 2,
	## (Send) Keep the websocket connection alive.
	HEARTBEAT = 3,
	## (Receive) Describe the session.
	SESSION_DESCRIPTION = 4,
	## (Send/Receive) Indicate which users are speaking.
	SPEAKING = 5,
	## (Receive) Sent to acknowledge a received client heartbeat.
	HEARTBEAT_ACK = 6,
	## (Send) Resume a connection.
	RESUME = 7,
	## (Receive) Time to wait between sending heartbeats in milliseconds.
	HELLO = 8,
	## (Receive) Acknowledge a successful session resume.
	RESUMED = 9,
	## (Receive) A client has connected to the voice channel.
	CLIENT_CONNECT = 12,
	## (Receive) A client has disconnected from the voice channel.
	CLIENT_DISCONNECT = 13,
}

enum VoiceCloseCodes {
	## You sent an invalid opcode.
	UNKNOWN_OPCODE = 4001,
	## You sent an invalid payload in your identifying to the Gateway.
	DECODE_ERROR = 4002,
	## You sent a payload before identifying with the Gateway.
	NOT_AUTHENTICATED = 4003,
	## The token you sent in your identify payload is incorrect.
	AUTHENTICATION_FAILED = 4004,
	## You sent more than one identify payload.
	ALREADY_AUTHENTICATED = 4005,
	## Your session is no longer valid.
	SESSION_NO_LONGER_VALID = 4006,
	## Your session has timed out.
	SESSION_TIMEOUT = 4009,
	## We can't find the server you're trying to connect to.
	SERVER_NOT_FOUND = 4011,
	## We didn't recognize the protocol you sent.
	UNKNOWN_PROTOCOL = 4012,
	## Channel was deleted, you were kicked, voice server changed, or the main gateway session was dropped.
	DISCONNECTED = 4014,
	## The server crashed. Our bad! Try resuming.
	VOICE_SERVER_CRASHED = 4015,
	## We didn't recognize your encryption.
	UNKNOWN_ENCRYPTION_MODE = 4016,
}

## Speaking flags
enum SpeakingFlags {
	## Normal transmission of voice audio.
	MICROPHONE = 1,
	## Transmission of context audio for video, no speaking indicator.
	SOUNDSHARE = 2,
	## Priority speaker, lowering audio of other speakers.
	PRIORITY = 4,
}
#endregion


#region Signals
## Emitted when the voice gateway connection is ready
signal voice_ready(ssrc: int, ip: String, port: int, modes: Array)
## Emitted when the session description is received
signal session_description_received(mode: String, secret_key: PackedByteArray)
## Emitted when a user's speaking state changes
signal speaking_state_changed(user_id: String, ssrc: int, speaking: int)
## Emitted when voice gateway packet is received
signal packet_received(data: Dictionary)
## Emitted when the voice connection is closed
signal voice_closed(code: int, reason: String)
## Emitted when a client connects to the voice channel
signal client_connected(user_id: String, ssrc: int)
## Emitted when a client disconnects from the voice channel
signal client_disconnected(user_id: String)
## Emitted when UDP connection is ready for audio
signal udp_ready(external_ip: String, external_port: int)
#endregion


#region Constants
const VOICE_GATEWAY_VERSION = 8

const RECONNECTABLE_CLOSE_CODES = [
	VoiceCloseCodes.VOICE_SERVER_CRASHED,
]

## Preferred encryption mode
const PREFERRED_MODE = "aead_xchacha20_poly1305_rtpsize" # Required for V8, xsalsa20_poly1305 deprecated
#endregion


#region Public Variables
## Whether to print verbose debug messages
var VERBOSE := false
#endregion


#region Private Variables
var _client: WebSocketPeer
var _heartbeat_timer: Timer
var _heartbeat_interval: int
var _got_heartbeat_ack := true
var _heartbeat_sent_at: int
var _nonce: int = 0
var _last_seq_ack: int = -1 # V8: Track last sequence number received from server

# Connection info
var _token: String
var _session_id: String
var _server_id: String # guild_id or channel_id for DM
var _user_id: String
var _endpoint: String

# Voice session info
var _ssrc: int
var _voice_ip: String
var _voice_port: int
var _modes: Array
var _secret_key: PackedByteArray
var _selected_mode: String

# State
var _is_connected := false
var _is_speaking := false

# UDP Client (C++ GDExtension)
var _udp_client#: VoiceUDPClient
var _external_ip: String
var _external_port: int
#endregion


func _ready() -> void:
	_client = WebSocketPeer.new()
	_client.inbound_buffer_size = 1024 * 1024
	_client.outbound_buffer_size = 1024 * 1024
	_heartbeat_timer = Timer.new()
	add_child(_heartbeat_timer)
	_heartbeat_timer.timeout.connect(_heartbeat_timer_timeout)


var _process_log_counter = 0

func _process(_delta: float) -> void:
	if not _is_connected:
		return
	
	_client.poll()
	
	var state = _client.get_ready_state()
	
	# Debug log every 200 frames (about once per second)
	_process_log_counter += 1
	if _process_log_counter >= 2000:
		_process_log_counter = 0
		print("[DiscordVoice DEBUG] _process: state=%d, packets=%d" % [state, _client.get_available_packet_count()])
	
	if state == WebSocketPeer.STATE_OPEN:
		while _client.get_available_packet_count():
			var packet = _client.get_packet()
			_packet_received(packet.get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = _client.get_close_code()
		var reason = _client.get_close_reason()
		_connection_closed(code, reason)


#region Public Methods

## Connect to a voice gateway endpoint
## [param endpoint]: The voice server endpoint (without wss:// prefix)
## [param token]: The voice connection token
## [param session_id]: The session ID from the main gateway
## [param server_id]: The guild ID (or channel ID for DMs)
## [param user_id]: The current user's ID
func connect_to_voice(endpoint: String, token: String, session_id: String, server_id: String, user_id: String) -> Error:
	_token = token
	_session_id = session_id
	_server_id = server_id
	_user_id = user_id
	
	# Clean up endpoint - remove trailing port if present and add wss://
	_endpoint = endpoint.replace(":443", "")
	var url = "wss://%s/?v=%d" % [_endpoint, VOICE_GATEWAY_VERSION]
	
	_log(func(): return "Connecting to voice gateway: %s" % url)
	
	_is_connected = true
	set_process(true)
	return _client.connect_to_url(url)


## Disconnect from the voice gateway
func disconnect_from_voice() -> void:
	_log(func(): return "Disconnecting from voice gateway")
	_heartbeat_timer.stop()
	_is_connected = false
	_is_speaking = false
	set_process(false)
	
	if _client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_client.close(1000, "Normal closure")


## Set speaking state
## [param speaking]: Speaking flags (use SpeakingFlags enum)
## [param delay]: Speaking delay in milliseconds (usually 0)
func set_speaking(speaking: int = SpeakingFlags.MICROPHONE, delay: int = 0) -> void:
	if not _is_connected:
		return
	
	_is_speaking = speaking > 0
	send_payload(_make_speaking_payload(speaking, delay))


## Send a payload to the voice gateway
func send_payload(data: Dictionary) -> void:
	if _client.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_log(func(): return "Failed to send voice packet, invalid ws state=(%d)" % _client.get_ready_state())
		return
	
	var payload = JSON.stringify(data)
	print("[DiscordVoice DEBUG] <<< Sending payload: ", payload)
	var err = _client.send_text(payload) # Use send_text instead of put_packet
	if OK != err:
		_log(func(): return "Failed to send voice packet: error=%s (%s)" % [error_string(err), err])


## Get connection state
func is_voice_connected() -> bool:
	return _is_connected and _client.get_ready_state() == WebSocketPeer.STATE_OPEN


## Get SSRC (Synchronization Source) for this connection
func get_ssrc() -> int:
	return _ssrc


## Get voice server IP
func get_voice_ip() -> String:
	return _voice_ip


## Get voice server port
func get_voice_port() -> int:
	return _voice_port


## Check if UDP is ready for audio transmission
func is_udp_ready() -> bool:
	return _udp_client != null and _udp_client.is_connected() and _secret_key.size() > 0


## Get the UDP client for direct access
func get_udp_client():# -> VoiceUDPClient:
	return _udp_client


## Send a frame of audio data
## [param pcm_data]: 16-bit signed integer PCM, stereo (2 channels), 48kHz
## Frame should be 20ms = 960 samples * 2 channels * 2 bytes = 3840 bytes
## Returns a godot Error enum
func send_audio_frame(pcm_data: PackedByteArray):
	if not is_udp_ready():
		return ERR_UNCONFIGURED
	return _udp_client.send_audio_frame(pcm_data)


## Send silence frames to indicate end of speaking
func send_silence() -> void:
	if _udp_client:
		_udp_client.send_silence_frames()

#endregion


#region Packet Handling

func _packet_received(packet_str: String) -> void:
	print("[DiscordVoice DEBUG] >>> Received packet: ", packet_str.substr(0, 200))
	var dict = JSON.parse_string(packet_str)
	if not dict or not dict.has("op"):
		printerr("[DiscordVoice] Failed to parse packet: " + packet_str)
		return
	
	var op = int(dict.op)
	var d = dict.get("d", {})
	
	# V8: Track sequence number from server messages for seq_ack in heartbeats
	if dict.has("seq"):
		_last_seq_ack = int(dict.seq)
		print("[DiscordVoice DEBUG] >>> Updated seq_ack to: %d" % _last_seq_ack)
	
	print("[DiscordVoice DEBUG] >>> Opcode: %d (%s)" % [op, VoiceOpCodes.find_key(op) if VoiceOpCodes.find_key(op) else "UNKNOWN"])
	
	_log(func(): return "\nGot voice packet with op=%s (%d)" % [VoiceOpCodes.find_key(op), op])
	_log(func(): return packet_str if op != VoiceOpCodes.HEARTBEAT_ACK else "")
	
	packet_received.emit(dict)
	
	match op:
		VoiceOpCodes.READY:
			_ready_received(d)
		VoiceOpCodes.SESSION_DESCRIPTION:
			_session_description_received(d)
		VoiceOpCodes.SPEAKING:
			_speaking_received(d)
		VoiceOpCodes.HEARTBEAT_ACK:
			_on_heartbeat_ack_received()
		VoiceOpCodes.HELLO:
			_hello_received(d)
		VoiceOpCodes.RESUMED:
			_log(func(): return "Voice session resumed successfully")
		VoiceOpCodes.CLIENT_CONNECT:
			_client_connect_received(d)
		VoiceOpCodes.CLIENT_DISCONNECT:
			_client_disconnect_received(d)
		_:
			_log(func(): return "Unhandled voice op code %s (%d)" % [VoiceOpCodes.find_key(op), op])

#endregion


#region Hello Packet Handling

func _hello_received(data: Dictionary) -> void:
	print("[DiscordVoice DEBUG] _hello_received called with data: ", data)
	var raw_interval = int(data.heartbeat_interval)
	_heartbeat_interval = _calculate_heartbeat_secs(raw_interval)
	print("[DiscordVoice DEBUG] Raw heartbeat_interval=%dms, using %d seconds" % [raw_interval, _heartbeat_interval])
	_log(func(): return "Voice HELLO received. Raw heartbeat_interval=%dms, using %d seconds" % [raw_interval, _heartbeat_interval])
	
	# Start heartbeat timer (don't send first heartbeat until identify is sent)
	_heartbeat_timer.wait_time = _heartbeat_interval
	_heartbeat_timer.start()
	
	# Send identify first, then send heartbeat
	print("[DiscordVoice DEBUG] Sending voice IDENTIFY")
	_log(func(): return "Sending voice IDENTIFY")
	send_payload(_make_identify_payload())
	
	# Send first heartbeat after a short delay to let identify go through
	print("[DiscordVoice DEBUG] Creating timer for first heartbeat...")
	get_tree().create_timer(0.5).timeout.connect(func():
		print("[DiscordVoice DEBUG] Timer fired, sending first heartbeat")
		_log(func(): return "Sending first heartbeat after identify")
		_send_heartbeat()
	)


func _calculate_heartbeat_secs(interval: int) -> int:
	# Use 75% of the interval to be safe, minimum 5 seconds
	return max(5, int(float(interval) * 0.75 / 1000.0))

#endregion


#region Ready Packet Handling

func _ready_received(data: Dictionary) -> void:
	_ssrc = int(data.ssrc)
	_voice_ip = data.ip
	_voice_port = int(data.port)
	_modes = data.modes
	
	_log(func(): return "Voice ready: ssrc=%d, ip=%s, port=%d" % [_ssrc, _voice_ip, _voice_port])
	_log(func(): return "Available modes: %s" % str(_modes))
	
	voice_ready.emit(_ssrc, _voice_ip, _voice_port, _modes)
	
	# Initialize UDP client in deferred call to avoid blocking heartbeat
	call_deferred("_setup_udp_client")


func _setup_udp_client() -> void:
	if not ClassDB.class_exists("VoiceUDPClient"):
		_log_error(func(): return "VoiceUDPClient not available (GDExtension is required for voice feature). UDP voice disabled.")
		if _modes.size() > 0:
			_selected_mode = _modes[0]
		return
	
	_udp_client = ClassDB.instantiate("VoiceUDPClient")
	var err = _udp_client.connect_to_server(_voice_ip, _voice_port)
	if err != OK:
		_log(func(): return "Failed to connect UDP client: %s" % error_string(err))
		return
	
	_log(func(): return "UDP client connected, performing IP discovery...")
	var discovery_result = _udp_client.perform_ip_discovery(_ssrc)
	
	if not discovery_result.has("ip") or not discovery_result.has("port"):
		_log(func(): return "IP Discovery failed")
		return
	
	_external_ip = discovery_result.ip
	_external_port = discovery_result.port
	_log(func(): return "IP Discovery success: %s:%d" % [_external_ip, _external_port])
	
	# Select the best available encryption mode
	_selected_mode = PREFERRED_MODE if PREFERRED_MODE in _modes else _modes[0]
	_udp_client.set_ssrc(_ssrc)
	
	# Send SELECT_PROTOCOL
	send_payload(make_select_protocol_payload(_external_ip, _external_port, _selected_mode))
	udp_ready.emit(_external_ip, _external_port)

#endregion


#region Session Description Handling

func _session_description_received(data: Dictionary) -> void:
	_selected_mode = data.mode
	_secret_key = PackedByteArray()
	
	for byte in data.secret_key:
		_secret_key.append(int(byte))
	
	_log(func(): return "Session description received: mode=%s, secret_key_length=%d" % [_selected_mode, _secret_key.size()])
	
	# Pass secret key to UDP client
	if _udp_client:
		_udp_client.set_secret_key(_secret_key)
		_log(func(): return "UDP client configured with secret key, ready for audio!")
	
	session_description_received.emit(_selected_mode, _secret_key)

#endregion


#region Speaking Handling

func _speaking_received(data: Dictionary) -> void:
	var user_id = data.get("user_id", "")
	var ssrc = int(data.get("ssrc", 0))
	var speaking = int(data.get("speaking", 0))
	
	_log(func(): return "Speaking state: user_id=%s, ssrc=%d, speaking=%d" % [user_id, ssrc, speaking])
	
	speaking_state_changed.emit(user_id, ssrc, speaking)

#endregion


#region Client Connect/Disconnect

func _client_connect_received(data: Dictionary) -> void:
	var user_id = data.get("user_id", "")
	# audio_ssrc is provided in some cases
	var ssrc = int(data.get("audio_ssrc", 0))
	
	_log(func(): return "Client connected: user_id=%s" % user_id)
	client_connected.emit(user_id, ssrc)


func _client_disconnect_received(data: Dictionary) -> void:
	var user_id = data.get("user_id", "")
	
	_log(func(): return "Client disconnected: user_id=%s" % user_id)
	client_disconnected.emit(user_id)

#endregion


#region Heartbeat Handling

func _on_heartbeat_ack_received() -> void:
	var latency = Time.get_ticks_msec() - _heartbeat_sent_at
	_got_heartbeat_ack = true
	_log(func(): return "Voice heartbeat ack received, latency=%dms" % latency)


func _heartbeat_timer_timeout() -> void:
	_log(func(): return "Heartbeat timer fired. got_ack=%s, nonce=%d" % [str(_got_heartbeat_ack), _nonce])
	
	if not _got_heartbeat_ack:
		# Only close if we've sent at least 2 heartbeats without ack
		if _nonce > 1:
			_log(func(): return "Closing voice WS because didn't receive heartbeat ack after %d heartbeats" % _nonce)
			_client.close(1002)
			return
		else:
			_log(func(): return "First heartbeat ack missing, will retry")
	
	_send_heartbeat()


func _send_heartbeat() -> void:
	_nonce = Time.get_ticks_msec() # Use timestamp as nonce for V8
	# V8 format: d must be {"t": timestamp, "seq_ack": last_seq}
	var payload = {
		op = VoiceOpCodes.HEARTBEAT,
		d = {
			t = _nonce,
			seq_ack = _last_seq_ack
		}
	}
	_heartbeat_sent_at = Time.get_ticks_msec()
	send_payload(payload)
	_got_heartbeat_ack = false
	_log(func(): return "Sent voice heartbeat with t=%d, seq_ack=%d" % [_nonce, _last_seq_ack])

#endregion


#region Connection Closed

func _connection_closed(code: int, reason: String) -> void:
	_log(func(): return "Voice WS connection closed with code=%d, reason=%s" % [code, reason])
	
	_heartbeat_timer.stop()
	_is_connected = false
	_is_speaking = false
	set_process(false)
	
	voice_closed.emit(code, reason)
	
	if code in RECONNECTABLE_CLOSE_CODES:
		_log(func(): return "Voice server crashed, should attempt to resume")
		# The main gateway will receive a new VOICE_SERVER_UPDATE event
		# which will trigger a new voice connection


func _resume() -> void:
	_log(func(): return "Attempting to resume voice session")
	send_payload(_make_resume_payload())

#endregion


#region Payload Builders

func _make_identify_payload() -> Dictionary:
	var payload = {
		op = VoiceOpCodes.IDENTIFY,
		d = {
			server_id = _server_id,
			user_id = _user_id,
			session_id = _session_id,
			token = _token
		}
	}
	_log(func(): return "Identify payload: server_id=%s, user_id=%s, session_id=%s, token=%s..." % [
		_server_id, _user_id, _session_id, _token.substr(0, 10) if _token.length() > 10 else _token
	])
	return payload


func _make_resume_payload() -> Dictionary:
	return {
		op = VoiceOpCodes.RESUME,
		d = {
			server_id = _server_id,
			session_id = _session_id,
			token = _token
		}
	}


func _make_speaking_payload(speaking: int, delay: int = 0) -> Dictionary:
	return {
		op = VoiceOpCodes.SPEAKING,
		d = {
			speaking = speaking,
			delay = delay,
			ssrc = _ssrc
		}
	}


## Build select protocol payload
## Note: This requires IP discovery via UDP which cannot be done purely in GDScript
## [param address]: The external IP address from IP discovery
## [param port]: The external port from IP discovery
## [param mode]: The encryption mode to use
func make_select_protocol_payload(address: String, port: int, mode: String) -> Dictionary:
	return {
		op = VoiceOpCodes.SELECT_PROTOCOL,
		d = {
			protocol = "udp",
			data = {
				address = address,
				port = port,
				mode = mode
			}
		}
	}

#endregion


#region Common

func _log(message_func: Callable) -> void:
	if VERBOSE:
		var message = str(message_func.call())
		if message.is_empty():
			return
		var start = "[color=MEDIUM_PURPLE][DiscordVoice][/color] "
		print_rich(start + ("\n" + start).join(message.split("\n")))



func _log_error(message_func: Callable) -> void:
	var message = str(message_func.call())
	var start = "[color=RED][DiscordVoice][/color] "
	print_rich(start + ("\n" + start).join(message.split("\n")))
#endregion
