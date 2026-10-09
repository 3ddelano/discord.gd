extends SceneTree

const Bot = preload("res://addons/discord_gd/discord.gd")

var _failures = 0
var _ready_count = 0
var _joined_guilds: Array = []
var _ready_guilds: Dictionary = {}
var _ready_channels: Dictionary = {}
var _ready_user: String
var _ready_application: String


func _initialize() -> void:
	_test_normal_startup()
	_test_duplicate_and_unrelated_guilds()
	_test_zero_guilds()
	_test_new_ready_resets_pending_guilds()
	_test_new_ready_after_completed_startup()
	if _failures == 0:
		print("PASS: bot_ready regression tests")
	quit(1 if _failures else 0)


func _new_bot():
	_ready_count = 0
	_joined_guilds = []
	_ready_guilds = {}
	_ready_channels = {}
	_ready_user = ""
	_ready_application = ""
	var bot = Bot.new()
	bot.bot_ready.connect(func(ready_bot):
		_check(ready_bot == bot, "bot_ready should pass the bot instance")
		_ready_count += 1
		_ready_guilds = bot.guilds.duplicate(true)
		_ready_channels = bot.channels.duplicate(true)
		_ready_user = bot.user.id
		_ready_application = bot.application.id
	)
	bot.guild_create.connect(func(_bot, guild): _joined_guilds.append(guild.id))
	return bot


func _dispatch_ready(bot, guild_ids: Array) -> void:
	var guilds: Array = []
	for guild_id in guild_ids:
		guilds.append({"id": guild_id, "unavailable": true})
	bot._on_dispatch_event_received("READY", {
		"application": {"id": "application"},
		"user": {"id": "bot", "username": "test", "discriminator": "0", "avatar": null},
		"guilds": guilds,
	})


func _dispatch_guild(bot, guild_id: String, extra: Dictionary = {}) -> void:
	var guild = {"id": guild_id, "name": "Guild " + guild_id}
	guild.merge(extra)
	bot._on_dispatch_event_received("GUILD_CREATE", guild)


func _test_normal_startup() -> void:
	var bot = _new_bot()
	_dispatch_ready(bot, ["first", "last"])
	_check(_ready_count == 0, "READY with guilds should wait for GUILD_CREATE")
	_dispatch_guild(bot, "first")
	_check(_ready_count == 0, "one of two initial guilds should not emit readiness")
	_dispatch_guild(bot, "last", {
		"channels": [{"id": "channel", "type": 0}],
		"members": [{"user": {"id": "member"}}],
		"roles": [{"id": "role", "name": "Role"}],
	})
	_check(_ready_count == 1, "normal GUILD_CREATE without lazy should complete startup")
	_check(_ready_guilds.get("last", {}).get("name") == "Guild last", "final guild should be cached before bot_ready")
	_check(_ready_guilds.get("last", {}).get("available") == true, "final guild should be available before bot_ready")
	_check(_ready_guilds.get("last", {}).get("members", {}).has("member"), "members should be parsed before bot_ready")
	_check(_ready_guilds.get("last", {}).get("roles", {}).has("role"), "roles should be parsed before bot_ready")
	_check(_ready_channels.get("channel", {}).get("guild_id") == "last", "channels should be cached before bot_ready")
	_dispatch_guild(bot, "last", {"lazy": true})
	_dispatch_guild(bot, "later")
	_check(_ready_count == 1, "later guild events should not re-emit bot_ready")
	_check(_joined_guilds == ["later"], "initial guilds should not emit guild_create, but later joins should")
	bot.free()


func _test_duplicate_and_unrelated_guilds() -> void:
	var bot = _new_bot()
	_dispatch_ready(bot, ["first", "last"])
	_dispatch_guild(bot, "first", {"lazy": true})
	_check(_ready_count == 0, "one initial guild should not complete startup")
	_dispatch_guild(bot, "first", {"lazy": true})
	_check(_ready_count == 0, "duplicate initial guilds should not advance readiness")
	_dispatch_guild(bot, "joined", {"lazy": true})
	_check(_ready_count == 0, "a newly joined guild should not advance readiness")
	_check(_joined_guilds == ["joined"], "only new guilds should emit guild_create")
	_dispatch_guild(bot, "last")
	_check(_ready_count == 1, "only the last pending guild should complete startup")
	bot.free()


func _test_zero_guilds() -> void:
	var bot = _new_bot()
	_dispatch_ready(bot, [])
	_check(_ready_count == 1, "zero-guild READY should immediately emit bot_ready")
	_check(_ready_user == "bot", "user should be set before zero-guild bot_ready")
	_check(_ready_application == "application", "application should be set before zero-guild bot_ready")
	_dispatch_guild(bot, "joined")
	_check(_ready_count == 1, "joining a guild after zero-guild startup should not re-emit readiness")
	_check(_joined_guilds == ["joined"], "joining after zero-guild startup should emit guild_create")
	bot.free()


func _test_new_ready_resets_pending_guilds() -> void:
	var bot = _new_bot()
	_dispatch_ready(bot, ["old"])
	_dispatch_ready(bot, ["new"])
	_dispatch_guild(bot, "old")
	_check(_ready_count == 0, "guilds from the previous READY should not complete the new startup")
	_dispatch_guild(bot, "new")
	_check(_ready_count == 1, "a new READY should replace the previous pending guilds")
	_dispatch_ready(bot, ["pending"])
	_dispatch_ready(bot, [])
	_check(_ready_count == 2, "a zero-guild READY should discard old pending guilds")
	_dispatch_guild(bot, "pending", {"lazy": true})
	_check(_ready_count == 2, "discarded pending guilds should not re-emit readiness")
	bot.free()


func _test_new_ready_after_completed_startup() -> void:
	var bot = _new_bot()
	_dispatch_ready(bot, ["first"])
	_dispatch_guild(bot, "first", {"lazy": true})
	_check(_ready_count == 1, "initial startup should complete")
	_dispatch_ready(bot, ["second"])
	_check(_ready_count == 1, "a new READY should wait for its own guilds")
	_dispatch_guild(bot, "second")
	_check(_ready_count == 2, "a new READY should complete independently of cached guilds")
	bot.free()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("FAIL: " + message)
