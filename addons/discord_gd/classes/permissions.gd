class_name Permissions extends BitField
"""
Represents a bitfield of Discord permissions.
"""

var ALL
const DEFAULT = 104324673


func _init(bits = default_bit):
	default_bit = 0

	if bits == null:
		bits = default_bit

	FLAGS = {
		'CREATE_INSTANT_INVITE': 1 << 0,
		'KICK_MEMBERS': 1 << 1,
		'BAN_MEMBERS': 1 << 2,
		'ADMINISTRATOR': 1 << 3,
		'MANAGE_CHANNELS': 1 << 4,
		'MANAGE_GUILD': 1 << 5,
		'ADD_REACTIONS': 1 << 6,
		'VIEW_AUDIT_LOG': 1 << 7,
		'PRIORITY_SPEAKER': 1 << 8,
		'STREAM': 1 << 9,
		'VIEW_CHANNEL': 1 << 10,
		'SEND_MESSAGES': 1 << 11,
		'SEND_TTS_MESSAGES': 1 << 12,
		'MANAGE_MESSAGES': 1 << 13,
		'EMBED_LINKS': 1 << 14,
		'ATTACH_FILES': 1 << 15,
		'READ_MESSAGE_HISTORY': 1 << 16,
		'MENTION_EVERYONE': 1 << 17,
		'USE_EXTERNAL_EMOJIS': 1 << 18,
		'VIEW_GUILD_INSIGHTS': 1 << 19,
		'CONNECT': 1 << 20,
		'SPEAK': 1 << 21,
		'MUTE_MEMBERS': 1 << 22,
		'DEAFEN_MEMBERS': 1 << 23,
		'MOVE_MEMBERS': 1 << 24,
		'USE_VAD': 1 << 25,
		'CHANGE_NICKNAME': 1 << 26,
		'MANAGE_NICKNAMES': 1 << 27,
		'MANAGE_ROLES': 1 << 28,
		'MANAGE_WEBHOOKS': 1 << 29,
		'MANAGE_EMOJIS_AND_STICKERS': 1 << 30,
		'USE_APPLICATION_COMMANDS': 1 << 31,
		'REQUEST_TO_SPEAK': 1 << 32,
		'MANAGE_THREADS': 1 << 34,
		'USE_PUBLIC_THREADS': 1 << 35,
		'USE_PRIVATE_THREADS': 1 << 36,
		'USE_EXTERNAL_STICKERS': 1 << 37,
	}

	bitfield = resolve(bits)

	var values = FLAGS.values()
	var prev = default_bit
	for value in values:
		prev |= value
	ALL = prev

	return self

func missing(bits):
	var BF = load('res://addons/discord_gd/classes/permissions.gd')
	return BF.new(bits).remove(self).to_array()
