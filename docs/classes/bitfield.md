---
title: Class BitField
tags:
  - bitfield, class
---

# BitField
Extends: None

```
Data structure that makes it easier to intract with a bitfield
```

## Description
A base data structure which defines a bitfield to implement flags and permissions for Discord. 

## Properties
| Type       | Name     | Description                                         |
| ---------- | -------- | --------------------------------------------------- |
| int        | bitfield | The bitfield of the packed bits                     |
| Dictionary | FLAGS    | Numeric bitfield flags (Defined in extension class) |


## Methods
| Returns    | Definition                         |
| ---------- | ---------------------------------- |
| Bitfield   | [add(bit)](#bitfield-add)          |
| bool       | [any(bit)](#bitfield-any)          |
| bool       | [equals(bit)](#bitfield-equals)    |
| bool       | [has(bit)](#bitfield-has)          |
| Array      | [missing(bit)](#bitfield-missing)  |
| Bitfield   | [remove(bit)](#bitfield-remove)    |
| Dictionary | [serialize()](#bitfield-serialize) |
| Array      | [to_array()](#bitfield-to-array)   |
| int        | [resolve(bit)](#bitfield-resolve)  |


## Method Descriptions
### <a name="bitfield-add"></a>add(bit)
Adds bit to these ones.
> Returns: BitField

| Type    | Parameter | Description       |
| ------- | --------- | ----------------- |
| Variant | bit       | The bit(s) to add |

!!! note ""
    Here the bit is any data that can be resolved to give a bitfield. This can be:
    - A bit number
    - A string flag of the bitfield
    - An instance of `BitField`
    - An Array of data that can be resolved to give a bitfield

### <a name="bitfield-any"></a>any(bit)
Checks whether the bitfield has a bit, or any of multiple bits.
> Returns: bool

| Type    | Parameter | Description             |
| ------- | --------- | ----------------------- |
| Variant | bit       | The bit(s) to check for |

### <a name="bitfield-equals"></a>equals(bit)
Checks if this bitfield equals another.
> Returns: bool

| Type    | Parameter | Description             |
| ------- | --------- | ----------------------- |
| Variant | bit       | The bit(s) to check for |

### <a name="bitfield-has"></a>has(bit)
Checks whether the bitfield has a bit, or multiple bits.
> Returns: bool

| Type    | Parameter | Description             |
| ------- | --------- | ----------------------- |
| Variant | bit       | The bit(s) to check for |

### <a name="bitfield-missing"></a>missing(bit)
Returns all given bits that are missing from the bitfield.
> Returns: Array

!!! note
    Implemented by the children classes.

| Type    | Parameter | Description             |
| ------- | --------- | ----------------------- |
| Variant | bit       | The bit(s) to check for |

### <a name="bitfield-remove"></a>remove(bit)
Removes bits from these.
> Returns: BitField

| Type    | Parameter | Description             |
| ------- | --------- | ----------------------- |
| Variant | bit       | The bit(s) to check for |

### <a name="bitfield-serialize"></a>serialize()
Returns a dictionary mapping flag names to a boolean  indicating whether the bit is available.
> Returns: Dictionary

### <a name="bitfield-to-array"></a>to_array()
Returns an Array of flag names based on the bits available.
> Returns: Array

### <a name="bitfield-resolve"></a>resolve(bit)
Resolves bitfields to their numeric form.
> Returns: int

| Type    | Parameter | Description           |
| ------- | --------- | --------------------- |
| Variant | bit       | The bit(s) to resolve |
