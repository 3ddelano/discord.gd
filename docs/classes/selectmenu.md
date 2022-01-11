---
title: Class SelectMenu
tags:
  - select-menu, class
---
# SelectMenu
Extends: None

<small>See [Discord SelectMenu docs](https://discord.com/developers/docs/interactions/message-components#select-menus)</small>

```
Represents a select menu component.
```

## Description
Provides methods for customising a select menu.

## Properties
| Type   | Name         | Description                                         |
| ------ | ------------ | --------------------------------------------------- |
| String | custom_id    | The custom_id of the menu                           |
| Array  | options      | The options of this menu                            |
| String | placeholder? | Optional placeholder to show if nothing is selected |
| int    | min_values?  | Minimum items that must be chosen                   |
| int    | max_values?  | Maximum items that must be chosen                   |
| bool   | disabled     | Whether the menu is disabled or not                 |

## Methods
| Returns    | Definition                                                                           |
| ---------- | ------------------------------------------------------------------------------------ |
| SelectMenu | [set_custom_id(new_custom_id: String)](#selectmenu-set-custom-id)                    |
| String     | [get_custom_id()](#selectmenu-get-custom-id)                                         |
| SelectMenu | [add_option(value: String, label: String, data: Dictionary)](#selectmenu-add-option) |
| SelectMenu | [set_options(options: Array)](#selectmenu-set-options)                               |
| Array      | [get_options()](#selectmenu-get-options)                                             |
| SelectMenu | [set_placeholder(new_placeholder: String)](#selectmenu-set-placeholder)              |
| String     | [get_placeholder()](#selectmenu-get-placeholder)                                     |
| SelectMenu | [set_min_values(new_min_values: int)](#selectmenu-set-min-values)                    |
| int        | [get_min_values()](#selectmenu-get-min-values)                                       |
| SelectMenu | [set_max_values(new_max_values: int)](#selectmenu-set-max-values)                    |
| int        | [get_max_values()](#selectmenu-get-max-values)                                       |
| SelectMenu | [set_disabled(new_value: bool)](#selectmenu-set-disabled)                            |
| bool       | [get_disabled()](#selectmenu-get-disabled)                                           |
| void       | [print()](#selectmenu-print)                                                         |

## Method Descriptions
### <a name="selectmenu-set-custom-id"></a>set_custom_id(new_custom_id)
Sets the custom_id of the menu.
> Returns: SelectMenu

| Type   | Parameter     |
| ------ | ------------- |
| String | new_custom_id |

### <a name="selectmenu-get-custom-id"></a>get_custom_id()
Returns the custom_id of the menu.
> Returns: String

### <a name="selectmenu-add-option"></a>add_option(value, label, data?)
Add an option to the menu.
> Returns: SelectMenu

<small>See [Discord SelectMenu option docs](https://discord.com/developers/docs/interactions/message-components#select-menu-object-select-option-structure)</small>

| Type       | Parameter | Description                         |
| ---------- | --------- | ----------------------------------- |
| String     | value     | The dev-defined value of the option |
| String     | label     | The user-facing name of the option  |
| Dictionary | data      | Optional data for the option        |

```GDScript
{
    # Only custom emojis are supported
    emoji: {
        id: "ID_OF_CUSTOM_EMOJI"
    },
    "description": String,  Description of the option
    "default": bool, Whether the option is selected by default
}
```

#### Examples
Send a menu with a single option
```GDScript
var menu = SelectMenu.new().set_custom_id("menu1")
menu.set_placeholder("Select an option")

menu.add_option("my_custom_option", "Buy a Parrot", {
    "description": "This is a nice parrot!",
    "emoji": {"id": "565171769187500032"}, # Animated parrot emoji
})

var row = MessageActionRow.new().add_component(menu)
bot.send(message, {
    "content": "Choose an item from the menu:",
    "components": [row]
})
```

Send a multi-select menu
```GDScript
var menu = SelectMenu.new().set_custom_id("menu1")
menu.set_placeholder("Select an option")

# Add first option
menu.add_option("parrot_option", "Buy a Parrot", {
    "description": "This is a nice parrot!",
    "emoji": {"id": "565171769187500032"}, # Animated parrot emoji
})

# Add second option
menu.add_option("green_checkmark_option", "A checkmark", {
    "description": "A nice green checkmark",
    "emoji": {"id": "556051807504433152"} # Green checkmark emoji
})

# Set the max selectable items to 2
menu.set_max_values(2)

var row = MessageActionRow.new().add_component(menu)
bot.send(message, {
    "content": "Choose item(s) from the menu:",
    "components": [row]
})
```

### <a name="selectmenu-set-options"></a>set_options(new_options)
<small>(For advanced users)</small><br>
Directly set the options of the menu by providing a Array of SelectMenu option.
> Returns: SelectMenu

| Type  | Parameter   |
| ----- | ----------- |
| Array | new_options |

### <a name="selectmenu-get-options"></a>get_options()
Returns the options of the menu.
> Returns: Array

### <a name="selectmenu-set-placeholder"></a>set_placeholder(new_placeholder: String)
Sets the placeholder of the menu.
> Returns: SelectMenu

| Type   | Parameter       |
| ------ | --------------- |
| String | new_placeholder |

### <a name="selectmenu-get-placeholder"></a>get_placeholder()
Returns the placeholder of the menu.
> Returns: String

### <a name="selectmenu-set-min-values"></a>set_min_values(new_min_values)
Sets the min_values of the menu.
> Returns: SelectMenu

| Type | Parameter      |
| ---- | -------------- |
| int  | new_min_values |

### <a name="selectmenu-get-min-values"></a>get_min_values() 
Returns the min_values of the menu.
> Returns: int

### <a name="selectmenu-set-max-values"></a>set_max_values(new_max_values)
Sets the max_values of the menu.
> Returns: SelectMenu

| Type | Parameter      |
| ---- | -------------- |
| int  | new_max_values |

### <a name="selectmenu-get-max-values"></a>get_max_values()
Returns the max_values of the menu.
> Returns: int

### <a name="selectmenu-set-disabled"></a>set_disabled(new_value)
Sets the disabled state of the menu.
> Returns: SelectMenu

### <a name="selectmenu-get-disabled"></a>get_disabled()
Returns whether the menu is disabled or not.
> Returns: bool

### <a name="selectmenu-print"></a>print()
Prints the SelectMenu.
> Returns: void

!!! note
    Use this instead of `print(SelectMenu)`

## Handling SelectMenu Interactions
SelectMenu interactions are received via the `DiscordBot.interaction_create` signal.

```GDScript
func _on_interaction_create(bot, interaction: DiscordInteraction):
    # Make sure the interaction is only from a SelectMenu
    if not interaction.is_select_menu():
        return
    
    # Get the custom_id of the menu
    var custom_id = interaction.data.custom_id
    # Get the selected options
    var values = interaction.data.values

    match custom_id:
        "menu1":
            # Handle menu1 logic here
            var msg = "You selected `"
            msg += PoolStringArray(values).join("`, `")
            msg += '`'
            interaction.reply({
               "content": msg
            })

        "menu2":
            # Handle menu2 logic here
            ...
```
