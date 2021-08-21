class_name PermissionOverwrites

var channel_id: String
var id: String
var type: String

var allow: Permissions
var deny: Permissions


var TYPES = {
	0: 'ROLE',
	1: 'MEMBER'
}

func _init(channel: Dictionary, data):
	channel_id = channel.id
	if data:
		_patch(data)


func _patch(data):
	if data.has('id'):
		id = data.id

	if data.has('type'):
		if Helpers.is_num(data.type):
			type = TYPES[data.type]
		else:
			type = data.type

	if data.has('allow'):
		allow = Permissions.new(data.allow)

	if data.has('deny'):
		deny = Permissions.new(data.deny)

func _to_dict():
	return {
		'id': id,
		'type': type,
		'allow': allow.bitfield,
		'deny': deny.bitfield
	}

static func resolve_overwrite_options(options: Dictionary, data = {}):
	if not data.has('allow'):
		data.allow = 0
	var allow = Permissions.new(data.allow);

	if not data.has('deny'):
		data.deny = 0
	var deny = Permissions.new(data.deny);

	var keys = options.keys()
	var values = options.values()
	var i = 0
	for value in values:
		var perm = keys[i]
		if value == true:
			allow.add(perm)
			deny.remove(perm)
		elif value == false:
			allow.remove(perm)
			deny.add(perm)
		elif value == null:
			allow.remove(perm)
			deny.remove(perm)


		i += 1

	return {
		'allow': allow,
		'deny': deny
	}

#
#static func resolve(overwrite, guild):
#	var PO = load("res://addons/discord_gd/classes/permission_overwrites.gd")
#	if typeof(overwrite) == TYPE_OBJECT and overwrite.is_class(PO.get_class()):
#		return {
#			'id': overwrite.id,
#			'type': TYPES[overwrite.type],
#			'allow': str(Permissions.resolve(overwrite.allow || 0)),
#			'deny': str(Permissions.resolve(overwrite.deny || 0))
#		}
#
