# AETHRA: WILDBOUND

## Current engineering status

The continuation pass fixes a real startup type mismatch, rejects invalid inventory quantities/IDs, and restricts server chat to accepted peers. Godot 4.7.2, the Godot self-test, Go tests, Go vet, and bounded headless startup validation pass locally. Windows GUI gameplay, save/load GUI, settings GUI, and multiplayer GUI remain blocked without interactive automation.

Original 3D open-world voxel survival sandbox game project — corrected release candidate 0.2.3.

## Client

The client is a native Godot application with a recreated premium game hub built from real Godot UI controls (not a screenshot-as-UI). The supplied reference is used for layout, hierarchy and visual language; artwork, branding, icons, characters and sounds remain original.

The current hub includes:
- Home hero panel with local original artwork
- Functional sidebar routing: Home, Solo, Multiplayer, Servers, Worlds, Store, Settings, Profile, Log Out
- Live profile/session state
- Search over saved worlds, saved servers and current network presence
- Recent world cards backed by SaveDB
- Real create/resume/rename/duplicate/backup/delete world actions
- Multiplayer host/join/server-favorites flow
- Live session presence panel
- Honest offline/unknown states instead of fake server/player data
- Runtime FPS/memory/network/node diagnostics
- Native window minimize/maximize/close controls
- Control rebinding, graphics, audio, camera and gameplay settings
- Authentication gate backed by AuthClient with persistent same-device local accounts when no remote auth service is reachable; remote multi-device auth remains deployment-dependent

## Run

Open `project.godot` in Godot 4.7.2 stable.

Client: F6/F5.

Dedicated server scene: `res://server/main_server.tscn`.

Self-test: `godot --headless --path . --script res://tests/self_test.gd`

## Assets

`assets/ui/hero_background.png` is original AETHRA artwork generated for this project. Existing audio assets are local project assets.

## Validation note

Source/static checks and the auth-service test suite were performed in this environment. The current source additionally fixes real control rebinding, fluid rendering, periodic world autosave, persisted day/night/weather state, and remote player state synchronization. Full Godot editor import, Windows runtime, Android export, iOS export, and live dedicated-server/load testing remain blocked by the absence of the Godot 4.7.2 exporter/runtime toolchains in this environment. The project does not claim commercial completion until the release gates are executed on target environments.


## 2026-09-21 audit state
The audited branch enumerates 118 repository files. All 31 GDScript source files were fetched and structurally scanned; critical scenes, project/export configuration, auth schema/service, persistence, networking, world generation, gameplay, UI, tests, and build scripts were inspected. Latest Windows CI on commit `a2116b26b599081be9409e66579d5cea6aa8f995` passed editor validation, GDScript load gate, Godot self-test, Go tests, Go vet, Windows export, EXE process start, and the configured static gate. Interactive GUI gameplay/save/settings/multiplayer checks are explicitly not claimed as PASS when the automation script/environment is unavailable.