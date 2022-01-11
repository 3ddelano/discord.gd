---
title: Class DiscordInteraction
tags:
  - discord-interaction, class
---

# DiscordInteraction
Extends: None

```
Represents a Discord interaction.
```

## Description
Provides methods for replying, updating and follow up to interactions.

## Properties
| Type       | Name           | Description                                                       |
| ---------- | -------------- | ----------------------------------------------------------------- |
| String     | application_id | The application's id                                              |
| String     | channel_id     | The id of the channel this interaction was sent in                |
| String     | guild_id       | The id of the guild this interaction was sent in                  |
| String     | id             | The interaction's id                                              |
| Dictionary | member         | If this interaction was sent in a guild, the member which sent it |
| Message    | message        | For components, the message they were attached to                 |
| String     | token          | The interaction's token                                           |
| String     | type           | The interaction's type                                            |
| Dictionary | data           | Additional data of this interaction                               |

## Methods
| Returns | Definition                                                                                  |
| ------- | ------------------------------------------------------------------------------------------- |
| Variant | [defer_reply(options: Dictionary)](#discordinteraction-defer-reply)                         |
| Variant | [defer_update(options: Dictionary)](#discordinteraction-defer-update)                       |
| Variant | [delete_follow_up(message: Message)](#discordinteraction-delete-follow-up)                  |
| Variant | [delete_reply()](#discordinteraction-delete-reply)                                          |
| Variant | [edit_follow_up(message: Message, options: Dictionary)](#discordinteraction-edit-follow-up) |
| Variant | [edit_reply(options: Dictionary)](#discordinteraction-edit-reply)                           |
| Message | [fetch_reply()](#discordinteraction-fetch-reply)                                            |
| Variant | [follow_up(options: Dictionary)](#discordinteraction-follow-up)                             |
| bool    | [in_guild()](#discordinteraction-in-guild)                                                  |
| bool    | [is_button()](#discordinteraction-is-button)                                                |
| bool    | [is_message_component()](#discordinteraction-is-message-component)                          |
| bool    | [is_select_menu()](#discordinteraction-is-select-menu)                                      |
| bool    | [is_command()](#discordinteraction-is-command)                                              |
| bool    | [is_autocomplete()](#discordinteraction-is-autocomplete)                                    |
| bool    | [respond_autocomplete(choices: Array)](#discordinteraction-respond-autocomplete)            |
| Variant | [reply(options: Dictionary)](#discordinteraction-reply)                                     |
| Variant | [update(options: Dictionary)](#discordinteraction-update)                                   |

## Method Descriptions
### <a name="discordinteraction-is-message-component"></a>is_message_component()
Indicates whether this interaction is a message component.
> Returns: bool

### <a name="discordinteraction-is-button"></a>is_button()
Indicates whether this interaction is a button interaction.
> Returns: bool

### <a name="discordinteraction-is-select-menu"></a>is_select_menu()
Indicates whether this interaction is a select menu interaction.
> Returns: bool

### <a name="discordinteraction-is-command"></a>is_command()
Indicates whether this interaction is an application command interaction.
> Returns: bool

### <a name="discordinteraction-is-autocomplete"></a>is_autocomplete()
Indicates whether this interaction is an application command autocomplete interaction.
> Returns: bool

### <a name="discordinteraction-respond-autocomplete"></a>respond_autocomplete(choices)
Responds to an autocomplete interaction with suggested choices.
> Returns: bool
> Returns `true` if successful otherwise `false`.

<small>See [Discord responding to autocomplete](https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-response-object-autocomplete)</small>


| Type  | Parameter | Description          |
| ----- | --------- | -------------------- |
| Array | choices   | The array of choices |

#### Examples
Always respond with two choices
```GDScript
# In DiscordBot.interaction_create
if interaction.is_autocomplete():
var data = interaction.data
print("Autocomplete data: ", data)

# In a real situation you would send different choices based on the current input of the user,
# which can be found in interaction.data
interaction.respond_autocomplete([
    ApplicationCommand.choice("Name of the choice 1", "value1"),
    ApplicationCommand.choice("Name of the choice 2", "value2"),
])
return
```


### <a name="discordinteraction-in-guild"></a>in_guild()
Indicates whether this interaction is received from a guild.
> Returns: bool

### <a name="discordinteraction-fetch-reply"></a>fetch_reply()
Fetches the initial reply to this interaction.
> Returns: Promise<Message>

### <a name="discordinteraction-reply"></a>reply(options)
Creates a reply to this interaction.
> Returns: Variant

| Type       | Parameter | Description                   |
| ---------- | --------- | ----------------------------- |
| Dictionary | options   | The options for the new reply |

!!! note
    Here the options means the message options. Like embeds, components, content, files, etc.
    The two new keys are `fetch_reply` and `ephemeral`.

    If `fetch_reply` is true, the function will return a Promsise<[[Message]]> otherwise the function will return `true`.

options: Dictionary
```GDScript
{
    fetch_reply: bool, whether to return the new reply or not,
    ephemeral: bool, whether the reply should be ephemeral or not,
    files: Array, the files to attach to the new reply,
    embeds: Array, the embeds to attach to the new reply,
    content: String, the content of the new reply,
    components: Array, the components to attach to the new reply
}
```

### <a name="discordinteraction-edit-reply"></a>edit_reply(options)
Edits the initial reply to this interaction.
> Returns: Variant

!!! note
    options is same as `DiscordInteraction.reply()` options.

### <a name="discordinteraction-delete-reply"></a>delete_reply()
Deletes the initial reply to this interaction.
> Returns: void

### <a name="discordinteraction-defer-reply"></a>defer_reply(options)
Defers the reply to this interaction.
> Returns: Variant

!!! note
    options is same as `DiscordInteraction.reply()` options.

#### Examples
Defer to send an ephemeral reply later
```GDScript
yield(interaction.defer_reply({"ephemeral": true}), "completed")
```

### <a name="discordinteraction-update"></a>update(options)
Updates the original message of the component on which the interaction was received on.
> Returns: Variant

!!! note
    options is same as `DiscordInteraction.reply()` options.

#### Examples
Remove the components from the message
```GDScript
yield(interaction.update({
    "components": [],
    "content": "Components are removed"
}), "completed")
``` 

### <a name="discordinteraction-follow-up"></a>follow_up(options)
Send a follow-up message to this interaction.
> Returns: Variant

!!! note
    options is same as `DiscordInteraction.reply()` options.


### <a name="discordinteraction-edit-follow-up"></a>edit_follow_up(message, options)
Edits a follow-up message to this interaction.
> Returns: Variant

!!! note
    options is same as `DiscordInteraction.reply()` options.

| Type        | Parameter | Description                                                     |
| ----------- | --------- | --------------------------------------------------------------- |
| [[Message]] | message   | The sent follow up message to edit                              |
| Dictionary  | options   | Additional options same as `DiscordInteraction.reply()` options |

### <a name="discordinteraction-delete-follow-up"></a>delete_follow_up(message)
Deletes a follow-up message to this interaction.
> Returns: Variant
 
| Type    | Parameter | Description                          |
| ------- | --------- | ------------------------------------ |
| Message | message   | The sent follow up message to delete |

#### Examples
Delete a sent follow up
```GDScript
# inside interaction_create signal

# Send a follow up
var msg = yield(interaction.follow_up({"content": "This will be deleted soon"}), "completed")

# Wait 5s
yield(get_tree().create_timer(5), "timeout")

# Delete the follow up
interaction.delete_follow_up(msg)
```
