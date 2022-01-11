---
title: Class MessageFlags
tags:
- message-flags, class
---

# MessageFlags
Extends: [[BitField]]

```
Data structure that makes it easy to interact with the Message.flags bitfield.
```

## Description
An extended data structure which defines the flags supported by a Message on Discord.
<small>See [Discord Message Flags Docs](https://discord.com/developers/docs/resources/channel#message-object-message-flags)</small>

!!! note
    This is a bitfield, so you can use the properties and methods of `BitField`.

## Flags
| Bit | Flag                   |
| --- | ---------------------- |
| 0   | CROSSPOSTED            |
| 1   | IS_CROSSPOST           |
| 2   | SUPPRESS_EMBEDS        |
| 3   | SOURCE_MESSAGE_DELETED |
| 4   | URGENT                 |
| 5   | HAS_THREAD             |
| 6   | EPHEMERAL              |
| 7   | LOADING                |