# WINDOWS RUNTIME VERIFICATION

## Current source revision
- Commit SHA: `c1be0e76f5a049c670cd1778f07a97d37b9c8433`
- CI run: `35526554338`
- Godot: `4.7.2.stable.official.ed1daf0bf`

## Automated verification
- Godot editor validation: PASS
- Full GDScript parse validation: PASS
- Godot self-test: PASS
- Go tests: PASS
- Go vet: PASS
- Windows export: PASS
- Windows EXE process start for 15 seconds: PASS

## GUI/gameplay verification
- Result: BLOCKED BY ENVIRONMENT
- The workflow completed successfully, but `tests/windows_gui_smoke.ps1` is not present in the repository, so the workflow explicitly did not claim GUI automation.
- Save/load, settings interaction, account interaction, gameplay, and multiplayer remain unverified by interactive Windows automation.

## Current source fixes represented by this revision
- Fixed the strict GDScript chunk type inference failure in `scripts/world/voxel_world.gd`.
- Fixed the related neighbor typing failure.
- Reworked auth HTTPRequest lifecycle to permit concurrent-independent requests without reusing a busy HTTPRequest.
- Added persistent session restore with auth-service verification and invalid-session clearing.
- Reworked main-menu responsiveness for 1366x768 and larger desktop resolutions.
- Replaced UI emoji/symbol glyphs with drawn vector icons, including the online-player person icon.
- Localized world creation and other affected UI text to prevent mixed-direction display issues.

## Evidence rule
Build and process-start PASS do not imply gameplay PASS.
