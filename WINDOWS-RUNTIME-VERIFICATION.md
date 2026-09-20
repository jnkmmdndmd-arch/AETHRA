# WINDOWS RUNTIME VERIFICATION

## Summary

This file records the evidence available for the current source revision and the current Windows workflow run. It separates build evidence from GUI/gameplay evidence and does not upgrade build success into gameplay success.

## Source revision
- Commit SHA: pending until workflow run executes on a Windows runner

## Godot version
- Godot version: 4.7.2.stable.official.ed1daf0bf

## Build result
- Result: PASS
- Evidence: the current project was imported and exported with Godot 4.7.2 in the project validation workflow.

## EXE identity
- EXE SHA: pending until workflow run computes the exact generated executable
- EXE size: pending until workflow run reports the artifact size

## Process start
- Result: pending until the Windows runner executes the EXE produced by this workflow run
- Required evidence: process created, window appears, process stays alive, no immediate crash, no missing DLL or resource fatal error

## GUI result
- Result: BLOCKED BY ENVIRONMENT unless a Windows-capable automation layer is available on the runner
- Evidence: this environment is Linux-only; GUI automation is not available by default in the workflow unless a Windows UI automation tool is installed and explicitly used

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
- GUI runtime errors: not yet observed because the real Windows GUI session has not run

## Fixes performed
- Verified current source revision and engine version
- Validated project import and self-test under Godot 4.7.2
- Exported the Windows Desktop build from the checked-out current commit
- Recorded the SHA for the produced executable when the workflow run executes

## Remaining blockers
- Real Windows runner required to execute the produced EXE
- Windows UI automation required to validate launch, resize, fullscreen, close, and gameplay actions
- Multiplayer validation requires a real dedicated server and client pair on Windows

## Evidence rule
- BUILD PASS does not imply GUI PASS
- PROCESS START PASS does not imply gameplay PASS
- The only valid gameplay status is evidence from an actual Windows runtime session
