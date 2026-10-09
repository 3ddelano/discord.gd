# Offline regression tests

Run with Godot 4 installed:

```sh
sh tests/run.sh
```

To use a specific executable:

```sh
GODOT=/path/to/godot sh tests/run.sh
```

The runner copies the addon into a temporary Godot project, imports its global
script classes, runs the tests headlessly, and removes the temporary project.
It does not need a Discord token or make network requests.

The readiness tests cover normal `GUILD_CREATE` payloads without `lazy`,
zero-guild startup, cache contents when `bot_ready` fires, duplicate and unrelated
guild events, and subsequent `READY` events.
