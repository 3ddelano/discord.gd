---
title: Getting Started
tags:
  - update
hide:
  - toc
---

After the [installation](../installation), add the [[DiscordBot]] node as a child to any node.

![create node window](https://cdn.discordapp.com/attachments/360062738615107605/870882234096300093/unknown.png){ loading=lazy }

The scene tree should look like this

![the scene tree with the bot](https://cdn.discordapp.com/attachments/360062738615107605/870882778537926747/unknown.png){ loading=lazy }

Now you can add a script to any node besides the [[DiscordBot]] node, here let's add the script to the `Test` node.

The compulsory requirement is the bot `TOKEN` which can be obtained from [Discord Developers](https://discord.com/developers/applications)
After setting the `TOKEN`, calling `.login()` will login the bot and establish a connection to the Discord gateway.

![your scene tree](https://cdn.discordapp.com/attachments/360062738615107605/870896477776523294/unknown.png){ loading=lazy }

If everything went well, the [[DiscordBot]] will emit the `bot_ready` signal.
Now you need to connect the signals which you want from [[DiscordBot]] to the Test node.

![after connecting the signals](https://cdn.discordapp.com/attachments/360062738615107605/870898322410463242/unknown.png){ loading=lazy }

That's it, you can connect the other signals too like [[DiscordBot#message_create|message_create]] , [[DiscordBot#message_create|guild_create]] , etc.

## See [simple bot](../simple-bot)



