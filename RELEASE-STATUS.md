# AETHRA: Wildbound — 0.2.3 corrected-final-source

## Historical Windows release
- Release tag: `aethra-windows-0.2.3-final`
- This release belongs to the earlier source state and is not the current source artifact.
- Release date: 2026-09-20
- GUI gameplay, save/load, settings, and multiplayer remain blocked without real interactive Windows automation.

Status: CURRENT SOURCE REPAIRED — GUI gameplay still requires interactive validation

Current CI evidence for source revision `c1be0e76f5a049c670cd1778f07a97d37b9c8433`: Godot editor validation, full GDScript parse, self-test, Go tests, Go vet, Windows export, and Windows process-start all passed.
Not verified here: real Windows GUI launch, interactive gameplay validation, multiplayer runtime across Windows clients, and live auth/session integration across actual Windows clients.

Architecture-dependent features intentionally remain PARTIAL when their required backend/infrastructure is not present: social friends, global server discovery, notifications, per-world thumbnail capture, full anti-cheat, and production TLS deployment.

## 2026-09-20 source repair batch
- Current source includes fixes for the confirmed `voxel_world.gd` parser issue, concurrent authentication HTTPRequest handling, and responsive UI layout.
- Windows release artifacts must be rebuilt from the new commit before they are associated with this source state.
- Interactive Windows gameplay/settings/auth verification remains pending until the new artifact is tested.

## Current UI and source cleanup
- Removed decorative emoji/symbol glyphs from the game UI and replaced functional icons with drawn vector controls.
- Reworked Arabic RTL layout in the main menu, settings, social panel, and HUD.
- The source tree was reviewed for unrelated files; no production file was clearly unrelated enough to delete safely.
