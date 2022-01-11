---
title: Simple Bot
tags:
  - simple-bot, example
---

# Simple Bot

```GDScript
extends Node2D

func _ready():
    var bot = DiscordBot.new()
    add_child(bot)
	bot.connect("bot_ready", self, "_on_bot_ready")
	bot.connect("message_create", self, "_on_message_create")
	bot.TOKEN = "your_bot_token_here"
	bot.login()

func _on_bot_ready(bot: DiscordBot):
	print("Logged in as " + bot.user.username + "#" + bot.user.discriminator)
	print("Listening on " + str(bot.channels.size()) + " channels and " + str(bot.guilds.size()) + " guilds.")

func _on_message_create(bot: DiscordBot, message: Message, channel: Dictionary):
    var content = message.content
    print("Received message: " + content)
    bot.send(message, "I got a message here")
```

### [More Examples](https://github.com/3ddelano/discord_gd_examples)