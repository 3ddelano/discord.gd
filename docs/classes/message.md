---
title: Class Message
tags:
  - message, class
---

# Message
Entends: None

```
Represents a message from, or to Discord.
```

## Description
Stores all the data related to a message from Discord. It also has a few methods to manage the data in the message. 

!!! note
    To print a Message, use Message.print() instead of print(Message)

## Properties
<small>See [Discord Message Structure](https://discord.com/developers/docs/resources/channel#message-object-message-structure)</small>

| Type       | Name               | Description                                                                                                                                                                                                    |
| ---------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| String     | id                 | The id of the message                                                                                                                                                                                          |
| String     | channel_id         | The id of the channel from which the message originated                                                                                                                                                        |
| String     | guild_id           | The id of the guild from which the message originated                                                                                                                                                          |
| [[User]]   | author             | The [[User]] from which the message originated                                                                                                                                                                 |
| Dictionary | member             | The partial guild member from which the message originated                                                                                                                                                     |
| String     | content            | The text content of the message                                                                                                                                                                                |
| String     | timestamp          | ISO8601 timestamp when the message was sent                                                                                                                                                                    |
| String     | edited_timestamp   | ISO8601 timestamp when the message was edited (or null if never)                                                                                                                                               |
| bool       | tts                | Whether or not the message is text to speech                                                                                                                                                                   |
| bool       | mention_everyone   | Whether or not the message mentions everyone                                                                                                                                                                   |
| Array      | mentions           | An Array of [[User]] objects, with an additional partial member field                                                                                                                                          |
| Array      | mention_roles      | An Array of roles mentioned in the message <small>(See [Discord Role Structure](https://discord.com/developers/docs/topics/permissions#role-object-role-structure))</small>                                    |
| Array      | mention_channels   | An Array of channels mentioned in the message <small>(See [Discord Channel Mention Structure](https://discord.com/developers/docs/resources/channel#channel-mention-object-channel-mention-structure))</small> |
| Array      | attachments        | An Array of attachments in the message                                                                                                                                                                         |
| Array      | embeds             | An Array of embeds in the message                                                                                                                                                                              |
| Array      | reactions          | An Array of reactions of the message <small>(See [Discord Reaction Structure](https://discord.com/developers/docs/resources/channel#reaction-object-reaction-structure))</small>                               |
| bool       | pinned             | Whether or not the message is pinned                                                                                                                                                                           |
| String     | type               | The type of the message                                                                                                                                                                                        |
| Dictionary | message_reference  | Data showing the source of a crosspost, channel follow add, pin or message reply                                                                                                                               |
| Dictionary | referenced_message | The message associated with the message_reference                                                                                                                                                              |

## Methods
| Returns | Definition                                                                                                   |
| ------- | ------------------------------------------------------------------------------------------------------------ |
| void    | [print()](#message-print)                                                                                    |
| void    | [slice_attachments(index: int, delete_count?: int, replace_attachments?: Array)](#message-slice-attachments) |

## Method Descriptions
### <a name="message-print"></a>print()
Prints the Message
> Returns: void

!!! note
    Use this instead of `print(Message)`

### <a name="message-slice-attachments"></a>slice_attachments(index, delete_count?, replace_attachments?)
Removes, replaces, and inserts attachments in the Message
> Returns: void

!!! note
    The maximum file size of the Message must be less than 8MB

| Type  | Parameter           | Defaults | Description                                                        |
| ----- | ------------------- | -------- | ------------------------------------------------------------------ |
| int   | index               | -        | The index of the first attachment in the attachments to be removed |
| int   | delete_count        | 1        | The number of attachments to remove                                |
| Array | replace_attachments | []       | The replacing attachments                                          |

Each Attachment: <small>See [Discord Message Attachment Structure](https://discord.com/developers/docs/resources/channel#attachment-object-attachment-structure))</small>
```GDScript
{
    id: String, the id of the attachment,
    filename: String, the name of the file attached,
    content_type: String, MIME type of the file,
    size: int, size of the file in bytes,
    url: String, source url of the file
    proxy_url: String, a proxied url of the file,
    height?: int, height of file (if image),
    width?: int, width of file (if image)
}
```