Changelog
============

This is a high-level changelog for each released versions of the plugin.
For a more detailed list of past and incoming changes, see the commit history.

Master
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