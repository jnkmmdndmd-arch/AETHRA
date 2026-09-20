# AETHRA: Wildbound Architecture

Client: Godot 4.7.x, GDScript, Node3D voxel renderer.

Dedicated server: same Godot project exported headless. The server owns world simulation and network authority.

Authentication/database: `/server/auth-service` is a small service using SQLite in production deployment; its schema is supplied in `server/database_schema.sql`.

World persistence: chunk deltas and player state use atomic JSON snapshots in `user://worlds`. This is deliberately separate from account/session storage.

Core boundaries:
- `scripts/world` = voxel data, deterministic generation, chunk meshing.
- `scripts/player` = movement, interaction, survival/inventory ownership.
- `scripts/entities` = creature behavior and spawning.
- `scripts/network` = ENet client/server transport and server validation gates.
- `scripts/persistence` = world snapshots and recovery files.
- `scripts/ui` = menu/HUD/settings.
- `scripts/tools` = developer console.

Security rule: client requests changes; server validates and applies authoritative state in multiplayer.
