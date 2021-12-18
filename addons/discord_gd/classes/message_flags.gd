class_name MessageFlags extends BitField
"""
Represents a bitfield of Discord message flags.
"""

func _init(bits = default_bit):
	default_bit = 0

	if bits == null:
		bits = default_bit

	FLAGS = {
		'CROSSPOSTED': 1 << 0,
		'IS_CROSSPOST': 1 << 1,
		'SUPPRESS_EMBEDS': 1 << 2,
		'SOURCE_MESSAGE_DELETED': 1 << 3,
		'URGENT': 1 << 4,
		'HAS_THREAD': 1 << 5,
		'EPHEMERAL': 1 << 6,
		'LOADING': 1 << 7,
	}

	bitfield = resolve(bits)

	return self

func missing(bits):
	var BF = load('res://addons/discord_gd/classes/message_flags.gd')
	return BF.new(bits).remove(self).to_array()
