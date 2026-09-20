# Build Matrix — AETHRA: Wildbound

| Target | Preset / entry | Status in this environment | Evidence | Required next validation |
|---|---|---|---|---|
| Windows x64 | `Windows Desktop` | RELEASE BUILD REQUIRED / GUI BLOCKED BY ENVIRONMENT | Release CI rebuilds the exact pushed commit and publishes the verified ZIP | Real interactive Windows GUI automation |
| Linux dedicated server | `server/main_server.tscn` | SOURCE READY | Dedicated server scene + entry point + NetworkManager binding | Headless export/run on Linux |
| Android | `Android` | CONFIGURED | Export preset exists | Android SDK, export templates, install/runtime QA |
| iOS | `iOS` | CONFIGURED | Export preset exists | macOS/Xcode/signing/export QA |
| Auth service Linux x64 | `server/auth-service` | TESTED PREVIOUSLY | Existing Go tests/service artifact | Deploy behind TLS and production secret |
| UI hub | `scripts/ui/main_menu.gd` | SOURCE IMPLEMENTED | Native Control-node implementation | Godot editor import and interactive UI test |
| Settings | `scripts/ui/settings_menu.gd` | SOURCE IMPLEMENTED | Settings + rebinding callbacks | Interactive persistence test on Windows |
| World persistence | `scripts/persistence/save_db.gd` | SOURCE IMPLEMENTED | Resume/rename/duplicate/backup/delete methods | Crash/recovery runtime test |
| Remote world metadata | `scripts/network/network_manager.gd` | SOURCE IMPLEMENTED | Server-to-client `receive_world_state` RPC | Dedicated-server reconnect test |
