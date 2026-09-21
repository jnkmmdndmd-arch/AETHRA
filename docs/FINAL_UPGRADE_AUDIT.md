# AETHRA: WILDBOUND — Final Upgrade Audit

## Scope
This source bundle is the upgraded working tree produced from the supplied project archive.
It contains the gameplay, voxel, persistence, authentication, multiplayer, economy, creature, UI,
weather, server-directory, build and installer changes requested during the audit.

## Implemented in this upgrade

- World height presets: 500 / 800 / 1000.
- World horizontal boundary: +/-32768 on X/Z (64k span).
- Deterministic terrain with biome, cave, ore, water and vegetation generation.
- Chunk streaming with distance budgets and LOD1 heightfield meshes.
- Greedy opaque voxel meshing, fluid mesh separation, collision budgeting, AO-like shading and emission contribution.
- Dynamic weather controller with rainfall particles.
- Day/night state persistence and weather validation.
- 30 creature types with hostile subset, target selection, line-of-sight checks, despawn budget and loot.
- Survival damage/death/respawn and food consumption.
- Inventory validation and persistent server-side per-user inventory snapshots.
- Expanded crafting catalogue and an inventory/crafting UI.
- Local persistent economy/shop and coin wallet.
- Multiplayer sender validation, movement distance validation, authoritative block mutation and PvP validation.
- External auth-session validation with HTTPS requirement for non-local endpoints.
- Username policy, session revocation and prepared SQLite statements in auth service.
- Save file structure validation, backup rotation, previous-save fallback and temporary-file replacement.
- LAN discovery, favorites persistence and optional global server directory service.
- Server moderation commands with environment-configured admin IDs.
- Windows standalone export plus Inno Setup installation package.
- Desktop shortcut, Start Menu shortcut and Windows uninstall registration.

## Verification performed locally

- Go auth service tests: PASS.
- Go directory service tests: PASS.
- Go vet on both Go services: PASS.
- Server build shell syntax: PASS.
- Project inventory: 126 files in the upgraded working tree.
- Script inventory: 33 source-code files.

## Environment-limited gates

- Godot editor/parser runtime: not available in the current Linux container.
- Windows export and Windows GUI interaction: delegated to the GitHub Windows runtime workflow.
- Real two-client multiplayer gameplay: requires Windows/Godot runtime execution.

## Release truth rule
No runtime-only gate is marked PASS by this document. Final Windows release status is determined by the corresponding CI run and its uploaded verification report.