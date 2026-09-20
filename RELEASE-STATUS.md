# AETHRA: Wildbound — 0.2.3 corrected-final-source

## Windows release
- Release tag: `aethra-windows-0.2.3-final`
- Release commit: recorded after the production documentation update and Windows CI rebuild.
- Windows build: PASS after the pushed release commit is rebuilt by CI.
- EXE SHA-256: recorded in `WINDOWS-RUNTIME-VERIFICATION.md` and the release asset checksum.
- Windows ZIP SHA-256: recorded when the GitHub Release asset is uploaded.
- Release date: 2026-09-20
- GUI gameplay, save/load, settings, and multiplayer remain blocked without real interactive Windows automation.

Status: RELEASE CANDIDATE — Windows GUI runtime remains BLOCKED BY ENVIRONMENT

Verified in this environment: Godot editor validation, Godot self-test, Go auth-service tests, Go vet, and clean Windows export from the current source revision.
Not verified here: real Windows GUI launch, interactive gameplay validation, multiplayer runtime across Windows clients, and live auth/session integration across actual Windows clients.

Architecture-dependent features intentionally remain PARTIAL when their required backend/infrastructure is not present: social friends, global server discovery, notifications, per-world thumbnail capture, full anti-cheat, and production TLS deployment.

## 2026-09-20 source repair batch
- Current source includes fixes for the confirmed `voxel_world.gd` parser issue, concurrent authentication HTTPRequest handling, and responsive UI layout.
- Windows release artifacts must be rebuilt from the new commit before they are associated with this source state.
- Interactive Windows gameplay/settings/auth verification remains pending until the new artifact is tested.
