---
title: Class Embed
tags:
  - embed, class
---

# Embed
Extends: None

```
Wrapper for an Embed on Discord
```

## Description
Contains all the data of an embed. It also has a few chainable methods to make creating embeds easy

## Properties
<small>See [Discord Embed Stucture](https://discord.com/developers/docs/resources/channel#embed-object-embed-structure)</small>

| Type       | Name        | Description                                                                                                                                                          |
| ---------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| String     | title       | The title of the Embed                                                                                                                                               |
| String     | type        | The type of the Embed (default is `rich`) <small>(See [Discord Embed Types](https://discord.com/developers/docs/resources/channel#embed-object-embed-types))</small> |
| String     | description | The description of the Embed                                                                                                                                         |
| String     | url         | The url of the Embed                                                                                                                                                 |
| String     | timestamp   | The ISO8601 timestamp of the Embed (or null)                                                                                                                         |
| int        | color       | The color code of the Embed                                                                                                                                          |
| Dictionary | footer      | Footer information                                                                                                                                                   |
| Dictionary | image       | Image information                                                                                                                                                    |
| Dictionary | thumbnail   | Thumbnail information                                                                                                                                                |
| Dictionary | video       | Video information                                                                                                                                                    |
| Dictionary | provider    | Provider information                                                                                                                                                 |
| Dictionary | author      | Author information                                                                                                                                                   |
| Array      | fields      | The fields of the embed                                                                                                                                              |

footer: Dictionary <small>(See [Discord Embed Footer Structure](https://discord.com/developers/docs/resources/channel#embed-object-embed-footer-structure))</small>
```GDScript
{
    text: String, text of the footer,
    icon_url?: String, url of footer icon,
    proxy_url?: String, proxied url of footer icon
}
```

image: Dictionary <small>(See [Discord Embed Image Structure](https://discord.com/developers/docs/resources/channel#embed-object-embed-image-structure))</small>
```GDScript
{
    url?: String, source url of image,
    proxy_url?: String, proxied url of image,
    height?: int, height of image,
    width?: int, width of image
}
```

thumbnail: Dictionary <small>(See [Discord Embed Thumbnail Structure](https://discord.com/developers/docs/resources/channel#embed-object-embed-thumbnail-structure))</small>
```GDScript
{
    url?: String, source url of thumbnail,
    proxy_url?: String, proxied url of thumbnail,
    height?: int, height of thumbnail,
    width?: int, width of thumbnail
}
```

video: Dictionary <small>(See [Discord Embed Video Structure](https://discord.com/developers/docs/resources/channel#embed-object-embed-video-structure))</small>
```GDScript
{
    url?: String, source url of video,
    proxy_url?: String, proxied url of video,
    height?: int, height of video,
    width?: int, width of video
}
```

provider: Dictionary <small>(See [Discord Embed Provider Structure](https://discord.com/developers/docs/resources/channel#embed-object-embed-provider-structure))</small>
```GDScript
{
    name?: String, name of provider
    url?: String, url of provider,
}
```

author: Dictionary <small>(See [Discord Embed Author Structure](https://discord.com/developers/docs/resources/channel#embed-object-embed-author-structure))</small>
```GDScript
{
    name?: String, name of author,
    url?: String, url of author,
    icon_url?: String, url of author icon,
    proxy_url?: String, proxied url of author icon
}
```

Each field: Dictionary <small>(See [Discord Embed Field Structure](https://discord.com/developers/docs/resources/channel#embed-object-embed-field-structure))</small>
```GDScript
{
    name: String, name of the field,
    value: String, value of the field,
    inline?: bool, whether or not this field should display inline
}
```

## Methods
| Returns | Definition                                                                                              |
| ------- | ------------------------------------------------------------------------------------------------------- |
| Embed   | [add_field(name: String, value: String, inline?: bool)](#embed-add-field)                               |
| void    | [print()](#embed-print)                                                                                 |
| Embed   | [set_author(name: String, url?: String, icon_url?: String, proxy_icon_url?: String)](#embed-set-author) |
| Embed   | [set_color(color: Variant)](#embed-set-color)                                                           |
| Embed   | [set_description(description: String)](#embed-set-description)                                          |
| Embed   | [set_footer(text: String, icon_url?: String, proxy_icon_url?: String)](#embed-set-footer)               |
| Embed   | [set_image(url: String, width?: int, height?: int, proxy_url?: String)](#embed-set-image)               |
| Embed   | [set_provider(name: String, url?: String)](#embed-set-provider)                                         |
| Embed   | [set_thumbnail(url: String, width?: int, height?: int, proxy_url?: String)](#embed-set-thumbnail)       |
| Embed   | [set_timestamp(timestamp: String)](#embed-set-timestamp)                                                |
| Embed   | [set_title(title: String)](#embed-set-title)                                                            |
| Embed   | [set_type(type: String)](#embed-set-type)                                                               |
| Embed   | [set_url(url: String)](#embed-set-url)                                                                  |
| Embed   | [set_video(url: String, width?: int, height?: int, proxy_url?: String)](#embed-set-video)               |
| Embed   | [slice_fields(index: int, delete_count?: int, replace_fields?: Array)](#embed-slice-fields)             |

!!! note
    Getters are also defined for the above functions which all return Dictionary

!!! note
    All setter methods and `add_fields()` return the Embed itself, so chaining of methods is possible

## Method Descriptions
### <a name="embed-set-title"></a>set_title(title)
Sets the title of the Embed
> Returns: Embed

| Type   | Parameter |
| ------ | --------- |
| String | title     |


### <a name="embed-set-type"></a>set_type(type)
Sets the type of the Embed
> Returns: Embed

| Type   | Parameter |
| ------ | --------- |
| String | type      |

### <a name="embed-set-description"></a>set_description(description)
Sets the description of the Embed
> Returns: Embed

| Type   | Parameter   |
| ------ | ----------- |
| String | description |


### <a name="embed-set-url"></a>set_url(url)
Sets the url of the Embed
> Returns: Embed

| Type   | Parameter |
| ------ | --------- |
| String | url       |


### <a name="embed-set-timestamp"></a>set_timestamp()
Sets the timestamp of the Embed to the current unix timestamp
> Returns: Embed

#### Examples
Set the timestamp of an embed to the current ISO8601 timestamp

```GDScript
var embed = Embed.new().set_timestamp()
```

### <a name="embed-set-color"></a>set_color(color)
Sets the color of the Embed
> Returns: Embed

| Type                   | Parameter | Description                                              |
| ---------------------- | --------- | -------------------------------------------------------- |
| Array \| String \| int | color     | Supports RGB array, HEX string or decimal representation |

#### Examples
An rgb color
```GDScript
var embed = Embed().new().set_color([255, 0, 255])
```

A hex color
```GDScript
var embed = Embed().new().set_color("#ff55ff")
```

A decimal color
```GDScript
var embed = Embed().new().set_color(16711935)
```

### <a name="embed-set-footer"></a>set_footer(text, icon_url?, proxy_icon_url?)
Sets the footer of the Embed
> Returns: Embed

| Type   | Parameter      | Description                    |
| ------ | -------------- | ------------------------------ |
| String | text           | The text of the footer         |
| String | icon_url       | The url of footer icon         |
| String | proxy_icon_url | The proxied url of footer icon |

### <a name="embed-set-image"></a>set_image(url, width?, height?, proxy_url?)
Sets the image of the Embed
> Returns: Embed

| Type   | Parameter | Description                    |
| ------ | --------- | ------------------------------ |
| String | url       | The url of embed image         |
| int    | width     | The width of embed image       |
| int    | height    | The height url of embed image  |
| String | proxy_url | The proxied url of embed image |

### <a name="embed-set-thumbnail"></a>set_thumbnail(url, width?, height?, proxy_url?)
Sets the thumbnail of the Embed
> Returns: Embed
> 
| Type   | Parameter | Description                        |
| ------ | --------- | ---------------------------------- |
| String | url       | The url of embed thumbnail         |
| int    | width     | The width of embed thumbnail       |
| int    | height    | The height url of embed thumbnail  |
| String | proxy_url | The proxied url of embed thumbnail |

### <a name="embed-set-video"></a>set_video(url, width?, height?, proxy_url?)
Sets the video of the Embed
> Returns: Embed

| Type   | Parameter | Description                    |
| ------ | --------- | ------------------------------ |
| String | url       | The url of embed video         |
| int    | width     | The width of embed video       |
| int    | height    | The height url of embed video  |
| String | proxy_url | The proxied url of embed video |

### <a name="embed-set-provider"></a>set_provider(name, url?)
Sets the provider of the Embed
> Returns: Embed

| Type   | Parameter | Description                |
| ------ | --------- | -------------------------- |
| String | name      | The name of embed provider |
| String | url       | The url of embed provider  |

### <a name="embed-set-author"></a>set_author(name, url?, icon_url?, proxy_icon_url?)
Sets the author of the Embed
> Returns: Embed

| Type   | Parameter      | Description                    |
| ------ | -------------- | ------------------------------ |
| String | name           | The name of embed author       |
| String | url            | The url of embed author        |
| String | icon_url       | The url of author icon         |
| String | proxy_icon_url | The proxied url of author icon |

#### Examples
Set the author of an Embed
```GDScript
var embed = Embed.new().set_author("Delano Lourenco", "https://url_to_image_file.png")
```

### <a name="embed-add-field"></a>add_field(name, value, inline?)
Sets the field of the Embed
> Returns: Embed

!!! note
    An Embed can have a max of 25 fields

| Type   | Parameter | Description                                     |
| ------ | --------- | ----------------------------------------------- |
| String | name      | The name of the embed field                     |
| String | value     | The value of the  embed field                   |
| bool   | inline    | Whether or not this field should display inline |

#### Examples
Add multiple fields to an Embed
```GDScript
# Make the embed
var embed = Embed.new()
embed.add_field("field 1", "text 1")
embed.add_field("field 2", "text 2")
embed.add_field("field 3", "inline text 1", true) # inline
embed.add_field("field 4", "inline text 1", true) # inline

# Send the embed
bot.send(message, {"embeds": [embed]})
```

### <a name="embed-slice-fields"></a>slice_fields(index, delete_count?, replace_fields?)
Removes, replaces, and inserts fields in the Embed.
> Returns: Embed

| Type  | Parameter      | Defaults | Description                                                     |
| ----- | -------------- | -------- | --------------------------------------------------------------- |
| int   | index          | Required | The index of the first field in the Embeds.fields to be removed |
| int   | delete_count   | 1        | The number of fields to remove                                  |
| Array | replace_fields | []       | The replacing fields, an array of Dictionary(field)             |

Dictionary(field): Dictionary
```GDScript
{
    name: String, name of the field,
    value: String, value of the field,
    inline?: bool, whether or not this field should display inline
}
```

### <a name="embed-print"></a>print()
Prints the Embed
> Returns: void

!!! note
    To print an Embed, use Embed.print() instead of print(Embed)
