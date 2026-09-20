# FINAL RUNTIME VERIFICATION

Date: 2026-09-20

## Build artifact

- Commit SHA: `af4e527fae8f1e721fd97c80dbba7992b05c897a`
- Godot version: `4.7.2.stable.official.ed1daf0bf`
- Windows EXE: `AETHRA-Wildbound.exe`
- EXE size: `109M`
- SHA-256: `2a6d8b28121beac64ce00701f633e284a6d127267dc8b2b3f3b4417bb049009f`
- Source ZIP: `AETHRA-Wildbound-source.zip`

## Automated verification commands

### Godot smoke test

```bash
cd /workspaces/AETHRA && timeout 180 ./.tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/self_test.gd
```

Actual result:

```text
SELFTEST_EXIT:0
[TEST] Block registry: PASS
[TEST] Item registry: PASS
[TEST] Recipes: PASS
[TEST] Deterministic terrain: PASS
[TEST] World bounds: PASS
[TEST] Survival damage: PASS
```

### Go auth-service validation

```bash
cd /workspaces/AETHRA/server/auth-service && go test ./... && go vet ./...
```

Actual result:

```text
ok      aethra-auth     (cached)
```

### Clean export build

```bash
cd /workspaces/AETHRA && rm -rf build && mkdir -p build && ./.tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --editor --quit && ./.tools/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --export-release "Windows Desktop" build/AETHRA-Wildbound.exe
```

Actual result:

- Export completed successfully.
- Artifact exists at `build/AETHRA-Wildbound.exe`.
- Hash: `2a6d8b28121beac64ce00701f633e284a6d127267dc8b2b3f3b4417bb049009f`

## Runtime classification

### PASS
- Registry initialization and data integrity
- Recipe lookup and validation
- Deterministic world generation for a fixed seed
- World bounds validation
- Survival damage flow
- Editor project validation in Godot 4.7.2
- Auth service tests

### PARTIAL
- Full gameplay runtime loop is not directly user-driven in this Linux environment because the host cannot launch a Windows GUI application.

### BLOCKED BY ENVIRONMENT
- Real Windows execution of the built `.exe`
- Real multiplayer runtime with server + two Windows clients
- Full user-driven gameplay validation through the interactive UI path

## Root-cause fixes performed

1. Resolved Godot 4.7 strict-type parser issues by adding explicit typed variables and guarded dictionary handling.
2. Reworked the smoke test so it validates actual registry and generator behavior without depending on autoload globals in a headless scene test.
3. Hardened world generation to avoid autoload-only assumptions while preserving the in-game logic.

## Final release decision

This is not a claim of full commercial release readiness. The evidence supports an export-capable and automated-validation-passing source revision, but real Windows runtime gameplay verification remains blocked by the Linux host environment.
