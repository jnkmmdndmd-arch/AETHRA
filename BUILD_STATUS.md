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
- Godot editor validation: PASS on source revision `f3cdbbbe4cf22a20f9395e55e7406a0df3c164e1`
- Full GDScript parse validation: PASS
- Godot self-test: PASS
- Go auth-service tests: PASS
- Go vet: PASS
- Clean Windows export: PASS on CI run `35528036255`
- Windows executable process start: PASS on CI run `35528036255`
- Windows GUI/gameplay automation: BLOCKED BY ENVIRONMENT
- Current Windows artifact SHA-256: `fc6df94ff511cdc6b8f7e0d013d1e861dae2055152583f67e35fbc0f69e9ddaa`
- Current exported EXE SHA-256: `1d6115adb96df5e4294007631d54cfbcea6cc6c70acc3a9c71d490fe516f7e3e`
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
- Windows CI validation for source revision `f3cdbbbe4cf22a20f9395e55e7406a0df3c164e1` is now complete: parser/load gates, Godot self-test, Go tests/vet, Windows export, EXE identity, and process start passed. Interactive GUI gameplay/save/load/settings/multiplayer remain blocked by runner environment.

## Current source repair state
- UI navigation uses drawn vector icons instead of decorative emoji/symbol glyphs.
- The online-player area uses a drawn person icon and only displays real network presence data.
- Arabic UI layout is explicitly RTL and responsive at the target desktop sizes.
- World creation display labels are localized while internal IDs remain stable.
- Authentication requests use independent HTTPRequest instances, and saved sessions are revalidated against the auth service on startup.
- Historical Windows artifact hashes remain historical and are not associated with the current commit.
- Stale delivery/verification report files and the unused `assets/icon.svg` vector asset were removed from the repository; required Godot metadata, source, server, tests, assets, and engineering documentation remain.


## 2026-09-21 low-end performance pass
- Reduced the initial world area from 25 chunks to 9 and changed streaming from a square radius to a circular radius.
- Mesh rebuilds are budgeted across frames; collision generation is separated and limited to nearby chunks.
- Cached block solidity/colors during chunk meshing to remove repeated registry lookups.
- Optimized terrain generation to calculate surface/biome once per column instead of once per block.
- Added real 3D resolution scaling and adaptive runtime scaling for low/medium profiles while keeping the 2D UI at native window resolution.
- Lowered low-end defaults and creature counts to reduce CPU/physics load.


## 2026-09-21 audited release
- Branch: `fix/aethra-ui-auth-performance`
- Audited commit before documentation-only updates: `a2116b26b599081be9409e66579d5cea6aa8f995`
- Windows CI run: `35641143024`
- Godot editor validation: PASS
- GDScript load gate: PASS
- Godot self-test: PASS
- Go auth-service tests: PASS
- Go vet: PASS
- Windows export: PASS
- EXE process start: PASS
- GUI/gameplay/save/load/settings/multiplayer automation: BLOCKED — the repository does not currently contain `tests/windows_gui_smoke.ps1`, so the workflow cannot claim interactive GUI verification.
- Audited artifact SHA-256: `d3e256e8f2a8ae4061ef156841f6f55319fbd67b341594894736c50aacafe599`
- Repository scope: 118 files total, including 31 GDScript files; all 31 GDScript source files were fetched and structurally scanned in batches, and critical scene/config/build/security/gameplay files were inspected.
- Persistent local account fallback is implemented and tested through source/CI gates. Public multi-device account service deployment is BLOCKED without an external deployed auth endpoint and shared secret.
