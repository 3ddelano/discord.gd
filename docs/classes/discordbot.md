---
title: Class DiscordBot
tags:
  - discord-bot, class
---

# DiscordBot
Extends: [HTTPRequest](https://docs.godotengine.org/en/3.3/classes/class_httprequest.html)

```
The main Node which interacts with the Discord API.
```

## Description
A Node with the ability to communicate with the Discord websockets and REST API. Uses HTTPRequest internally. Uses signals to communicate websocket events from Discord to Godot.

## Properties
| Type       | Name        | Defaults | Description                                                                           |
| ---------- | ----------- | -------- | ------------------------------------------------------------------------------------- |
| String     | TOKEN       | ""       | The token of the Discord Bot from Discord Developers                                  |
| bool       | VERBOSE     | false    | If true, prints additional debug messages                                             |
| int        | INTENTS     | 513      | [Gateway Intents](https://discord.com/developers/docs/topics/gateway#gateway-intents) |
| [[User]]   | user        | null     | The bot's user account                                                                |
| Dictionary | application | {}       | Partial bot's application                                                             |
| Dictionary | guilds      | {}       | Guilds the bot is in mapped by their ids                                              |
| Dictionary | channels    | {}       | Text channels and DM channels the bot can access mapped by their ids                  |

## Methods
| Returns                | Definition                                                                                                 |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| int                    | [add_member_role(guild_id: String, member_id: String, role_id: String)](#discordbot-add-member-role)       |
| Dictionary             | [create_dm_channel(recipient_id: String)](#discordbot-create-dm-channel)                                   |
| int                    | [create_reaction(message, custom_emoji: String)](#discordbot-create-reaction)                              |
| Variant                | [delete(message: Message)](#discordbot-delete)                                                             |
| int                    | [delete_reaction(message, custom_emoji: String, userid?: String)](#discordbot-delete-reaction)             |
| int                    | [delete_reactions(message, custom_emoji: String)](#discordbot-delete-reactions)                            |
| Message                | [edit(message: Message, content, options?: Dictionary)](#discordbot-edit)                                  |
| Array                  | [get_guild_emojis(guild_id: String)](#discordbot-get-guild-emojis)                                         |
| PoolByteArray          | [get_guild_icon(guild_id: String, size?: int)](#discordbot-get-guild-icon)                                 |
| Dictionary             | [get_guild_member(guild_id: String, member_id: String)](#discordbot-get-guild-member)                      |
| Array                  | [get_reactions(message, custom_emoji: String)](#discordbot-get-reactions)                                  |
| void                   | [login()](#discordbot-login)                                                                               |
| Permissions            | [permissions_for(user_id: String, channel_id: String)](#discordbot-permissions-for)                        |
| Permissions            | [permissions_in(channel_id: String)](#discordbot-permissions-in)                                           |
| int                    | [remove_member_role(guild_id: String, member_id: String, role_id: String)](#discordbot-remove-member-role) |
| Message                | [reply(message: Message, content, options?: Dictionary)](#discordbot-reply)                                |
| Message                | [send(message_or_channelid: Variant, content, options?: Dictionary)](#discordbot-send)                     |
| void                   | [set_presence(options: Dictionary)](#discordbot-set-presence)                                              |
| Dictionary             | [start_thread(message: Message, name: String, duration?: int)](#discordbot-start-thread)                   |
| [[ApplicationCommand]] | [register_command(command: [[ApplicationCommand]], guild_id?: String)](#discordbot-register-command)       |
| Array                  | [register_commands(commands: Array, guild_id?: String)](#discordbot-register-commands)                     |
| int                    | [delete_command(command_id: String, guild_id?: String)](#discordbot-delete-command)                        |
| int                    | [delete_commands(guild_id?: String)](#discordbot-delete-commands)                                          |
| [[ApplicationCommand]] | [get_command(command_id: String, guild_id?: String)](#discordbot-get-command)                              |
| Array                  | [get_commands(guild_id?: String)](#discordbot-get-commands)                                                |

## Signals
<small>See [Discord Gateway Intents](https://discord.com/developers/docs/topics/gateway#commands-and-events-gateway-events)</small>

- bot_ready(bot: DiscordBot)
  <br>Emitted when the bot is logged in to Discord.
  <br>**bot**: The Discord bot itself

- message_create(bot: DiscordBot, message: [[Message]], channel: Dictionary)
  <br>Emitted when the bot receives a new message.
  <br>**bot**: The Discord bot itself
  <br>**message**: The message that was received
  <br>**channel**: The channel in which the message was received

- message_delete(bot: DiscordBot, message: Dictionary)
  <br>Emitted when any message was deleted.
  <br>**bot**: The Discord bot itself
  <br>**message**: The message that was deleted

- message_reaction_add(bot: DiscordBot, data: Dictionary)
  <br>Emitted when a user reacts to a message.
  <br>**bot**: The Discord bot itself
  <br>**data**: Data emitted with the event <small>(See [Event Fields](https://discord.com/developers/docs/topics/gateway#message-reaction-add-message-reaction-add-event-fields))</small>

- message_reaction_remove(bot: DiscordBot, data: Dictionary)
  <br>Emitted when a user removes a reaction from a message.
  <br>**bot**: The Discord bot itself
  <br>**data**: Data emitted with the event <small>(See [Event Fields](https://discord.com/developers/docs/topics/gateway#message-reaction-remove-message-reaction-remove-event-fields))</small>

- message_reaction_remove_all(bot: DiscordBot, data: Dictionary)
  <br>Emitted when a user explicitly removes all reactions from a message.
  <br>**bot**: The Discord bot itself
  <br>**data**: Data emitted with the event <small>(See [Event Fields](https://discord.com/developers/docs/topics/gateway#message-reaction-remove-all-message-reaction-remove-all-event-fields))</small>

- message_reaction_remove_emoji(bot: DiscordBot, data: Dictionary)
  <br>Emitted when a bot removes all instances of a given emoji from the reactions of a message.
  <br>**bot**: The Discord bot itself
  <br>**data**: Data emitted with the event <small>(See [Event Fields](https://discord.com/developers/docs/topics/gateway#message-reaction-remove-emoji-message-reaction-remove-emoji))</small>

- guild_create(bot: DiscordBot, guild: Dictionary)
  <br>Emitted when the bot joins a new guild
  <br>**bot**: The Discord bot itself
  <br>**guild**: The guild that was just joined

- guild_update(bot: DiscordBot, guild: Dictionary)
  <br>Emitted when the guild is updated
  <br>**bot**: The Discord bot itself
  <br>**guild**: Data of the guild that was updated

- guild_delete(bot: DiscordBot, guild_id: String)
  <br>Emitted when the bot leaves a guild
  <br>**bot**: The Discord bot itself
  <br>**guild_id**: The id of the guild that the bot left

- interaction_create(bot: DiscordBot, interaction: [[DiscordInteraction]])
  <br>Emitted when a new interaction is created
  <br>**bot**: The Discord bot itself
  <br>**interaction**: The interaction which was created

## Method Descriptions

### <a name="discordbot-login"></a>login() -> void
Connects the bot to the Discord websocket gateway.

!!! note
    If you want to set `DiscordBot.INTENTS` to a custom value, set it before calling `DiscordBot.login()`

!!! note
    The `DiscordBot.TOKEN` must be set prior to calling `DiscordBot.login()`

### <a name="discordbot-send"></a>send(message_or_channelid, content, options?)
Sends a message to a channel
> Returns: Promise<Message\>

| Type                     | Parameter            | Description                                                              |
| ------------------------ | -------------------- | ------------------------------------------------------------------------ |
| Variant                  | message_or_channelid | Either the channelid or the message from which to extract the channel_id |
| String     \| Dictionary | content              | Either the message content, or a Dictionary of message options           |
| Dictionary               | options              | Additional message options                                               |

options: Dictionary
```GDScript
{
  embeds?: Array of Embed,
  files?: Array of files
  tts?: bool,
  allowed_mentions?: Dictionary (See https://discord.com/developers/docs/resources/channel#allowed-mentions-object)
}
```

Each file in files: Dictionary
```GDScript
{
  data: PoolByteArray, the raw bytes of the file,
  name: String, the name of the file with extension,
  media_type: String, the MIME type of the file
}
```

#### Examples
Send only a text message
```GDScript
# This function is called when the message_create signal is emitted
func _on_message_create(bot: DiscordBot, message: Message, channel: Dictionary):
  bot.send(message, "hello")
  # OR
  # bot.send(message.channel_id, "hello")
  # OR
  # bot.send(channel.id, "hello")
```

Send only an embed 
```GDScript
# Make a new embed
var embed = Embed.new().set_description("Hello")
# Send it
bot.send(message, {"embeds": [embed]})
```

Send multiple embeds
```GDScript
# Make two embeds
var embed1 = Embed.new().set_description("This is embed 1")
var embed2 = Embed.new().set_description("This is embed 2")
# Snd them
bot.send(message, {"embeds": [embed1, embed2]})
```

Send a text message and an embed
```GDScript
# Make a new embed
var embed = Embed.new().set_description("Hello")
# Pass is as options
bot.send(message, "hello", {"embeds": [embed]})
```

Send only a image file
```GDScript
# Read the image file
var file = File.new()
file.open("res://icon.png", File.READ)

# Get the raw bytes as a PoolByteArray
var file_data: PoolByteArray = file.get_buffer(file.get_len())
file.close()

# Make the file data object
var file = {
  "data": file_data,
  "name": "godot.png",
  "media_type": "image/png"
}
# Send the file
bot.send(message, "Here is your file", {"files": [file]})
```

Send multiple files
```GDScript
#...code here to get the file_data_1 and file_data_2 as PoolByteArray

var file1 = {
  "data": file_data_1,
  "name": "file1.png",
  "media_type": "image/png"
}

var file2 = {
  "data": file_data_2,
  "name": "file2.png",
  "media_type": "image/png"
}

bot.send(message, {"files": [file1, file2]})
```

Send a message as a reply to another message
!!! note
  It's better to use [[discordbot-reply|DiscordBot.reply()]] to reply to messages, but if you want to use `DiscordBot.send()`, pass in a message_reference object to the options
```GDScript
var embed = Embed.new().set_description("embeds can also be added")
bot.send(message, "I replied to this message", {
  "embeds": [embed],
  "message_reference": {
    "message_id": message.id
  }
})
```

Send three messages in order
```GDScript
yield(bot.send(message, "This is message 1"), "completed")
yield(bot.send(message, "This is message 2"), "completed")
yield(bot.send(message, "This is message 3"), "completed")
```

### <a name="discordbot-edit"></a>edit(message, content, options?)
Edits a sent message.
> Returns: Promise<Message\>

| Type                     | Parameter | Description                                            |
| ------------------------ | --------- | ------------------------------------------------------ |
| Message                  | message   | The message to be edited                               |
| String     \| Dictionary | content   | Either the new message content, or new message options |
| Dictionary               | options   | Additional message options                             |

!!! note
    The `content` and `options` are same as [[#discordbot-send|DiscordBot.send()]]

!!! note
    Adding a file to a message that already has files results in both files existing on the new message.
    To only have the new file remain, use [[message#message-slice-attachments|Message.slice_attachments()]]

#### Examples

Edit the content of a message
```GDScript
# Send a new message
# The yield is to ensure that the message is sent
var msg = yield(bot.send(message, "This is the original content"), "completed")

# Edit the sent message
# Here the msg is passed to bot.edit() and not message, since we want to edit msg
var edited_msg = yield(bot.edit(msg, "This is the edited content"), "completed")
```

Edit the embed of a message
```GDScript
# Make an embed
var embed = Embed.set_title("Test Title").set_description("Hello")

# Send a message with embed
var msg = yield(bot.send(message, {"embeds": [embed]}), "completed")

# Update the embed data
embed.set_title("Edited Embed Title")

# Edit the msg with updated embed
bot.edit(msg, {"embeds": [embed]})
```

### <a name="discordbot-delete"></a>delete(message)
Deletes the message with same id as message.

> Returns: Promise<bool\>
  The function returns `true` if the message is deleted, otherwise it returns the HTTP error code.

!!! note
    The bot should have `MANAGE_MESSAGES` permission inorder to delete messages of other users.

| Type    | Parameter | Description               |
| ------- | --------- | ------------------------- |
| Message | message   | The message to be deleted |

#### Examples
Delete a message sent by the bot
```GDScript
# Send a new message
# Note: The yield is to ensure that the message is sent
var msg = yield(bot.send(message, "This message will be delete"), "completed")

# Delete the sent message
var res = yield(bot.delete(msg), "completed")
```

Delete a message sent by a user
```GDScript
# In the message_create signal,
# The bot must have valid permissions to delete a message
var res = yield(bot.delete(message), "completed")
```

### <a name="discordbot-reply"></a>reply(message, content, options?)
Replies to a message
> Returns: Promise<Message\>
 
| Type                     | Parameter | Description                                            |
| ------------------------ | --------- | ------------------------------------------------------ |
| Message                  | message   | The message to reply to                                |
| String     \| Dictionary | content   | Either the new message content, or new message options |
| Dictionary               | options   | Additional message options                             |

!!! note
    The `content` and `options` are same as DiscordBot.send()

### <a name="discordbot-start-thread"></a>start_thread(message, name, duration?)
Creates a new thread with name as `name`, archive duration as `duration` and with the starter message as `message`.
It returns the information of the new thread.
> Returns: Promise<Dictionary\>

| Type    | Parameter | Description             |
| ------- | --------- | ----------------------- |
| Message | message   | The message to reply to |
| String  | name      | Name of the thread      |
| int     | duration  | Archive duration        |

#### Examples
Start a new thread with the name as discord.gd
```GDScript
bot.start_thread(message, "discord.gd")
```

### <a name="discordbot-get-guild-icon"></a>get_guild_icon(guild_id, size?)
Returns the guild icon of the guild.
> Returns: Promise<PoolByteArray\>

| Type   | Parameter | Defaults | Description                                                                          |
| ------ | --------- | -------- | ------------------------------------------------------------------------------------ |
| String | guild_id  | -        | The id of the guild                                                                  |
| int    | size      | 256      | The size of the guild icon image. One of 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 |

!!! note
    To get the `guild_icon` as an `Image` or `ImageTexture` use [[helpers#helpers-to-png-image|Helpers.to_png_image()]] and [[helpers#helpers-to-image-texture|Helpers.to_image_texture()]]

#### Examples
Get the guild icon as an `Image`
```GDScript
# The yield is to ensure that the guild icon is fetched
var bytes = yield(bot.get_guild_icon("330264450148073474", 512), "completed")

var image: Image = Helpers.to_png_image(bytes)
```

Get the guild icon as an `ImageTexture`
```GDScript
# The yield is to ensure that the guild icon is fetched
var bytes = yield(bot.get_guild_icon("330264450148073474", 512), "completed")

var image: Image = Helpers.to_png_image(bytes)
var texture: ImageTexture = Helpers.to_image_texture(image)
```

### <a name="discordbot-set-presence"></a>set_presence(options)
Sets the presence of the bot
> Returns: void

```GDScript
options {
    status: String, status of the presence (https://discord.com/developers/docs/topics/gateway#update-presence-status-types),
    afk: bool, whether or not the client is afk,

    activity: { (https://discord.com/developers/docs/topics/gateway#activity-object)
        type: String, type of the presence,
        name: String, name of the presence,
        url: String, url of the presence,
        created_at: int, unix timestamp (in milliseconds) of when activity was added to user's session
    }
}
```

#### Examples

Set the presence of the bot to "Playing Godot Engine"
```GDScript
# In the bot_ready method,
bot.set_presence({
    "status": "online",
    "afk": false,
    "activity": {
        "type": "game",
        "name": "Godot Engine",
    }
})
```
### <a name="discordbot-permissions-in"></a>permissions_in(channel_id)
Returns the permissions the bot has in a specific channel after applying channel overwrites
> Returns: Permissions
> 
| Type   | Parameter  | Description           |
| ------ | ---------- | --------------------- |
| String | channel_id | The id of the channel |

#### Examples
Check if the bot has the `SEND_MESSAGES` pemissions before sending a message
```GDScript
var perms = bot.permissions_in(message.channel_id)
if not perms.has("SEND_MESSAGES"):
    return

bot.send(message, "I can send messages :)")
```

### <a name="discordbot-permissions-for"></a>permissions_for(user_id, channel_id)
Returns the permissions for a specific user in a specific channel
> Returns: Permissions
!!! note
    This currently only works for the Bot, since loading the guild users requires the GUILD_MEMBERS priviledged intent.

| Type   | Parameter  | Description           |
| ------ | ---------- | --------------------- |
| String | user_id    | The id of the user    |
| String | channel_id | The id of the channel |

### <a name="discordbot-get-guild-member"></a>get_guild_member(guild_id, member_id)
Fetches a specific guild member's data
> Returns: Promise<Dictionary\>

| Type   | Parameter | Description                          |
| ------ | --------- | ------------------------------------ |
| String | guild_id  | The id of the guild the member is in |
| String | member_id | The id of the member                 |

#### Examples
Get the guild member data of the user who sent the message
```GDScript
var member_id = message.author.id
var member = yield(bot.get_guild_member(message.guild_id, member_id), "completed")
print(member)
```

### <a name="discordbot-add-member-role"></a>add_member_role(guild_id, member_id, role_id)
Adds the role to the member
> Returns: int
> 
> Returns the HTTP response code (204 is success)

!!! note
    This requires the `MANAGE_ROLES` permission

| Type   | Parameter | Description                          |
| ------ | --------- | ------------------------------------ |
| String | guild_id  | The id of the guild the member is in |
| String | member_id | The id of the member                 |
| String | role_id   | The id of the role to add            |

#### Examples
Add the role with id `374446838406709259` to the user who sent the message
```GDScript
var member_id = message.author.id
var res = yield(bot.add_member_role(message.guild_id, member_id, "374446838406709259"), "completed")
print(res) # Prints the HTTP response code (204 is success)
```

### <a name="discordbot-remove-member-role"></a>remove_member_role(guild_id, member_id, role_id)
Removes the role from the member
> Returns: int
> 
> Returns the HTTP response code (204 is success)
!!! note
    This requires the `MANAGE_ROLES` permission

| Type   | Parameter | Description                          |
| ------ | --------- | ------------------------------------ |
| String | guild_id  | The id of the guild the member is in |
| String | member_id | The id of the member                 |
| String | role_id   | The id of the role to remove         |

#### Examples
Remove the role with id `374446838406709259` from the user who sent the message
```GDScript
var member_id = message.author.id
var res = yield(bot.remove_member_role(message.guild_id, member_id, "374446838406709259"), "completed")
print(res) # Prints the HTTP response code (204 is success)
```

### <a name="discordbot-get-guild-emojis"></a>get_guild_emojis(guild_id)
Returns an array of all the custom emojis of the guild
> Returns: Promise<Array\>

| Type   | Parameter | Description         |
| ------ | --------- | ------------------- |
| String | guild_id  | The id of the guild |

#### Examples
Get the custom emojis of the guild in which the message was sent
```GDScript
var emojis = yield(bot.get_guild_emojis(message.guild_id), "completed")
print(emojis)
```

### <a name="discordbot-create-dm-channel"></a>create_dm_channel(recipient_id)
Returns the channel data of the DM channel between the bot and the recipient
> Returns: Promise<Dictionary\>

| Type   | Parameter    | Description                  |
| ------ | ------------ | ---------------------------- |
| String | recipient_id | The id of the recipient user |

#### Examples
Send the user with id "32123387577696256" a DM
```GDScript
var dm_channel = yield(bot.create_dm_channel("321233875776962560"), "completed")
bot.send(dm_channel.id, "Hey this is a dm")
```

### <a name="discordbot-create-reaction"></a>create_reaction(message, custom_emoji)
Creates a emoji reaction for the message.
> Returns: int
> 
> Returns the http response code (204 is success).

!!! note
    Only CUSTOM EMOJIS are supported since Godot can't render unicode emojis. Pass only the Id of the custom emoji for `custom_emoji` parameter.

!!! note
    This requires the `READ_MESSAGE_HISTORY` permission. Additionally, if nobody else has reacted to the message using this emoji, this endpoint requires the `ADD_REACTIONS` permission to be present on the current user.

| Type    | Parameter    | Description                   |
| ------- | ------------ | ----------------------------- |
| Variant | message      | The message on which to react |
| String  | custom_emoji | The custom id of the emoji    |

#### Examples
React with an animated parrot
```GDScript
bot.create_reaction(message, "565171769187500032")
```

React with an animated parrot and a white checkmark in order
```GDScript
yield(bot.create_reaction(message, "565171769187500032"), "completed") # animated parrot
yield(bot.create_reaction(message, "556051807504433152"), "completed") # white checkmark
```

React without using the entire Message object
```GDScript
var message_object = {
  id = "message id here",
  channel_id = "channel id here"
}
yield(bot.create_reaction(message_object, "565171769187500032"), "completed")
```

### <a name="discordbot-delete-reaction"></a>delete_reaction(message, custom_emoji, userid?)
Deletes the bot's or a user's reaction of an emoji. 
> Returns: Promise<int\>
> 
> Returns the http response code (204 is success).

!!! note
    This requires the `MANAGE_MESSAGES` permission

!!! note
    Only CUSTOM emojis are supported since Godot can't render unicode emojis. Pass only the Id of the custom emoji as `custom_emoji`.


| Type    | Parameter    | Description                                                                                       |
| ------- | ------------ | ------------------------------------------------------------------------------------------------- |
| Variant | message      | The message on which to react                                                                     |
| String  | custom_emoji | The custom id of the emoji                                                                        |
| String  | user_id      | The id of the user whose reaction to delete. If not provided, the bot's reaction will be deleted. |


#### Examples
Delete the bot's reaction of an animated parrot
```GDScript
# First react to the message
yield(bot.create_reaction(message, "565171769187500032"), "completed")

# Then delete that reaction
yield(bot.delete_reaction(message, "565171769187500032"), "completed")
```

Delete the bot's reaction of an animated parrot and a white checkmark in order
```GDScript
# First react to the message
yield(bot.create_reaction(message, "565171769187500032"), "completed") # animated parrot
yield(bot.create_reaction(message, "556051807504433152"), "completed") # white checkmark

# Then delete those reactions
yield(bot.delete_reaction(message, "565171769187500032"), "completed")
yield(bot.delete_reaction(message, "556051807504433152"), "completed")
```

Delete the reaction of the user
```GDScript
# First react to the message with an animated parrot
yield(bot.create_reaction(message, "565171769187500032"), "completed")

# Wait for some time so the user can also react with the same emoji
yield(get_tree().create_timer(2), "timeout")

# Then delete the user's reaction
yield(bot.delete_reaction(message, "565171769187500032", message.author.id), "completed")
```

Delete the reaction of the user as soon as it was reacted to
```GDScript
# This method is connected to the DiscordBot.message_reaction_add signal
func _on_bot_message_reaction_add(bot: DiscordBot, data: Dictionary):
    # Make sure the emoji was a CUSTOM EMOJI
    if !data.emoji.id:
        return

    # Make sure it's not the bot's reaction
    if data.member.user.id == bot.user.id:
        return

    # Delete the user's reaction to the CUSTOM EMOJI
    bot.delete_reaction(data, data.emoji.id, data.member.user.id)
```

### <a name="discordbot-delete-reactions"></a>delete_reactions(message, custom_emoji)
Deletes all reactions of the emoji on the message.
> Returns: Promise<int\>
> 
> Returns the http response code (204 is success).

!!! note
    Only CUSTOM emojis are supported since Godot can't render unicode emojis. Pass only the Id of the custom emoji as the `custom_emoji`.

!!! note
    This requires the `MANAGE_MESSAGES` permission

| Type    | Parameter    | Description                                |
| ------- | ------------ | ------------------------------------------ |
| Variant | message      | The message from which to delete reactions |
| String  | custom_emoji | The custom id of the emoji to delete       |

#### Examples
Delete all reactions on the animated parrot emoji the mesasge
```GDScript
# First react to the message with the animated parrot
yield(bot.create_reaction(message, "565171769187500032"), "completed")

# Wait for some time so the user can also react with the same emoji
yield(get_tree().create_timer(2), "timeout")

# Then delete all reactions to the animated parrot emoji
yield(bot.delete_reactions(message, "565171769187500032"), "completed")
```

### <a name="discordbot-get-reactions"></a>get_reactions(message, custom_emoji)
Returns a list of users that reacted with this emoji.
> Returns: Promise<Array\>

!!! note
    Only CUSTOM emojis are supported since Godot can't render unicode emojis. Pass only the Id of the custom emoji as `custom_emoji`.

| Type    | Parameter    | Description                      |
| ------- | ------------ | -------------------------------- |
| Variant | message      | The message the emoji is present |
| String  | custom_emoji | The custom id of the emoji       |

#### Examples
Get the list of users who reacted to the animated parrot emoji
```GDScript
var user_reacted = yield(bot.get_reactions(message, "565171769187500032"), "completed")
print(user_reacted)

# If you want to convert the data to a User, use the following:
for userdata in user_reacted:
    var user: User = User.new(bot, userdata)
    print(user)
```

### <a name="discordbot-register-command"></a>register_command(command, guild_id?)
Register the command as a global or guild level command.
> Returns: Promise<[[ApplicationCommand]]\>

!!! note
    While developing commands it's better to use guild level commands since they update instantly while global commands take upto 1hr to update.
    See [Discord registering a command docs](https://discord.com/developers/docs/interactions/application-commands#registering-a-command)


| Type                   | Parameter | Description                                                                             |
| ---------------------- | --------- | --------------------------------------------------------------------------------------- |
| [[ApplicationCommand]] | command   | The application command to register                                                     |
| String                 | guild_id  | The id of the guild to register the command. If not specified it will register globally |

#### Examples
Register a global command
```GDScript
var cmd1 = ApplicationCommand.new().set_name("ping").set_description("Check my latency")
bot.register_command(cmd1)
```

Register command for a specific guild
```GDScript
var cmd1 = ApplicationCommand.new().set_name("ping").set_description("Check my latency")

# Register the command for the guild with id "330264450148073474"
bot.register_command(cmd1, "330264450148073474")
```

Register a global command with options (Specific example)
```GDScript
"""
This results in a single command "market" which can be scoped
to multiple resources "fruits" or "vegetables" which can be
further scoped to multiple actions "buy" or "sell".

The action buy vegetable can further be scoped to a fixed
set of values "carrot", "cabbage" or "potato" 
"""

var cmd1 = ApplicationCommand.new()\
            .set_name("market")
            .set_description("Buy or sell items from the market")

# Add a sub command group "fruits" to the command
# which has two sub commands "buy" and "sell"
cmd1.add_option(
    ApplicationCommand.sub_command_group_option("fruits", "Buy or sell some fruits", {
        "options": [
            ApplicationCommand.sub_command_option("buy", "Buy a fruit"),
            ApplicationCommand.sub_command_option("sell", "Sell a fruit"),
        ]
    })
)

# Add a sub command group "vegetables" to the command
# which has two sub commands "buy" and "sell"
# The buy sub command is further limited to "carrot", "cabbage" and "potato"
cmd1.add_option(
    ApplicationCommand.sub_command_group_option("vegetables", "Buy or sell some vegetables", {
        "options": [
            ApplicationCommand.sub_command_option("buy", "Buy a vegetable", {
                "options": [
                    ApplicationCommand.string_option("vegetable", "The vegetable to buy", {
                        "required": true,
                        "choices": [
                            ApplicationCommand.choice("Buy a carrot", "carrot"),
                            ApplicationCommand.choice("Buy a cabbage", "cabbage"),
                            ApplicationCommand.choice("Buy a potato", "potato"),
                        ]
                    })
                ]
            }),
            ApplicationCommand.sub_command_option("sell", "Sell a vegetable")
        ]
    })
)
bot.register_command(cmd1)
```

### <a name="discordbot-register-commands"></a>register_commands(commands, guild_id?)
Bulk register multiple commands as a global or guild level commands.
> Returns: Promise<Array<[[ApplicationCommand]]\>\>

!!! note
    This will overwrite all types of application commands: slash, user and message Application Commands


| Type   | Parameter | Description                                                                              |
| ------ | --------- | ---------------------------------------------------------------------------------------- |
| Array  | commands  | An array of [[ApplicationCommand]] to register                                           |
| String | guild_id  | The id of the guild to register the commands. If not specified it will register globally |

#### Examples
Register three commands globally at once
```GDScript
var cmd1 = ApplicationCommand.new().set_name("ping").set_description("Check my latency")
var cmd2 = ApplicationCommand.new().set_name("help").set_description("Shows some helpful information")
var cmd3 = ApplicationCommand.new().set_name("joke").set_description("Tells a joke")
bot.register_commands([cmd1, cmd2, cmd3])
```

Register three commands for a guild at once
```GDScript
var cmd1 = ApplicationCommand.new().set_name("ping").set_description("Check my latency")
var cmd2 = ApplicationCommand.new().set_name("help").set_description("Shows some helpful information")
var cmd3 = ApplicationCommand.new().set_name("joke").set_description("Tells a joke")

# Register the commands for the guild with id "330264450148073474"
bot.register_commands([cmd1, cmd2, cmd3], "330264450148073474")
```

### <a name="discordbot-delete-command"></a>delete_command(command_id, guild_id?)
Delete a global or guild level command.
> Returns: Promise<int\>
> 
> Returns the HTTP response code (204 is success).


| Type   | Parameter  | Description                                                                                          |
| ------ | ---------- | ---------------------------------------------------------------------------------------------------- |
| String | command_id | The id of command to delete                                                                          |
| String | guild_id   | The id of the guild to delete the command from. If not specified it will delete the command globally |

#### Examples
Delete a global command
```GDScript
# Delete command with id "123456789"
bot.delete_command("123456789")
```

### <a name="discordbot-delete-commands"></a>delete_commands(guild_id?)
Deletes all global or guild level commands.
> Returns: Promise<int\>
> 
> Returns the HTTP response code (204 is success).


| Type   | Parameter | Description                                                                                            |
| ------ | --------- | ------------------------------------------------------------------------------------------------------ |
| String | guild_id  | The id of the guild to delete all commands from. If not specified it will delete all commands globally |

#### Examples
Delete all global commands
```GDScript
bot.delete_commands()
```

Delete all commands for a specific guild
```GDScript
# Delete all commands for the guild with id "330264450148073474"
bot.delete_commands("330264450148073474")
```

### <a name="discordbot-get-command"></a>get_command(command_id, guild_id?)
Fetch a global or guild level command.
> Returns: Promise<[[ApplicationCommand]]\>

| Type   | Parameter  | Description                                                                            |
| ------ | ---------- | -------------------------------------------------------------------------------------- |
| String | command_id | The id of the command to fetch                                                         |
| String | guild_id   | The id of the guild to fetch from. If not specified it will fetch from global commands |


### <a name="discordbot-get-commands"></a>get_commands(guild_id?)
Fetch all global or guild level commands.
> Returns: Promise<Array<[[ApplicationCommand]]\>\>

| Type   | Parameter | Description                                                                           |
| ------ | --------- | ------------------------------------------------------------------------------------- |
| String | guild_id  | The id of the guild to fetch from. If not specified it will fetch all global commands |