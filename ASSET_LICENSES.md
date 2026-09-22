# Asset provenance

## Original AETHRA assets

- `assets/icon.png`: original application icon generated for AETHRA.
- `assets/audio/*.wav`: generated synthetic audio tone assets for UI, footsteps, digging, placement, jump and creature ambience.
- The player body and AETHRA-specific creature geometry remain procedurally generated in Godot.
- Functional UI icons remain drawn by `scripts/ui/vector_icon.gd`.

## Imported Minecraft 1.17.1 source material

The user supplied a local Minecraft Java 1.17.1 installation archive for integration work.

AETHRA now contains adapted atlas data under:

- `assets/minecraft/atlas/minecraft_blocks_1_17_1.webp.b64`
- `assets/minecraft/atlas/minecraft_entities_1_17_1.webp.b64`
- `assets/minecraft/atlas/minecraft_items_1_17_1.webp.b64`

These files are used by the native Godot compatibility layer in `scripts/integration/minecraft_compat.gd`.

The repository does not embed the supplied Minecraft Java runtime, launcher, client JAR, DLL collection, or Java third-party libraries.

Before any public redistribution of the imported Minecraft-derived assets, their applicable Minecraft/Mojang licensing terms and redistribution permissions must be checked. The integration is based on user-supplied source material and is not represented as an original AETHRA asset set.

## Integration boundary

Minecraft-derived assets are used as source material for AETHRA's native rendering, inventory and creature systems. The game's UI, world streaming, voxel mesh construction, controls, save system and other AETHRA architecture remain native to the existing Godot project.
