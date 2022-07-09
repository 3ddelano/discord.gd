# Represents a Discord ChannelMention
class_name ChannelMention extends DiscordDataclass

var id: String # Id of the channel
var guild_id: String # Id of the guild containing the channel
var type: int # [ChannelTypes] The type of channel
var name: String # The name of the channel


# @hidden
func _init().("ChannelMention"): return self
