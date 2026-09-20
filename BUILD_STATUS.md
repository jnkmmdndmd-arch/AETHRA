# AETHRA: Wildbound — Build Status

## Continuation pass
- The current continuation fixes are validated locally with Godot 4.7.2, the Godot self-test, Go tests, and Go vet.
- Windows CI run `35517353496` rebuilt the pushed continuation commit and passed export, hash, and process-start checks.

## Implemented in source
- Native Godot client hub rebuilt with functional sidebar, search, profile, hero, quick actions, recent worlds, social panel, server favorites, discovery fallback, settings, developer metrics, notifications empty-state, and window controls.
- Real data bindings for SaveDB, AppState, NetworkManager, ServerDirectory, Engine/Performance, Settings, and AudioManager.
- World resume, rename, duplicate, backup, delete flows are connected to SaveDB.
- Remote join waits for authoritative world metadata instead of inventing a seed on connection.
- Dedicated-server export points to `server/main_server.tscn`.
- Original generated hero artwork is stored locally under `assets/ui/hero_background.png`.

## Current verification state
- Godot editor validation: PASS
- Godot self-test: PASS
- Go auth-service tests: PASS
- Go vet: PASS
- Clean Windows export from current source: PASS
- Windows GUI runtime execution: BLOCKED BY ENVIRONMENT
- Android/iOS export: BLOCKED BY ENVIRONMENT
- Global server discovery: not implemented as a live external service
- Store commerce: not implemented as a live production backend

## Rule
The project is verified for editor import, headless source validation, and clean Windows export from the current source. Real Windows GUI gameplay verification remains BLOCKED BY ENVIRONMENT because this host is Linux and no real Windows runtime is available.

## Release hardening (current)
- Windows export preset targets x86_64 with embedded project resources (`binary_format/embed_pck=true`).
- `build_windows.ps1` verifies Godot 4.7.2, cleans stale build files, exports Release, and enforces a one-file `AETHRA-Wildbound.exe` release directory.
- Windows CI is configured with the official Godot setup action and export templates and can be started manually with `workflow_dispatch`.
- `build_windows.ps1 -CopyToDesktop` copies the verified EXE to the Windows user's Desktop after export.
- The current execution environment is Linux and has no Godot 4.7.2 exporter installed, so Windows runtime remains BLOCKED BY ENVIRONMENT here.
