# Minecraft Java 1.17.1 Integration Audit

## Source archive

The supplied archive was inspected as a complete ZIP before integration.

- Source: Minecraft Java 1.17.1 installation archive
- ZIP entries: 3,819
- Files: 3,332
- Directories: 487
- Compressed size: 458,399,088 bytes
- Uncompressed size: 540,653,205 bytes
- Client/runtime components include Java runtime modules, native DLLs, launcher/client executables, third-party Java libraries, the Minecraft client JAR, the 1.17.1 version JAR, asset indexes and hashed asset objects.

The 1.17.1 client JAR was also inspected. It contains the Minecraft asset/data trees, including block textures, models, blockstates, recipes, loot definitions and compiled Java classes.

## Integration decision

The Java runtime, Windows DLLs, Minecraft executable/client JAR and third-party launcher/runtime binaries are not copied into AETHRA. They are not Godot-native resources and embedding them would not integrate Minecraft's gameplay systems into the AETHRA architecture.

The useful compatible surface is integrated through a native Godot compatibility layer:

- scripts/integration/minecraft_compat.gd
- registered as the MinecraftCompat autoload
- source version fixed to Minecraft Java 1.17.1
- 60 AETHRA block IDs receive a Minecraft 1.17.1 source-texture mapping
- a generated 8x8, 16-pixel tile atlas is produced from sampled 1.17.1 texture colors
- voxel solid faces use the atlas through a Godot spatial shader
- greedy-meshed faces preserve repeated tile UVs
- LOD terrain uses the same atlas material
- fluids continue to use the dedicated fluid material

This is an adaptation layer, not a byte-for-byte redistribution of the Minecraft client.

## AETHRA-side changes

- VoxelChunk now carries block IDs in vertex color metadata and samples the Minecraft compatibility atlas in its material shader.
- Greedy meshing is preserved; UVs repeat across merged quads.
- Heightfield LOD uses the same atlas material path.
- Existing collision generation is unchanged.
- tests/self_test.gd now verifies the Minecraft compatibility source version, manifest size and a known stone mapping.

## Parser/build hardening performed while integrating

- Explicitly typed the creative-palette callback in inventory_menu.gd.
- Explicitly typed the main-menu avatar/store callbacks.
- Explicitly typed the dedicated-server save result.
- Explicitly typed voxel meshing arrays/loop variables that could otherwise trigger variant-inference warnings.
- Preserved the previously fixed crafting transaction type annotation.

## Excluded content

1. Java runtime modules and native DLLs.
2. Minecraft client/server compiled Java classes.
3. Minecraft launcher/client executables.
4. Third-party Java libraries that are not required by AETHRA.
5. Original Minecraft runtime packaging and launch configuration.

These components cannot be treated as Godot modules or drop-in gameplay code without replacing the underlying engine/runtime architecture.

## Verification target

The integration branch must pass:

1. Godot editor validation.
2. GDScript parse gate.
3. Godot self-test, including the Minecraft compatibility test.
4. Existing Go auth/directory tests and vet.
5. Windows export.
6. Windows executable startup smoke.

Interactive GUI gameplay, save/load GUI, and multiplayer GUI are only marked PASS when the Windows runner actually executes those flows.