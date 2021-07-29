tool
extends EditorPlugin


func _enter_tree():
	add_custom_type('DiscordBot', 'HTTPRequest', load('res://addons/discord_gd/discord.gd'), preload('res://addons/discord_gd/icon.png'))


func _exit_tree():
	print('bye left the tree')
	remove_custom_type('DiscordBot')
