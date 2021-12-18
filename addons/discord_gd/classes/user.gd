class_name User
"""
Represents a Discord User.
"""

var id: String
var username: String
var discriminator: String
var avatar: String

# Optional
var bot: bool
var system: bool
var mfa_enabled: bool
var locale: String
var verified: bool
var email: String
var flags: int
var premium_type: int
var public_flags: int

var client

const AVATAR_URL_FORMATS = ['webp', 'png', 'jpg', 'jpeg', 'gif']
const AVATAR_URL_SIZES = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096]

func get_display_avatar_url(options: Dictionary = {}) -> String:
	"""
	options {
		format: String, one of webp, png, jpg, jpeg, gif (default png),
		size: int, one of 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 (default 256),
		dynamic: bool, if true the format will automatically change to gif for animated avatars (default false)
	}
	"""

	if options.has('format'):
		assert(options.format in AVATAR_URL_FORMATS, 'Invalid avatar_url provided to get_display_avatar')
	else:
		options.format = 'png'

	if options.has('size'):
		assert(int(options.size) in AVATAR_URL_SIZES, 'Invalid size provided to get_display_avatar')
	else:
		options.size = 256

	if options.has('dynamic'):
		assert(typeof(options.dynamic) == TYPE_BOOL, 'dynamic attribute must be of type bool in get_display_avatar')
		if Helpers.is_valid_str(avatar) and avatar.begins_with('a_'):
			options.format = 'gif'
	else:
		options.dynamic = false

	if not Helpers.is_valid_str(avatar):
		return get_default_avatar_url()

	return client._cdn_base + '/avatars/%s/%s.%s?size=%s' % [id, avatar, options.format, options.size]


func get_default_avatar_url() -> String:
	var moduloed_discriminator = int(discriminator) % 5
	return client._cdn_base + '/embed/avatars/%s.png' % moduloed_discriminator


func get_display_avatar(options: Dictionary = {}) -> PoolByteArray:
	var png_bytes = yield(
		client._send_get_cdn(get_display_avatar_url(options)), 'completed'
	)
	return png_bytes


func get_default_avatar() -> PoolByteArray:
	var png_bytes = yield(
		client._send_get_cdn(get_default_avatar_url()), 'completed'
	)
	return png_bytes


func _init(_client, user):
	client = _client
	# Compulsory
	assert(user.has('id'), 'User must have an id')
	assert(user.has('username'), 'User must have a username')
	assert(user.has('discriminator'), 'User must have a discriminator')


	id = user.id
	username = user.username
	discriminator = user.discriminator
	if user.avatar:
		avatar = user.avatar

	# Optional

	if user.has('bot') and user.bot != null:
		assert(typeof(user.bot) == TYPE_BOOL, 'bot attribute of User must be bool')
		bot = user.bot
	else:
		bot = false

	if user.has('system') and user.system != null:
		assert(typeof(user.system) == TYPE_BOOL, 'system attribute of User must be bool')
		system = user.system
	else:
		system = false

	if user.has('mfa_enabled') and user.mfa_enabled != null:
		assert(typeof(user.mfa_enabled) == TYPE_BOOL, 'mfa_enabled attribute of User must be bool')
		mfa_enabled = user.mfa_enabled
	else:
		mfa_enabled = false

	if user.has('verified') and user.verified != null:
		assert(typeof(user.verified) == TYPE_BOOL, 'verified attribute of User must be bool')
		verified = user.verified
	else:
		verified = false

	if user.has('locale') and user.locale != null:
		assert(typeof(user.locale) == TYPE_STRING, 'locale attribute of User must be String')
		locale = user.locale

	if user.has('email') and user.email != null:
		assert(typeof(user.email) == TYPE_STRING, 'email attribute of User must be String')
		email = user.email

	if user.has('flags') and user.flags != null:
		assert(Helpers.is_num(user.flags), 'flags attribute of User must be int')
		flags = user.flags

	if user.has('premium_type') and user.premium_type != null:
		assert(Helpers.is_num(user.premium), 'premium_type attribute of User must be int')
		premium_type = user.premium_type

	if user.has('public_flags') and user.public_flags != null:
		assert(Helpers.is_num(user.public_flags), 'public_flags attribute of User must be int')
		public_flags = user.public_flags

func _to_string(pretty: bool = false):
	var data = {
		'id': id,
		'username': username,
		'discriminator': discriminator,
		'avatar': avatar,
		'bot': bot,
		'system': system,
		'mfa_enabled': mfa_enabled,
		'locale': locale,
		'verified': verified,
		'email': email,
		'flags': flags,
		'premium_type': premium_type,
		'public_flags': public_flags
	}
	return JSON.print(data, '\t') if pretty else JSON.print(data)

func print():
	print(_to_string(true))
