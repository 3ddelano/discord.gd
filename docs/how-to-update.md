---
title: How to update
tags:
  - update
---
# How to update
As of Godot 3, there is no proper way to update plugins in a clean method.
As a workaround:

1. Disable the plugin (Project Settings > Plugins > Discord.gd)
2. Close all your scenes (or close Godot entirely)
3. Delete the `addons/discord.gd` folder from your project directory
4. Follow the [installation](../installation) steps here to install the new version