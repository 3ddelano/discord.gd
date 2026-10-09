#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project_dir=$(mktemp -d)
trap 'rm -rf "$project_dir"' EXIT HUP INT TERM

cp -R "$repo_dir/addons" "$project_dir/addons"
cp "$repo_dir/tests/test_bot_ready.gd" "$project_dir/test_bot_ready.gd"
printf 'config_version=5\n' > "$project_dir/project.godot"

# Import first so Godot registers the addon's global script classes.
"${GODOT:-godot}" --headless --path "$project_dir" --editor --import
"${GODOT:-godot}" --headless --path "$project_dir" --script res://test_bot_ready.gd
