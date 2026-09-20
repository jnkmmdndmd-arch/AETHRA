# Dedicated Server

The game uses the same Godot project in headless mode for dedicated simulation. Godot 4 supports dedicated-server exports/headless operation, which avoids a specialized legacy server binary.

Default game port: 31001/UDP via ENet.

Recommended deployment:
1. Export a dedicated server preset.
2. Run the server process on Linux.
3. Put the HTTPS authentication service behind TLS.
4. Restrict the game port to the expected clients/regions.
5. Back up `user://worlds` on an external volume.
