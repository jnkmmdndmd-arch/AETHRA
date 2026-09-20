# Development

Recommended engine: Godot 4.7 stable. The project is intentionally authored against the stable 4.7 branch. Godot documents Windows, Android, iOS and dedicated-server export paths; Android release builds require signing configuration from the deployment environment.

Open `project.godot` in Godot 4.7.2 or later in the 4.7 stable family.

Run client: press F6/F5.
Run dedicated server: `godot --headless --path . --script res://server/main_server.gd -- --server --seed 1234567`
Run self tests: `godot --headless --path . --script res://tests/self_test.gd`

F8 opens developer console in-game. F11 toggles fullscreen/windowed. Settings persist to `user://aethra_settings.json`.
