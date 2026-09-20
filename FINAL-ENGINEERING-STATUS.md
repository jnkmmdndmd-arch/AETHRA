# AETHRA: WILDBOUND ENGINEERING STATUS

## Current scope

This status describes the continuation pass after the previously verified Windows release. It records only evidence obtained from the current source and local validation; GUI gameplay and multiplayer remain separate runtime gates.

## Changes in this pass

- Fixed the app-root/UI builder contract so `Node3D` ownership is accepted by the menu, settings, and developer-console builders.
- Rejected negative inventory quantities and invalid fluid/lava/bedrock inventory IDs.
- Required accepted peers and non-empty trimmed text for server chat.
- Cleaned standalone self-test registry objects to remove its observed ObjectDB/resource leak warnings.

## Cleanup classification

- Historical verification documents: KEEP.
- Active source, scenes, assets, server dependencies, and build configuration: KEEP.
- Existing generated EXE, ZIP, checksum, local Godot toolchain, and delivery directory: NOT SOURCE; replace or exclude during final packaging.
- No uncertain production file was deleted.

## Evidence status

- Godot editor validation: PASS on Godot 4.7.2.
- Godot self-test: PASS.
- Actual project headless startup: PASS during the bounded startup check.
- Go tests: PASS.
- Go vet: PASS.
- Windows GUI gameplay, save/load GUI, settings GUI, and multiplayer GUI: BLOCKED BY ENVIRONMENT until real interactive automation is available.