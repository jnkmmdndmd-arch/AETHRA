# WINDOWS RUNTIME VERIFICATION

## Summary

This file records the evidence available for the current source revision and the current Windows workflow run. It separates build evidence from GUI/gameplay evidence and does not upgrade build success into gameplay success.

## Source revision
- Commit SHA: 68d037519ade765b263f51542c9c4a26917f6251

## Godot version
- Godot version: 4.7.2.stable.official.ed1daf0bf

## Build result
- Result: PASS
- Evidence: Windows CI run 35515950476 imported and exported the checked-out commit with Godot 4.7.2.

## EXE identity
- EXE SHA: 3f075bc725ef8ce3585d0ac570f3ba3ef8c92ac71c77965b0dafd7bb0568d886
- EXE size: 114236392 bytes

## Process start
- Result: PASS
- Evidence: Windows CI run 35515950476 launched the generated EXE, kept it alive for 15 seconds, then stopped it cleanly.

## GUI result
- Result: BLOCKED BY ENVIRONMENT
- Evidence: the Windows runner had no `tests/windows_gui_smoke.ps1` automation script; no GUI/gameplay claim is made.

## Gameplay result
- Result: BLOCKED BY ENVIRONMENT
- Evidence: no real interactive Windows gameplay session was executed in this environment, so gameplay cannot be marked PASS

## Save/load result
- Result: BLOCKED BY ENVIRONMENT
- Evidence: no actual Windows client session persisted and reloaded using the EXE under test

## Settings result
- Result: BLOCKED BY ENVIRONMENT
- Evidence: no real Windows settings change/restore validation was executed

## Multiplayer result
- Result: BLOCKED BY ENVIRONMENT
- Evidence: no real Windows dedicated server + client validation was executed in this workflow

## Errors found
- Build/import errors: none in the current validation pass
- GUI runtime errors: not observed; GUI automation was unavailable

## Fixes performed
- Verified current source revision and engine version
- Validated project import and self-test under Godot 4.7.2
- Exported the Windows Desktop build from the checked-out current commit
- Recorded the SHA for the produced executable

## Remaining blockers
- Windows UI automation required to validate launch, resize, fullscreen, close, and gameplay actions
- Multiplayer validation requires a real dedicated server and client pair on Windows

## Evidence rule
- BUILD PASS does not imply GUI PASS
- PROCESS START PASS does not imply gameplay PASS
- The only valid gameplay status is evidence from an actual Windows runtime session
