---
title: Class MessageButton
tags:
  - message-button, class
---
# MessageButton
Extends: None

```
Represents a button message component.
```
See <small>[Discord Button docs](https://discord.com/developers/docs/interactions/message-components#buttons)</small>

## Description
Provides methods for customising a message button.

## Enums
### STYLES
```GDScript
{
    DEFAULT,
    PRIMARY,
    SECONDARY,
    SUCCESS,
    DANGER,
    LINK
}
```

## Properties
| Type       | Name      | Description                              |
| ---------- | --------- | ---------------------------------------- |
| String     | custom_id | The custom_id of the button              |
| String     | label     | The label of the button                  |
| String     | url       | The url of the button (LINK button only) |
| bool       | disabled  | Whether the button is disabled or not    |
| Dictionary | emoji     | The emoji of the button                  |

## Methods
| Returns       | Definition                                                              |
| ------------- | ----------------------------------------------------------------------- |
| MessageButton | [set_style(style_type: MessageButton.STYLES)](#messagebutton-set-style) |
| String        | [get_style()](#messagebutton-get-style)                                 |
| MessageButton | [set_label(new_label: String)](#messagebutton-set-label)                |
| String        | [get_label()](#messagebutton-get-label)                                 |
| MessageButton | [set_custom_id(new_custom_id: String)](#messagebutton-set-custom-id)    |
| String        | [get_custom_id()](#messagebutton-get-custom-id)                         |
| MessageButton | [set_url(new_url: String)](#messagebutton-set-url)                      |
| String        | [get_url()](#messagebutton-get-url)                                     |
| MessageButton | [set_disabled(new_value: bool)](#messagebutton-set-disabled)            |
| bool          | [get_disabled()](#messagebutton-get-disabled)                           |
| MessageButton | [set_emoji(new_emoji: Dictionary)](#messagebutton-set-emoji)            |
| Dictionary    | [get_emoji()](#messagebutton-get-emoji)                                 |
| void          | [print()](#messagebutton-print)                                         |

## Method Descriptions
### <a name="messagebutton-set-style"></a>set_style(style_type)
Sets the style of the button.
> Returns: MessageButton

#### Examples
Set the button style to LINK
```GDScript
var button = MessageButton.new().set_style(MessageButton.STYLES.LINK)
```
### <a name="messagebutton-get-style"></a>get_style()
Returns the style of the button.
> Returns: String

### <a name="messagebutton-set-label"></a>set_label(new_label)
Sets the label of the button.
> Returns: MessageButton

| Type   | Parameter |
| ------ | --------- |
| String | new_label |

#### Examples
Set the button label to "Click Me"
```GDScript
var button = MessageButton.new().set_label("Click Me")
```
### <a name="messagebutton-get-label"></a>get_label()
Returns the label of the button.
> Returns: String

### <a name="messagebutton-set-custom-id"></a>set_custom_id(new_custom_id)
Sets the custom_id of the button.
> Returns: MessageButton

| Type   | Parameter     |
| ------ | ------------- |
| String | new_custom_id |

#### Examples
Set the button custom_id to "primary_button"
```GDScript
var button = MessageButton.new().set_custom_id("primary_button")
```
### <a name="messagebutton-get-custom-id"></a>get_custom_id()
Returns the custom_id of the button.
> Returns: String

### <a name="messagebutton-set-url"></a>set_url(new_url)
Sets the url of the button.
> Returns: MessageButton

| Type   | Parameter |
| ------ | --------- |
| String | new_url   |

### <a name="messagebutton-get-url"></a>get_url()
Returns the url of the button.
> Returns: String

### <a name="messagebutton-set-disabled"></a>set_disabled(new_value)
Sets the disabled state of the button.
> Returns: MessageButton

| Type | Parameter |
| ---- | --------- |
| bool | new_value |

### <a name="messagebutton-get-disabled"></a>get_disabled()
Returns whether the button is disabled or not.
> Returns: bool

### <a name="messagebutton-set-emoji"></a>set_emoji(new_emoji)
Sets the emoji of the button.

new_emoji: Dictionary <small>See [Discord Emoji Structure](https://discord.com/developers/docs/resources/emoji#emoji-object-emoji-structure)</small>
```GDScript
{
    id: Id of the custom emoji,
    name?: Name of the custom emoji
}
```

!!! note
    This works only for Custom Emojis. The default ASCII emojis will not work. Its a limitation of Godot.

!!! note "Workaround for button emojis"
    If you want to use the default ASCII emojis as an emoji for the button.
    <br> 1. Add the emoji you want as a `custom emoji` on any server
    <br> 2. Get the `emoji id` of the `custom emoji`
    <br> 3. Use this id in the id field of the `MessageButton.set_emoji()` (See examples below)  

#### Examples
Send a green checkmark emoji button
```GDScript
var checkmark_button = MessageButton.new()
checkmark_button.set_style(MessageButton.STYLES.SECONDARY)
checkmark_button.set_custom_id("abcde")

# This id is a custom emoji id on the 3ddelano Cafe server
checkmark_button.set_emoji({"id": "556051807504433152"})

var row = MessageActionRow.new().add_component(checkmark_button)
bot.send(message.channel_id, {
    "content": "This is a emoji button",
    "components": [row]
})
```

Send an animated parrot emoji button
```GDScript
var parrot_button = MessageButton.new()
parrot_button.set_style(MessageButton.STYLES.SECONDARY)
parrot_button.set_custom_id("abcdefgh")

# This id is a custom animated emoji id on the 3ddelano Cafe server
parrot_button.set_emoji({"id": "565171769187500032"})

var row = MessageActionRow.new().add_component(parrot_button)
bot.send(message.channel_id, {
    "content": "This is an animated emoji button",
    "components": [row]
})
```

### <a name="messagebutton-get-emoji"></a>get_emoji()
Get the emoji of the button if it has one.
> Returns: Dictionary

### <a name="messagebutton-print"></a>print()
Prints the MessageButton.
> Returns: void

!!! note
    Use this instead of `print(MessageButton)`

## Handling MessageButton Interactions
MessageButton interactions are received via the `DiscordBot.interaction_create` signal.

```GDScript
func _on_interaction_create(bot, interaction: DiscordInteraction):
    # Make sure the interaction is only from a MessageButton
    if not interaction.is_button():
        return
    
     # Get the custom_id of the button
    var custom_id = interaction.data.custom_id

    match custom_id:
        "my_button1":
            # Handle my_button1 logic here
            interaction.reply({
               "content": "You pressed my_button1"
            })

        "other_button2":
            # Handle other_button2 logic here
            ...
```
