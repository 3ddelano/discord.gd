---
title: Class ApplicationCommand
tags:
  - application-command, class
---

# ApplicationCommand
Extends: None

<small>See [Discord ApplicationCommand docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-structure)</small>

```
Represents a Discord application command.
```

## Description
Provides an interface to make and respond to Discord application commands.

## Properties
| Type   | Name               | Description                                                                  |
| ------ | ------------------ | ---------------------------------------------------------------------------- |
| String | name               | The name of this command                                                     |
| String | description        | The description of this command                                              |
| int    | type?              | The type of the command (one of 1, 2, 3)                                     |
| String | id                 | The id of the command                                                        |
| String | application_id     | The id of the parent application                                             |
| String | guild_id?          | The guild id of the command, if not global                                   |
| Array  | options            | The parameters for the command (only for `CHAT_INPUT` commands)              |
| bool   | default_permission | Whether the command is enabled by default (default is `true`)                |
| String | version            | Autoincrementing version identifier updated during substantial record hanges |

## Methods
| Returns             | Definition                                                                                                                              |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| String              | [get_id()](#applicationcommand-get-id)                                                                                                  |
| String              | [get_type()](#applicationcommand-get-type)                                                                                              |
| ApplicationCommand  | [set_type(new_type: String)](#applicationcommand-set-type)                                                                              |
| String              | [get_application_id()](#applicationcommand-get-application-id)                                                                          |
| ApplicationCommand  | [set_name(new_name: String)](#applicationcommand-set-name)                                                                              |
| String              | [get_name()](#applicationcommand-get-name)                                                                                              |
| ApplicationCommand  | [set_description(new_description: String)](#applicationcommand-set-description)                                                         |
| String              | [get_description()](#applicationcommand-get-description)                                                                                |
| String              | [get_guild_id()](#applicationcommand-get-guild-id)                                                                                      |
| ApplicationCommand  | [set_options(new_options: Array\<Dictionary\>)](#applicationcommand-set-options)                                                        |
| Array\<Dictionary\> | [get_options()](#applicationcommand-get-options)                                                                                        |
| ApplicationCommand  | [add_option(option_data: Dictionary)](#applicationcommand-add-option)                                                                   |
| Dictionary          | [`static` sub_command_option(name: String, description: String, data?: Dictionary)](#applicationcommand-sub-command-option)             |
| Dictionary          | [`static` sub_command_group_option(name: String, description: String, data?: Dictionary)](#applicationcommand-sub-command-group-option) |
| Dictionary          | [`static` string_option(name: String, description: String, data?: Dictionary)](#applicationcommand-string-option)                       |
| Dictionary          | [`static` integer_option(name: String, description: String, data?: Dictionary)](#applicationcommand-integer-option)                     |
| Dictionary          | [`static` boolean_option(name: String, description: String, data?: Dictionary)](#applicationcommand-boolean-option)                     |
| Dictionary          | [`static` user_option(name: String, description: String, data?: Dictionary)](#applicationcommand-user-option)                           |
| Dictionary          | [`static` channel_option(name: String, description: String, data?: Dictionary)](#applicationcommand-channel-option)                     |
| Dictionary          | [`static` role_option(name: String, description: String, data?: Dictionary)](#applicationcommand-role-option)                           |
| Dictionary          | [`static` mentionable_option(name: String, description: String, data?: Dictionary)](#applicationcommand-mentionable-option)             |
| Dictionary          | [`static` number_option(name: String, description: String, data?: Dictionary)](#applicationcommand-number-option)                       |
| Dictionary          | [`static` choice(name: String, value: Variant)](#applicationcommand-choice)                                                             |
| Dictionary          | [print()](#applicationcommand-print)                                                                                                    |

## Method Descriptions
### <a name="applicationcommand-get-id"></a>get_id()
Returns the id of the command.
> Returns: String

### <a name="applicationcommand-get-type"></a>get_type()
Returns the type of the menu. One of (`CHAT_INPUT`, `MESSAGE` or `USER`)
> Returns: String

### <a name="applicationcommand-set-type"></a>set_type(new_type)
Sets the type of this command.
> Returns: ApplicationCommand
 
<small>See [Discord application command types docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-types)</small>

| Type   | Parameter |
| ------ | --------- |
| String | new_type  |

### <a name="applicationcommand-get-application-id"></a>get_application_id()
Returns the application_id of the parent application.
> Returns: String

### <a name="applicationcommand-set-name"></a>set_name(new_name)
Sets the name of the command.
> Returns: ApplicationCommand

| Type   | Parameter |
| ------ | --------- |
| String | new_name  |

### <a name="applicationcommand-get-name"></a>get_name()
Returns the name of the command.
> Returns: String

### <a name="applicationcommand-set-description"></a>set_description(new_description)
Sets the description of the command.
> Returns: ApplicationCommand

| Type   | Parameter       |
| ------ | --------------- |
| String | new_description |

### <a name="applicationcommand-get-description"></a>get_description()
Returns the description of the command.
> Returns: String

### <a name="applicationcommand-get-guild-id"></a>get_guild_id()
Returns the guild_id of the command.
> Returns: String

### <a name="applicationcommand-set-options"></a>set_options(new_options)
<small>(For advanced users)</small><br>
Directly set the options of the command by passing an Array of Dictionary options.
> Returns: ApplicationCommand

!!! note
    Use [[#applicationcommand-add-option|ApplicationCommand.add_option()]] instead for easier usage.

| Type  | Parameter   |
| ----- | ----------- |
| Array | new_options |

#### Examples
Set the options to a single option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("test")\
            .set_description("Testing description")
cmd1.set_options(
    [{
        "type": 3,
        "name": "string-option",
        "description": "This is a string option"
    }]
)
```

### <a name="applicationcommand-get-options"></a>get_options()
Returns the options of the command.
> Returns: Array

### <a name="applicationcommand-add-option"></a>add_option(option_data)
Easy way to add options to the command.
> Returns: ApplicationCommand

| Type       | Parameter   | Description                           |
| ---------- | ----------- | ------------------------------------- |
| Dictionary | option_data | Dictionary containing the option data |

!!! note ""
    To get the `option_data` use any of the static option generator methods like [[#applicationcommand-sub-command-option|sub_command_option()]], [[#applicationcommand-sub-command-group-option||sub_command_group_option()]], [[#applicationcommand-string-options|string_option()]], [[#applicationcommand-integer-option|integer_option()]], [[#applicationcommand-boolean-option|boolean_option()]], [[#applicationcommand-user-option|user_option()]], [[#applicationcommand-channel-option|channel_option()]], [[#applicationcommand-role-option|role_option()]], [[#applicationcommand-mentionable-option|mentionable_option()]] or [[#applicationcommand-number-option|number_option()]] of the ApplicationCommand class.

#### Examples
Add a string option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("view")\
            .set_description("View an item.")
cmd1.add_option(
    ApplicationCommand.string_option("item", "Name of the item to view")
)
```

Add a user option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("donate")\
            .set_description("Give someone money.")
cmd1.add_option(
    ApplicationCommand.user_option("user", "The person to donate to.", {
        # Make this option compulsory
        "required": true
    })
)
```

Add a channel option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("notify")\
            .set_description("Change the notification channel.")
cmd1.add_option(
    ApplicationCommand.channel_option("channel", "The channel where to send the notifications.", {
        # Make this option compulsory
        "required": true
    })
)
```

Add an autocompleted string option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("autocomplete-testing")\
            .set_description("Autocomplete command test.")
cmd1.add_option(
    ApplicationCommand.string_option("autocomplete-option", "This is an autocompleted option", {
        "autocomplete": true,
        "required": true
    })
)

# Then to respond to the autocomplete, in the DiscordBot.interaction_create:
if interaction.is_autocomplete():
    print("autocomplete data ", interaction.data)
    interaction.respond_autocomplete([
        ApplicationCommand.choice("This is autocompleted choice 1", "autocomplete_choice_1")
        ApplicationCommand.choice("This is autocompleted choice 2", "autocomplete_choice_2")
        ApplicationCommand.choice("This is autocompleted choice 3", "autocomplete_choice_3")
    ])
return

```

### <a name="applicationcommand-sub-command-option"></a>sub_command_option(name, description, data?)
Generates data for a sub command option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

### <a name="applicationcommand-sub-command-group-option"></a>sub_command_group_option(name, description, data?)
Generates data for a sub command group option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

#### Examples
Add a sub command group with two sub commands
```GDScript
var cmd1 = ApplicationCommand.new().set_name("market")\
            .set_description("Buy or sell items.")

# Add a sub command group
cmd1.add_option(
    ApplicationCommand.sub_commang_group("items", "Buy or sell items", {
        "options": [
            # Add first sub command
            ApplicationCommand.sub_command_option("buy", "Buy an item"),
            # Add second sub command
            ApplicationCommand.sub_command_option("sell", "Sell an item")
        ]
    })
)
```

### <a name="applicationcommand-string-option"></a>string_option(name, description, data?)
Generates data for a string option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |


#### Examples
Add a single string option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("set-country")\
            .set_description("Sets your country.")
cmd1.add_option(
    ApplicationCommand.string_option("country", "The country name", {
    # Make this option compulsory
    "required": true
    })
)
```

Add multiple string options
```GDScript
var cmd1 = ApplicationCommand.new().set_name("set-location")\
            .set_description("Sets your location.")
cmd1.add_option(
    ApplicationCommand.string_option("continent", "The name of the continent", {
        # Make this option compulsory
        "required": true,

        # Provide a fixed set of choices to choose from
        "choices": [
            ApplicationCommand.choice("Asia", "asia"),
            ApplicationCommand.choice("Europe", "europe"),
            ApplicationCommand.choice("South America", "south-america"),
            ApplicationCommand.choice("North America", "north-america"),
            ApplicationCommand.choice("Antartica", "antartica"),
            ApplicationCommand.choice("Africa", "africa"),
            ApplicationCommand.choice("Oceania", "oceania"),
        ]
    })
)

cmd1.add_option(
    ApplicationCommand.string_option("country", "The name of the country", {
        "autocomplete": true
    })
)

```

### <a name="applicationcommand-integer-option"></a>integer_option(name, description, data?)
Generates data for a integer option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

#### Examples
Add a single integer option (with min and max values)
```GDScript
var cmd1 = ApplicationCommand.new().set_name("set-age")\
            .set_description("Sets your age.")
cmd1.add_option(
    ApplicationCommand.integer_option("age", "The value of your age", {
        "required": true,
        "min_value": 13, # Minimum value
        "max_value": 120 # Maximum value
    })
)
```

### <a name="applicationcommand-boolean-option"></a>boolean_option(name, description, data?)
Generates data for a boolean option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

#### Examples
Add a single boolean option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("set-afk")\
            .set_description("Set whether you are AFK.")
cmd1.add_option(
    ApplicationCommand.boolean_option("afk", "Set to True if you are AFK")
)
```

### <a name="applicationcommand-user-option"></a>user_option(name, description, data?)
Generates data for a user option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

#### Examples
Add a single user option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("profile")\
            .set_description("Shows the user profile.")
cmd1.add_option(
    ApplicationCommand.user_option("user", "The user whose profile to show")
)
```

### <a name="applicationcommand-channel-option"></a>channel_option(name, description, data?)
Generates data for a channel option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

#### Examples
Add a single channel option
```GDScript
var cmd1 = ApplicationCommand.new().set_name("set-logs")\
            .set_description("Set the channel to send logs.")
cmd1.add_option(
    ApplicationCommand.channel_option("channel", "The channel where to send logs", {
        # Allow only guild text channels
        "channel_types": ["GUILD_TEXT"]
    })
)
```

### <a name="applicationcommand-role-option"></a>role_option(name, description, data?)
Generates data for a role option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

### <a name="applicationcommand-mentionable-option"></a>mentionable_option(name, description, data?)
Generates data for a mentionable option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

### <a name="applicationcommand-number-option"></a>number_option(name, description, data?)
Generates data for a number option.
> Returns: Dictionary

<small> See [Discord application command option docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-structure)</small>

| Type       | Parameter   |
| ---------- | ----------- |
| String     | name        |
| String     | description |
| Dictionary | data        |

### <a name="applicationcommand-choice"></a>choice(name, value)
Generates data for a command option choice.
> Returns: Dictionary

<small> See [Discord application command option choice docs](https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-option-choice-structure)</small>

| Type    | Parameter |
| ------- | --------- |
| String  | name      |
| Variant | value     |

#### Examples
Choices for a string option
```GDScript
ApplicationCommand.choice("A red apple", "apple")
ApplicationCommand.choice("A ripe banana", "banana")
```

Choices for a integer option
```GDScript
ApplicationCommand.choice("One", 1)
ApplicationCommand.choice("Two", 2)
ApplicationCommand.choice("Dozen", 12)
```

Choices for a number option
```GDScript
ApplicationCommand.choice("Half", 0.5)
ApplicationCommand.choice("Quarter", 0.25)
ApplicationCommand.choice("One and a half", 1.5)
```

### <a name="applicationcommand-print"></a>print()
Prints the ApplicationCommand.
> Returns: void

!!! note
    Use this instead of `print(Message)`Generates data for a command option choice.


## Registering Application Commands

<small> See [Discord registering a command docs](https://discord.com/developers/docs/interactions/application-commands#registering-a-command)</small>

Use the [[discordbot#discordbot-register-command|DiscordBot.register_command()]] and [[discordbot#discordbot-register-commands|DiscordBot.register_commands()]] methods to register commands.

!!! warning ""
    While developing commands it's better to use `guild level commands` since they update instantly while `global commands` take upto 1hr to update.

#### Examples
Making a `MESSAGE` command
```GDScript
var cmd1 = ApplicationCommand.new().set_type("MESSAGE").set_name("Bookmark this message")
bot.register_command(cmd1)
```

Making a `USER` command
```GDScript
var cmd1 = ApplicationCommand.new().set_type("USEr").set_name("High five this user")
bot.register_command(cmd1)
```

## Responding to Application Commands
Application commands will fire the `DiscordBot.interaction_create` signal.

#### Examples
Respond to an application command
```GDScript
# In the DiscordBot.interaction_create,
func _on_bot_interaction_create(bot: DiscordBot, interaction: DiscordInteraction):
    if not interaction.is_command():
        return
    
    print("received command: ", interaction.data)
    var command_data = interaction.data

    var type = command_data.type

    match command_data.name:
        "ping":
            interaction.reply({
                "embeds": [
                    MessageEmbed.new().set_title("Pong!")
                ]
            })

        "long-command":
            # Incase your processing requires
            # more than 3s, you can use defer_reply()
            interaction.defer_reply()

            # Fake delay of 5s
            yield(get_tree().create_timer(5), "timeout")
            
            # Edit the original message
            interaction.edit_reply({
                "content": "After processing for 5s the reply is edited!" 
            })

        _:
            # Default case
            interaction.reply({
                "content": "Received command. But logic is not implemented.",
            })
```