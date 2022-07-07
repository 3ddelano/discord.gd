# Represents a Discord message interaction
class_name MessageInteraction extends Dataclass

var id: String # Id of the interaction
var type: int # Type of interaction
var name: String # Name of the application command, including subcommands and subcommand groups
var user: User # [User] User who invoked the interaction
var member = null # Partial [GuildMember] Member who invoked the interaction in the guild


# @hidden
func _init().("MessageInteraction"): return self


# @hidden
func from_dict(p_dict: Dictionary):
	.from_dict(p_dict)

	user = User.new().from_dict(p_dict.user)
	if p_dict.has("member") and p_dict.member != null:
		member = GuildMember.new().from_dict(p_dict.member)

	return self