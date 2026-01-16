extends Control

const PREFIX = "gd."

@onready var bot: DiscordBot = $DiscordBot


func _ready() -> void:
	bot.VERBOSE = true
	#bot.gateway.VERBOSE = true
	bot.TOKEN = _read_token_from_env_file()

	bot.bot_ready.connect(_on_bot_ready)
	bot.message_create.connect(_on_message_create)

	bot.login()


func _on_bot_ready(_bot: DiscordBot):
	print("Logged in as %s#%s" % [bot.user.username, bot.user.discriminator])
	print("Listening on %d channels and %d guilds for command prefix %s" % [bot.channels.size(), bot.guilds.size(), PREFIX])
	
	bot.set_presence({
		status = "online",
		activity = {
			type = "watching",
			name = "watching the prefix %s on %d servers" % [PREFIX, bot.guilds.size()]
		}
	})


func _on_message_create(_bot: DiscordBot, message: Message, channel: Dictionary):
	# Skip msgs from bots
	if message.author.bot:
		return
	
	# Skip msgs that don't start with command prefix
	if not message.content.to_lower().begins_with(PREFIX):
		return

	var tokens: Array[String]
	tokens.assign(Array(message.content.split(" ")))
	var command = tokens.pop_front().to_lower().trim_prefix(PREFIX)
	var args = tokens
	_handle_command(command, args, message, channel)


@warning_ignore("unused_parameter")
func _handle_command(command: String, args: Array[String], msg: Message, channel: Dictionary):
	print("Got command name=%s, user_id=%s, channel_id=%s, guild_id=%s" % [command, msg.author.id, msg.channel_id, msg.guild_id])

	if command == "ping":
		await bot.reply(msg, "Pong!")
		return


# Read DISCORD_BOT_TOKEN from .env file
func _read_token_from_env_file():
	var file = FileAccess.open("res://.env", FileAccess.READ)
	var contents = file.get_as_text()
	var lines = contents.split("\n")
	for line in lines:
		if line.strip_edges().begins_with("DISCORD_BOT_TOKEN="):
			return line.strip_edges().split("=")[1].strip_edges()
	return ""
