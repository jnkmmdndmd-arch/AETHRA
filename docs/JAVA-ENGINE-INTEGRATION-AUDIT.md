# Java / Minecraft Engine Integration Audit

Date: 2026-09-22

## Input audited

The supplied archive `minecraft v1.17.1.zip` is an installed Minecraft Java 1.17.1 runtime package. It is not a Java source repository.

Measured contents:

- 3819 archive entries.
- 1.17.1 client JAR: 19,546,842 bytes.
- 6113 Java class files inside the 1.17.1 JAR.
- 7433 JSON resources, 2241 PNG resources and 866 NBT resources inside the JAR.
- 182 dependency JARs in the supplied installation tree.
- 0 `.java` source files.
- 0 Gradle build files.
- 0 Maven POM files.
- 0 mapping/source trees.
- `saves/` is present but empty; no Minecraft Anvil world was supplied.

The version manifest identifies the client entry point as `net.minecraft.client.main.Main`.

## Architectural decision

A compiled/obfuscated client JAR is a runtime artifact, not a refactorable Java source engine. Treating that JAR as if it were a source project would produce a fake “integration” with no maintainable Java gameplay layer.

AETHRA therefore remains one coherent application:

`AETHRA UI/HUD -> AETHRA client/presentation -> gameplay/world abstractions`

The Java/Minecraft package is handled through an explicit integration boundary. It can be inspected and identified as:

1. a real Java source project;
2. a compiled Java/Minecraft runtime package; or
3. missing/unavailable.

The bridge never silently treats a runtime JAR as source code.

## AETHRA authoritative systems

The current project already provides working implementations for:

- voxel world generation/chunk streaming
- blocks and interaction
- player movement, camera and collision
- inventory, items and crafting
- creatures and hostile mobs
- day/night and weather
- saving/loading and autosave
- networking
- graphics/audio/camera settings and input rebinding
- custom menu/HUD/profile/authentication

These remain authoritative until an actual Java source backend or supported Java server API is supplied.

## Visual/resource integration

The supplied client resources have been adapted into the AETHRA visual layer instead of replacing the AETHRA UI:

- blocky Minecraft-style player geometry
- transformed 64x64 player skin
- compact voxel texture atlas
- responsive HUD/crosshair/mouse-focus fixes

No second game is presented to the user at runtime.

## What the current ZIP does not provide

The requested replacement of AETHRA's gameplay engine by the Java engine cannot be completed from this ZIP alone because it does not contain:

- Java source code
- Gradle/Maven source build definitions
- mappings/source distribution
- a stable AETHRA interoperability API
- a Minecraft saved world to import and validate

For a real Java gameplay backend, the missing input is an authorized Java source/development project (source + build metadata + dependencies) or an explicitly supported server/backend API.

## Legal/resource handling

Minecraft's current official Usage Guidelines state that users must not redistribute Minecraft games or modified game files, and that Minecraft assets remain Mojang/Microsoft property. Any distribution of Minecraft-derived client code or assets therefore requires the necessary permission/license beyond simply having a local installation. citeturn315755search0turn315755search2

The bridge is designed so the user's local runtime can remain external instead of forcing the public AETHRA repository to ship the complete Minecraft client package.

## Validation

The PR5 integration branch passed static checks, Godot editor validation, GDScript load validation, Godot smoke testing, Go tests, Go vet, Windows export, EXE verification and process startup.

Interactive Windows GUI/gameplay automation remains environment-dependent.
