---
title: Class User
tags:
  - user, class
---

# User
Extends: None

```
Represents a user on Discord.
```

## Description
Stores all the data related to a user from Discord. It also has a few methods to manage the user data. 

## Properties
<small>See [Discord User Structure](https://discord.com/developers/docs/resources/user#user-object-user-structure)</small>

| Type   | Name          | Description                                                                                                                                                        |
| ------ | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| String | id            | The id of the user                                                                                                                                                 |
| String | username      | The username of the user                                                                                                                                           |
| String | discriminator | The discriminator of the user                                                                                                                                      |
| String | avatar        | The avatar hash of the user                                                                                                                                        |
| bool   | bot           | Whether or not the user is a bot                                                                                                                                   |
| bool   | system        | Wheter or not the user is an Official Discord System user                                                                                                          |
| bool   | mfa_enabled   | Whether or not the user has two factor enabled on their account                                                                                                    |
| String | locale        | The chosen language of the user                                                                                                                                    |
| bool   | verified      | Whether or not user's email is verified                                                                                                                            |
| String | email         | The email of the user                                                                                                                                              |
| int    | flags         | The flags of the user <small>(See [Discord User Flags](https://discord.com/developers/docs/resources/user#user-object-user-flags))</small>                         |
| int    | premium_type  | The type of Nitro subscription of the user <small>(See [Discord Premium Types](https://discord.com/developers/docs/resources/user#user-object-user-flags))</small> |
| int    | public_flags  | The public flags of the user <small>(See [Discord User Flags](https://discord.com/developers/docs/resources/user#user-object-user-flags))</small>                  |

## Methods
| Returns       | Definition                                                                   |
| ------------- | ---------------------------------------------------------------------------- |
| PoolByteArray | [get_default_avatar()](#user-get-default-avatar)                             |
| String        | [get_default_avatar_url()](#user-get-default-avatar-url)                     |
| PoolByteArray | [get_display_avatar(options?: Dictionary)](#user-get-display-avatar)         |
| String        | [get_display_avatar_url(options?: Dictionary)](#user-get-display-avatar-url) |

## Method Descriptions
### <a name="user-get-display-avatar-url"></a>get_display_avatar_url(options?)
Returns the url of the user's avatar icon
> Returns: String

!!! note
        If the user has no avatar, the default avatar url will be returned

options: Dictionary 
```GDScript
{
    format: String, one of "webp", "png", "jpg", "jpeg", "gif" (default "png"),
    size: int, one of 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 (default 256),
    dynamic: bool, if true the format will automatically change to gif 
    for animated avatars (default false)
}
```

#### Examples
Get the user's avatar and use in an embed
```GDScript
var avatar_url = message.author.get_display_avatar_url()
var embed = Embed.new().set_image(avatar_url)
bot.send(message, {"embeds": [embed]})
```

### <a name="user-get-default-avatar-url"></a>get_default_avatar_url()
Returns the url of the user's default avatar icon
> Returns: String

### <a name="user-get-display-avatar"></a>get_display_avatar(options?)
Returns the raw bytes of the user's avatar icon
> Returns: Promise<PoolByteArray>

!!! note
    To get the avatar as an `Image` or `ImageTexture` use [[helpers#helpers-to-png-image|Helpers.to_png_image()]] and [[helpers#helpers-to-image-texture|Helpers.to_image_texture()]]

!!! note
    If the user has no avatar set, the default avatar will be returned

options: Dictionary 
```GDScript
{
    format: String, one of "webp", "png", "jpg", "jpeg", "gif" (default "png"),
    size: int, one of 16, 32, 64, 128, 256, 512, 1024, 2048, 4096 (default 256),
    dynamic: bool, if true the format will automatically change to gif for animated avatars (default false)
}
```

#### Examples
Get the user's avatar as a PNG ImageTexture
```GDScript
# Note: The yield is to ensure that the avatar is received
var bytes = yield(user.get_display_avatar(), "completed")

# Convert the bytes to an Image
var image = Helpers.to_png_image(bytes)

# Convert the Image to ImageTexture
var texture = Helpers.to_image_texture(image)
```

Gets the user's avatar as a GIF automatically
```GDScript
# Gets the GIF bytes if the user has an animated avatar
var bytes = yield(user.get_display_avatar({
    "dynamic": true
}), "completed")

# Reply with the user's avatar as a GIF
bot.reply(message, {
    "content": "Your avatar is...",
    "files": [
        {
            "name": "avatar.gif",
            "media_type": "image/gif",
            "data": bytes
        }
    ]
})
```

### <a name="user-get-default-avatar"></a>get_default_avatar()
Returns the raw bytes of the user's default avatar icon
> Returns: Promise<PoolByteArray>

!!! note
    To get the avatar as an `Image` or `ImageTexture` use [[helpers#helpers-to-png-image|Helpers.to_png_image()]] and [[helpers#helpers-to-image-texture|Helpers.to_image_texture()]]
