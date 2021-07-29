Discord.gd [WIP]
=========================================


Discord Bot API wrapper for Godot 3.3.
It allows you to interact with the Discord API.

This repository holds the latest development version, which means it has the latest features but can also have bugs.
For a "stable" version, use the asset library or download from a commit tagged with a version.
The `master` branch is the latest development version, and may have bugs. Some major features can also be in other branches until they are done. For release versions, check the Git branches named after those versions, like `1.0.0`.


Features
--------------

- Uses Godot signals to emit events like `bot_ready`, `guild_create`, `message_create`, `message_delete`, etc.
- Send / Receive messages and events from Discord
- Get User Avatar and Guild Icon as Godot's ImageTexture
- Uses coroutine functions i.e Promises


Installation
--------------

This is a regular plugin for Godot.
Copy the contents of `addons/discord_gd` into the `addons/` folder in the same directory as your project, and activate it in your project settings.

The plugin now comes with no extra assets to stay lightweight.
If you want to try an example scene, you can install this demo once the plugin is setup and active:
https://github.com/3ddelano/discord_gd_examples

NOTE: You will need a valid Discord Bot TOKEN available at [Discord Applications](https://discord.com/developers/applications)


Getting Started
----------

1. After activating the plugin. There will be a new DiscordBot node added to Godot.
Click on any node in the scene tree of your scene for example `MyBot`:Node2D and add the DiscordBot as a child.

2. Connect the various signals (`bot_ready`, `guild_create`, `message_create`, `message_delete`, etc) of the DiscordBot to the parent node

3. Attach a script to the parent node.
Example script on `MyBot` node

```GDScript

func _ready():
	var discord_bot = $$DicordBot
	discord_bot.TOKEN = "your_bot_token_here"
	discord_bot.login()
	
func _on_DiscordBot_bot_ready(bot: DiscordBot):
	print('Logged in as ' + bot.user.username + '#' + bot.user.discriminator)
	print('Listening on ' + bot.channels.size() + ' channels and ' + bot.guilds.size() ' guilds.')

```

Documentation
----------

Check the Wiki Tab


Contributing
-----------

This plugin is a non-profit project developped by voluntary contributors. The following is the list of the current donors.
Thanks for your support :)

### Supporters

```
- None ( You can become the first)
```

### Donate
<a href="https://www.buymeacoffee.com/3ddelano" target="_blank"><img height="41" width="174" src="https://cdn.buymeacoffee.com/buttons/v2/default-red.png" alt="Buy Me A Coffee" width="150" ></a>

### Support Server
Join the Discord Server: [3ddelano Cafe](https://discord.gg/FZY9TqW)