# AETHRA: Wildbound — Verification & Correction Report

Date: 2026-09-19
Source package reviewed: AETHRA-Wildbound-Final-0.2.1.zip (from uploaded all-downloads archive)
Corrected package: 0.2.3 corrected-final-source

## Statement verification

Verified as TRUE in the supplied package:
- Godot project exists and is native Godot, not an HTML client.
- Windows x86_64 export preset exists.
- `binary_format/embed_pck=true` is configured.
- `build_windows.ps1` checks Godot 4.7.2, validates, exports, and enforces a single EXE output directory.
- `assets/icon.png` and `assets/ui/hero_background.png` exist.
- Window is resizable with native minimize/maximize/fullscreen/close actions.
- Native hub uses Godot controls rather than a screenshot-as-UI.

Verified as INACCURATE / INCOMPLETE:
- The package is not a commercial-release-complete implementation of all 58 sections.
- Day/night was already implemented in source despite the old traceability row saying Not implemented; traceability was stale.
- Weather had state changes but no precipitation renderer; it is partial.
- Multiplayer presence existed, but remote player state/3D synchronization was missing; corrected in 0.2.3.
- Settings UI allowed selecting Mine/Place bindings, but `Settings.apply_input_map()` ignored those saved bindings and forced Mouse1/Mouse2; corrected.
- World autosave was primarily close-event based; corrected with periodic autosave.
- Auth server address is user-configurable in the auth gate; the app root default is localhost, so remote auth requires setting the service URL or deployment configuration.
- Server discovery is not a global discovery service; only saved/direct server connections exist.
- Full anti-cheat and moderation are not implemented.
- Windows/Android/iOS release runtime is not verified in this environment.

## Static checks
- Every `res://...` reference resolves to an existing file: PASS
- No bare `pass` stubs remain in scripts: PASS
- Required client/server/assets/docs files exist: PASS
- All local WAV files parse successfully: PASS
- Go auth-service tests: PASS
- Go auth-service vet: PASS

## Release limitation
No Windows EXE is claimed from this environment because Godot 4.7.2 and Windows export templates are not installed here and Windows runtime execution is unavailable.


## Corrections in corrected-v2

- Fixed the custom Hub close button so it uses the same save-and-exit path as an operating-system window close request.
- Removed duplicated UI initialization calls/tooltips that were harmless but unnecessary.
- Fixed the automatic Windows build script so it cleans the output directory contents without deleting the directory required by the subsequent export command.
- The automatic Windows builder now uses the official `godot-builds` release host for the pinned 4.7.2 Windows editor/export-template downloads.
- Added an explicit preflight check for the installed Windows export template before invoking the exporter.
- The previously supplied external SHA-256 value matched the uploaded archive bytes, but its filename reflected the pre-upload name. A new checksum file is generated for the exact corrected-v2 archive filename.

## Remaining architecture-dependent features intentionally not faked

The following are not represented as PASS merely because the project contains UI or placeholders: global friend service, global server discovery, persistent notification service, per-world thumbnail capture, full anti-cheat, production TLS deployment, and Windows/Android/iOS runtime verification. These require additional infrastructure or unavailable runtime environments.
