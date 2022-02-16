Changelog
============

This is a high-level changelog for each released versions of the plugin.
For a more detailed list of past and incoming changes, see the commit history.

Master
------
- Fix JSON parsing error on empty data object in `DiscordBot._jsonstring_to_dict()`
- Add not null check in DiscordBot._send_get()

1.2.1
------
- Fixed Embed.set_color() for an array of RGB values
- Moved documentation to [Discord.gd](https://3ddelano.github.io/discord.gd)
- Added `DiscordBot.guild_update` signal
- Added `Helpers.iso2unix()` method
- Fixed `DiscordBot.get_guild_icon()` used to crash the bot if guild had no icon. 

1.2.0
------
- Fixed some bugs in `DiscordInteraction` regarding updating the message of interaction.
- Fixed typo in SelectMenu

1.1.9
------
### Implemented application commands (CHAT_INPUT / USER / MESSAGE commands) and also autocomplete response for application commands
- Added `is_command()`, `is_autocomplete()` and `respond_autocomplete()` methods to `DiscordInteraction`
- Added `register_command()`, `register_commands()`, `delete_command()`, `delete_commands()`, `get_command()` and `get_commands()` methods to `DiscordBot`
- Added class `ApplicationCommand`
- Made data argument in `SelectMenu.add_option()` optional

1.1.8
------
### Implemented select menus
- Added class `SelectMenu`
- Added helper method `Helpers.assert_length()`

1.1.7
------
### Implemented reactions (CUSTOM REACTIONS ONLY)
- Fixed `DiscordBot.edit()` was not updating `Message.attachments` properly
- Added `DiscordBot.create_reaction()`
- Added `DiscordBot.delete_reaction()`
- Added `DiscordBot.delete_reactions()`
- Added `DiscordBot.get_reactions()`
- Added signal `DiscordBot.message_reaction_add`
- Added signal `DiscordBot.message_reaction_remove`
- Added signal `DiscordBot.message_reaction_remove_all`
- Added signal `DiscordBot.message_reaction_remove_emoji`
    
1.1.6
------
- Fixed `DiscordBot.delete()` (Wasn't deleting the message)

1.1.5
------
- Added `DiscordBot.create_dm_channel()`
- Added `DiscordBot.get_guild_emojis()`
- Added emoji support for `MessageButton`

1.1.4
------
- Added `DiscordBot.get_guild_member()`
- Added `DiscordBot.add_member_role()`
- Added `DiscordBot.remove_member_role()`

1.1.3
------
- Updated `DiscordBot.send` to accept the channel_id or a `Message`
- Added `DiscordBot.permissions_in()` to get bot permissions in a channel
- Added `DiscordBot.permissions_for()` to get permmissions for a specific user (currently only Bot works)
  
1.1.2
------
- Added support for 4096 size in `DiscordBot.get_guild_icon()`
- Added support for 4096 size in `User.get_display_avatar()`
- Fixed dynamic option in `User.get_display_avatar()`
- Fixed a bug where `Message` did not store components.
- Added `DiscordInteraction.delete_follow_up(message: Message)` to delete a sent follow up message.
- Certain functions now use `push_error()` instead of `assert()` so that the program doesn't stop is an error occurs.

1.1.1
------
- Fixed User.get_display_avatar() was not returning PoolByteArray
- Fixed User.get_default_avatar() was not returning PoolByteArray

1.1.0
------
### Major Release (Added support for components)
- Added support for button components
- Added classes DiscordInteraction, MessageActionRow and MessageButton
- Added class MessageFlags for Message.flags
- Fixed a bug where bot would automatically login without calling the .login() method

1.0.3
------
- Added User.get_display_avatar_url()
- Added User.get_default_avatar_url()

1.0.2
------
- Fixed bug where bot crashes if no avatar is set
- If bot gets ratelimited, it now waits until the message is sent

1.0.1
------
- Bot will try to reconnect every 5s if initially there is no internet
- Added support to delete messages. DiscordBot.delete()
- Fixed bot crashing when only stickers were sent
- Made Helpers.make_iso_string() more efficient
- Fixed typo parsing options in User.get_display_avatar

1.0.0
------
- Initial version