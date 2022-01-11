---
title: Class Helpers
tags:
- helpers, class
---

# Helpers
Extends: None

```
General purpose functions
```

## Description
General purpose functions which Discord.gd makes use of.

## Static Methods
| Returns      | Definition                                                         |
| ------------ | ------------------------------------------------------------------ |
| bool         | [is_num(value: Variant)](#helpers-is-num)                          |
| bool         | [is_str(value: Variant)](#helpers-is-str)                          |
| bool         | [is_valid_str(value: Variant)](#helpers-is-valid-str)              |
| String       | [make_iso_string(datetime?: Dictionary)](#helpers-make-iso-string) |
| void         | [print_dict(to_print: Dictionary)](#helpers-print-dict)            |
| void         | [save_dict(to_save: Dictionary)](#helpers-save-dict)               |
| Image        | [to_png_image(png_bytes: PoolByteArray)](#helpers-to-png-image)    |
| ImageTexture | [to_image_texture(image: Image)](#helpers-to-image-texture)        |

## Method Descriptions
### <a name="helpers-is-num"></a>is_num(value)
Whether a given variable is an integer or a float.
> Returns: bool

| Type    | Parameter |
| ------- | --------- |
| Variant | value     |

#### Examples
```GDScript
print(Helpers.is_num(15)) # Prints true

print(Helpers.is_num(15.5)) # Prints true

print(Helpers.is_num("15")) # Prints false
```

### <a name="helpers-is-str"></a>is_str(value)
Returns true if a given variable is a String
> Returns: bool


| Type    | Parameter |
| ------- | --------- |
| Variant | value     |

#### Examples
```GDScript
print(Helpers.is_num(15)) # Prints false

print(Helpers.is_num("")) # Prints true

print(Helpers.is_num("15")) # Prints true
```

### <a name="helpers-is-valid-str"></a>is_valid_str(value)
Returns true if a given variable is a String and has length of 1 or more characters
> Returns: bool

| Type    | Parameter |
| ------- | --------- |
| Variant | value     |

#### Examples
```GDScript
print(Helpers.is_valid_str("15")) # Prints true

print(Helpers.is_valid_str("")) # Prints false
```

### <a name="helpers-make-iso-string"></a>make_iso_string(datetime?)
Returns a ISO8601 timestamp from the current or specified datetime Dictionary
> Returns: String

| Type   | Parameter | Default               | Description                                                                                                           |
| ------ | --------- | --------------------- | --------------------------------------------------------------------------------------------------------------------- |
| String | datetime  | OS.get_datetime(true) | A Dictionary with keys: year, month, day, weekday, dst (Daylight Savings Time), hour, minute, second. (UTC time zone) |


### <a name="helpers-print-dict"></a>print_dict(to_print)
Pretty prints a Dictionary
> Returns: void

!!! note
    This is the same as doing `print(JSON.print(to_print, "\t"))`

| Type       | Parameter |
| ---------- | --------- |
| Dictionary | to_print  |

### <a name="helpers-save-dict"></a>save_dict(to_save, filename?)
Saves a Dictionary as a JSON file to the `user://` directory. This helps viewing large dictionaries which result in outpul overflow when printing.
> Returns: void

!!! note
    `user://` directory is located at `%appdata%/Godot/app_userdata/PROJECT_NAME_HERE/`

| Type       | Parameter | Default    | Description                |
| ---------- | --------- | ---------- | -------------------------- |
| Dictionary | to_save   | -          | The dictionary to be saved |
| String     | filename  | saved_dict | The name of the JSON file  |


### <a name="helpers-to-png-image"></a>to_png_image(png_bytes)
Converts the raw bytes of a PNG image to a Image
> Returns: Image

| Type          | Parameter |
| ------------- | --------- |
| PoolByteArray | png_bytes |

### <a name="helpers-to-image-texture"></a>to_image_texture(image)
Converts an Image to a ImageTexture
> Returns: ImageTexture

| Type  | Parameter |
| ----- | --------- |
| Image | image     |