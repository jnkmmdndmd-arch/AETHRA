# AETHRA: Wildbound — local verification (2026-09-19)

## Verified with available tooling

- Package structure inspected after extraction.
- All referenced `res://...` resource paths found: 43 unique references, 0 missing in the current source package.
- No NUL bytes found in source/config/doc files inspected.
- Go auth service: `go test ./...` PASS.
- Go auth service: `go vet ./...` PASS.
- Auth binary identified as Linux x86-64 ELF.
- Windows export preset specifies x86_64 and `binary_format/embed_pck=true`.
- Project declares Godot 4.7 feature compatibility.
- The supplied archive SHA-256 was verified against its uploaded bytes; the hash matched, but the embedded checksum filename referred to the pre-upload archive name.

## Corrections applied in this package (same project, no new game)

1. Fixed the same-project UI initialization and custom Hub close button now calls the centralized save-and-exit path so closing from inside the game performs the same save/window-state work as an operating-system close request.
2. Removed redundant Hub UI initialization/tooltip duplication.
3. Fixed the automatic Windows build script so it cleans the output directory contents without deleting the directory needed by the subsequent export.
4. Updated the automatic Windows builder to download the pinned 4.7.2 Windows build and export templates from the official Godot builds repository.
5. Added an explicit Windows export-template preflight to the non-download build script.
6. Refreshed the internal SHA-256 manifest for modified files.

## Not verifiable in this environment

- Godot 4.7.2 editor/import/runtime execution.
- Windows x86_64 export execution.
- Launching the final Windows executable on Windows.
- Windows standalone runtime test with only one EXE.
- Live dedicated-server multiplayer load test.
- Android/iOS runtime export testing.

Therefore this package does **not** claim a Windows runtime PASS or a final commercial release. The Windows release remains subject to running the included build script on Windows with Godot 4.7.2 export templates, followed by a real Windows runtime smoke test.
