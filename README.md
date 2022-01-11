Discord.gd
=========================================
###### (Get it from Godot Asset Library - https://godotengine.org/asset-library/asset/1010)


### A Godot plugin to interact with the Discord Bot API. Make Discord Bots in Godot!

> 100% GDScript

<br>
<img alt="Godot3" src="https://img.shields.io/badge/-Godot 3.x-478CBF?style=for-the-badge&logo=godotengine&logoWidth=20&logoColor=white" />

Features
--------------

- Make a Discord Bot in less than 10 lines of code
- Supports `Buttons` and `SelectMenus`
- Supports `Application Commands` aka `Slash Commands`
- Uses Godot signals to emit events like `bot_ready`, `guild_create`, `message_create`, `message_delete`, etc.
- Get User Avatar and Guild Icon as Godot's `ImageTexture`
- Uses coroutine async functions i.e Promises


Installation
--------------

This is a regular plugin for Godot.
Copy the contents of `addons/discord_gd` into the `addons/` folder in the same directory as your project, and activate it in your project settings.

The plugin now comes with no extra assets to stay lightweight.
If you want to try an example scene, you can see the examples from: [Discord.gd Examples](https://github.com/3ddelano/discord_gd_examples)

> For in-depth installation instructions check the [Installation Wiki](https://3ddelano.github.io/discord.gd/installation)

> Note: You will need a valid Discord Bot token available at [Discord Applications](https://discord.com/developers/applications)


Getting Started
----------

1. After activating the plugin. There will be a new `DiscordBot` node added to Godot.
Click on any node in the scene tree of your scene for example `Root` and add the `DiscordBot` node as a child.

2. Connect the various signals (`bot_ready`, `guild_create`, `message_create`, `message_delete`, etc) of the `DiscordBot` node to the parent node, either through the editor or in the script using the `connect()` method.

3. Attach a script to the `Root` node.

```GDScript
extends Node2D

func _ready():
	var discord_bot = $DiscordBot
	discord_bot.TOKEN = "your_bot_token_here"
	discord_bot.login()
	discord_bot.connect("bot_ready", self, "_on_DiscordBot_bot_ready")

func _on_DiscordBot_bot_ready(bot: DiscordBot):
	print('Logged in as ' + bot.user.username + '#' + bot.user.discriminator)
	print('Listening on ' + str(bot.channels.size()) + ' channels and ' + str(bot.guilds.size()) ' guilds.')

```

[Documentation](https://3ddelano.github.io/discord.gd)
----------


Contributing
-----------

This plugin is a non-profit project developped by voluntary contributors.

### Supporters

```
- YaBoyTwiz#6733
```

### Support the project development
<a href="https://www.buymeacoffee.com/3ddelano" target="_blank"><img height="41" width="174" src="https://cdn.buymeacoffee.com/buttons/v2/default-red.png" alt="Buy Me A Coffee" width="150" ></a>

Want to support in other ways? Contact me on Discord: `@3ddelano#6033`

For doubts / help / bugs / problems / suggestions do join: [3ddelano Cafe](https://discord.gg/FZY9TqW)