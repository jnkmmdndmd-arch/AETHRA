# AETHRA: Wildbound — UI Architecture

The main hub is implemented with native Godot Control nodes and the following live providers:

- Recent Worlds -> `SaveDB.list_worlds()`
- Profile -> `AppState`
- Friends/presence -> `NetworkManager.remote_players`
- Servers -> `ServerDirectory`
- FPS/Memory/Node metrics -> Godot `Engine`/`Performance`
- Settings -> `Settings`
- Audio -> `AudioManager`

The supplied reference image is a visual reference only. The interface is recreated from native Godot UI controls; it is not a screenshot used as the UI.

Unsupported commercial services are shown as unavailable rather than fabricated, especially store commerce and global discovery when there is no backing service.
