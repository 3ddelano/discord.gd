class_name Embed

var title: String setget set_title, get_title
var type: String = 'rich' setget set_type, get_type
var description: String setget set_description, get_description
var url: String setget set_url, get_url
var timestamp: String setget set_timestamp, get_timestamp
var color setget set_color, get_color

var footer = null
var image = null
var thumbnail = null
var video = null
var provider = null
var author = null
var fields: Array

func _init():
	return self

func get_title():
	return title if Helpers.is_valid_str(title) else null

func get_type():
	return type if Helpers.is_valid_str(type) else null

func get_description():
	return description if Helpers.is_valid_str(description) else null

func get_url():
	return url if Helpers.is_valid_str(url) else null

func get_timestamp():
	return timestamp if Helpers.is_valid_str(timestamp) else null

func get_color():
	return color if Helpers.is_valid_str(color) else null



func set_title(_title):
	assert(Helpers.is_valid_str(_title), 'Embed title must be a String')
	assert(_title.length() <= 256, 'Embed title must be <= 256 characters')
	title = _title
	return self

func set_type(_type):
	assert(Helpers.is_valid_str(_type), 'Embed type must be a String')
	type = _type
	return self

func set_description(_description):
	assert(Helpers.is_valid_str(_description), 'Embed description must be a String')
	assert(_description.length() <= 4096, 'Embed description must be <= 4096 characters')
	description = _description
	return self

func set_url(_url):
	assert(Helpers.is_valid_str(_url), 'Embed url must be a String')
	url = _url
	return self

func set_timestamp(_timestamp = ''):
	timestamp = Helpers.make_iso_string()
	return self

func set_color(_color):

	# RBG color
	if typeof(_color) == TYPE_ARRAY:
		color = (int(_color[0]) * 256 * 256) + (int(_color[1]) * 256) + int(_color[3])

	# Hex color
	elif typeof(_color) == TYPE_STRING and _color.begins_with('#'):
		color = _color.replace('#', '0x').hex_to_int()

	# Decimal color
	elif _color.is_valid_integer:
		color = int(_color)

	return self

func set_footer(text: String, icon_url: String = '', proxy_icon_url: String = ''):
	assert(Helpers.is_valid_str(text), 'Embed footer text must be a valid String')
	assert(text.length() <= 2048, 'Embed footer text must be <= 2048 characters')

	footer = {
		'text': text,
		'icon_url': icon_url,
		'proxy_icon_url': proxy_icon_url
	}
	return self

func set_image(url: String, width: int = -1, height: int = -1, proxy_url: String = ''):
	assert(Helpers.is_valid_str(url), 'Embed image url must be a valid String')
	image  = {
		'url': url,
		'width': width if width != -1 else null,
		'height': height if height != -1 else null,
		'proxy_url': proxy_url if Helpers.is_valid_str(proxy_url) else null
	}
	return self

func set_thumbnail(url: String, width: int = -1, height: int = -1, proxy_url: String = ''):
	assert(Helpers.is_valid_str(url), 'Embed thumbnail url must be a valid String')
	thumbnail  = {
		'url': url,
		'width': width if width != -1 else null,
		'height': height if height != -1 else null,
		'proxy_url': proxy_url if Helpers.is_valid_str(proxy_url) else null
	}
	return self

func set_video(url: String, width: int = -1, height: int = -1, proxy_url: String = ''):
	assert(Helpers.is_valid_str(url), 'Embed video url must be a valid String')
	video  = {
		'url': url,
		'width': width if width != -1 else null,
		'height': height if height != -1 else null,
		'proxy_url': proxy_url if Helpers.is_valid_str(proxy_url) else null
	}
	return self

func set_provider(name: String, url: String = ''):
	assert(Helpers.is_valid_str(name), 'Embed provider name must be a valid String')
	provider = {
		'name': name,
		'url': url if Helpers.is_valid_str(url) else null
	}
	return self

func set_author(name: String = '', url: String = '', icon_url: String = '', proxy_icon_url: String = ''):
	assert(Helpers.is_valid_str(name), 'Embed author name must be a valid String')
	assert(name.length() <= 256, 'Embed author name must be <= 256 characters')

	author = {
		'name': name,
		'url': url if Helpers.is_valid_str(url) else null,
		'icon_url': icon_url if Helpers.is_valid_str(icon_url) else null,
		'proxy_icon_url': proxy_icon_url if Helpers.is_valid_str(proxy_icon_url) else null
	}
	return self

func add_field(name: String, value: String = '', inline: bool = false):
	assert(Helpers.is_valid_str(name), 'Embed field name must be a valid String')
	assert(Helpers.is_valid_str(value), 'Embed field value must be a valid String')

	assert(name.length() <= 256, 'Embed field name must be <= 256 characters')
	assert(value.length() <= 1024, 'Embed field value must be <= 1024 characters')
	assert(fields.size() <= 25, 'Embed can have a max of 25 fields')

	fields.append(
		{
			'name': name,
			'value': value,
			'inline': inline
		}
	)
	return self

func slice_fields(index: int, delete_count: int = 1, replace_fields: Array = []):
	var n = fields.size()
	assert(index, 'index must be provided to Embed.slice_fields')
	assert(index < n, 'index out of bounds in Embed.slice_fields')

	var max_deletable = n - index
	assert(delete_count <= max_deletable, 'delete_count out of bounds in Embed.slice_fields')

	while delete_count != 0:
		fields.remove(index)
		delete_count -= 1

	if replace_fields.size() != 0:
		# add fields
		for field in replace_fields:
			var inline = false
			if field.size() == 3:
				inline = field[2]
			add_field(field[0], field[1], inline)

	return self

func _to_string() -> String:
	return JSON.print(_to_dict())

func _to_dict() -> Dictionary:
	var total = title + description

	if footer and footer.text:
		total += footer.text

	if author and author.name:
		total += author.name

	for field in fields:
		total += field.name
		total += field.value

	total = str(total).length()
	assert(total <= 6000, 'Embed content must be <= 6000 characters in total')

	return {
		'title': title,
		'type': type,
		'description': description,
		'url': url,
		'timestamp': timestamp,
		'color': color,
		'footer': footer,
		'image': image,
		'thumbnail': thumbnail,
		'video': video,
		'provider': provider,
		'author': author,
		'fields': fields
	}

"""
func make_embed(data = {}):

	var footer = null
	var image = null
	var thumbnail = null
	var video = null
	var provider = null
	var author = null
	var fields = null


	if data.has('footer') and typeof(data.footer) == TYPE_DICTIONARY:
		footer = data.footer

	if data.has('image') and typeof(data.image) == TYPE_DICTIONARY:
		image = data.image

	if data.has('thumbnail') and typeof(data.thumbnail) == TYPE_DICTIONARY:
		thumbnail = data.thumbnail

	if data.has('video') and typeof(data.video) == TYPE_DICTIONARY:
		video = data.video

	if data.has('provider') and typeof(data.provider) == TYPE_DICTIONARY:
		provider = data.provider

	if data.has('author') and typeof(data.author) == TYPE_DICTIONARY:
		author = data.author

	if data.has('fields') and typeof(data.fields) == TYPE_ARRAY:
		fields = []
		for field in data.fields:
			fields.append(field)

	return {
		'footer': footer,
		'image': image,
		'thumbnail': thumbnail,
		'video': video,
		'provider': provider,
		'author': author,
		'fields': fields
	}
"""
