# AETHRA: WILDBOUND

## Current engineering status

The continuation pass fixes a real startup type mismatch, rejects invalid inventory quantities/IDs, and restricts server chat to accepted peers. Godot 4.7.2, the Godot self-test, Go tests, Go vet, and bounded headless startup validation pass locally. Windows GUI gameplay, save/load GUI, settings GUI, and multiplayer GUI remain blocked without interactive automation.

Original 3D open-world voxel survival sandbox game project — corrected release candidate 0.2.3.

## Client

The client is a native Godot application with a recreated premium game hub built from real Godot UI controls (not a screenshot-as-UI). The supplied reference is used for layout, hierarchy and visual language; artwork, branding, icons, characters and sounds remain original.

The current hub includes:
- Home hero panel with local original artwork
- Functional sidebar routing: Home, Solo, Multiplayer, Servers, Worlds, Store, Settings, Developer Tools, Log Out
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
- Authentication gate backed by the existing AuthClient, with an explicit offline path

## Run

Open `project.godot` in Godot 4.7.2 stable.

Client: F6/F5.

Dedicated server scene: `res://server/main_server.tscn`.

Self-test: `godot --headless --path . --script res://tests/self_test.gd`

## Assets

`assets/ui/hero_background.png` is original AETHRA artwork generated for this project. Existing audio assets are local project assets.

## Validation note

Source/static checks and the auth-service test suite were performed in this environment. The current source additionally fixes real control rebinding, fluid rendering, periodic world autosave, persisted day/night/weather state, and remote player state synchronization. Full Godot editor import, Windows runtime, Android export, iOS export, and live dedicated-server/load testing remain blocked by the absence of the Godot 4.7.2 exporter/runtime toolchains in this environment. The project does not claim commercial completion until the release gates are executed on target environments.
