# AETHRA: Wildbound — Build Status

## Windows release preparation
- The production documentation update is pushed before the release build.
- The release build must come from the exact pushed commit and be verified by Windows CI before publication.
- The release asset is `AETHRA-Wildbound-Windows-FINAL.zip`.

## Implemented in source
- Native Godot client hub rebuilt with functional sidebar, search, profile, hero, quick actions, recent worlds, social panel, server favorites, discovery fallback, settings, developer metrics, notifications empty-state, and window controls.
- Real data bindings for SaveDB, AppState, NetworkManager, ServerDirectory, Engine/Performance, Settings, and AudioManager.
- World resume, rename, duplicate, backup, delete flows are connected to SaveDB.
- Remote join waits for authoritative world metadata instead of inventing a seed on connection.
- Dedicated-server export points to `server/main_server.tscn`.
- Original generated hero artwork is stored locally under `assets/ui/hero_background.png`.

## Current verification state
- Godot editor validation: PASS on source revision `c1be0e76f5a049c670cd1778f07a97d37b9c8433`
- Full GDScript parse validation: PASS
- Godot self-test: PASS
- Go auth-service tests: PASS
- Go vet: PASS
- Clean Windows export: PASS on CI run `35526554338`
- Windows executable process start: PASS on CI run `35526554338`
- Windows GUI/gameplay automation: BLOCKED BY ENVIRONMENT
- Android/iOS export: BLOCKED BY ENVIRONMENT
- Global server discovery: not implemented as a live external service
- Store commerce: not implemented as a live production backend

## Rule
The project is verified for editor import, headless source validation, and clean Windows export from the CI-checked source revision. Real Windows GUI gameplay verification remains BLOCKED BY ENVIRONMENT because no interactive GUI automation is available.

## Release hardening (current)
- Windows export preset targets x86_64 with embedded project resources (`binary_format/embed_pck=true`).
- `build_windows.ps1` verifies Godot 4.7.2, cleans stale build files, exports Release, and enforces a one-file `AETHRA-Wildbound.exe` release directory.
- Windows CI is configured with the official Godot setup action and export templates and can be started manually with `workflow_dispatch`.
- `build_windows.ps1 -CopyToDesktop` copies the verified EXE to the Windows user's Desktop after export.
- The current execution environment is Linux and has no Godot 4.7.2 exporter installed, so Windows runtime remains BLOCKED BY ENVIRONMENT here.

## 2026-09-20 runtime/UI bugfix batch
- Fixed strict GDScript type inference in `scripts/world/voxel_world.gd` for runtime chunk creation and neighbor coordinates.
- Reworked authentication HTTPRequest handling so login, registration, and logout do not collide on one busy HTTPRequest.
- Made the main menu responsive for 1366×768 by adapting sidebar/social panels, centered auth layout, hero height, and popup anchoring.
- Changed the default Windows window size from 1600×900 to 1366×768 to match the tested target display.
- Runtime/Windows verification is still required after this source change; no gameplay PASS is claimed yet.

## Current source repair state
- UI navigation uses drawn vector icons instead of decorative emoji/symbol glyphs.
- The online-player area uses a drawn person icon and only displays real network presence data.
- Arabic UI layout is explicitly RTL and responsive at the target desktop sizes.
- World creation display labels are localized while internal IDs remain stable.
- Authentication requests use independent HTTPRequest instances, and saved sessions are revalidated against the auth service on startup.
- Historical Windows artifact hashes remain historical and are not associated with the current commit.
- No unambiguously unrelated production file was deleted; Godot metadata, source, server, test, asset, and engineering documentation files remain because they are part of the project or its validation.
