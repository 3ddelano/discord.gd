---
title: Class MessageActionRow
tags:
- message-action-row, class
---

# MessageActionRow
Extends: None

```
Represents an action row containing message components.
```

## Description
Provides methods for adding and removing message compoenents from an action row.


## Properties
| Type  | Name       | Description                       |
| ----- | ---------- | --------------------------------- |
| Array | components | The components in this action row |

## Methods
| Returns          | Definition                                                                                                       |
| ---------------- | ---------------------------------------------------------------------------------------------------------------- |
| MessageActionRow | [add_component(component: Variant))](#messageactionrow-add-component)                                            |
| void             | [print())](#messageactionrow-print)                                                                              |
| MessageActionRow | [slice_components(index: int, delete_count: int, replace_components?: Array)](#messageactionrow-slice-component) |


## Method Descriptions
### <a name="messageactionrow-add-component"></a>add_component(component)
Adds a component to the action row.
> Returns: MessageActionRow

| Type                                | Parameter |
| ----------------------------------- | --------- |
| [[MessageButton]] \| [[SelectMenu]] | component |

!!! danger ""
    The `MessageActionRow` can have a maximum of 5 components.

!!! danger ""
    The `MessageActionRow` cannot contain another `MessageActionRow`.

#### Examples
Create and send a MessageButton
```GDScript
var button = MessageButton.new().set_style(MessageButton.STYLES.DEFAULT)\
                .set_label("A")\
                .set_custom_id("primary_custom")

var row = MessageActionRow.new().add_component(button)

yield(bot.send(message, {
    "components": [row]
}))
```
### <a name="messageactionrow-slice-components"></a>slice_components(index, delete_count, replace_components?)
Removes, replaces, and inserts components in the action row.
> Returns: MessageActionRow

| Type  | Parameter          | Description                                        |
| ----- | ------------------ | -------------------------------------------------- |
| int   | index              | The starting index from which to start deletion    |
| int   | delete_count       | Number of components to delete (default is 1)      |
| Array | replace_components | An array of components to replace the deleted ones |

### <a name="messageactionrow-print"></a>print()
Prints the MessageActionRow
> Returns: void

!!! note
    Use this instead of `print(MessageActionRow)`
