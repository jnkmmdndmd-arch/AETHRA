# UI Traceability Update

Reference: supplied AETHRA: Wildbound production client/UI specification.

PASS source implementation:
- 1 Sidebar: native Godot buttons with real page routing.
- 2 Header: real search, notifications, profile, minimize/maximize/close actions.
- 3 Profile: AppState-backed session/profile state.
- 4 Hero: native UI over original local artwork; real Play flow.
- 5 Play flow: solo/multiplayer/server entry points connected.
- 6 Quick actions: create world/multiplayer/servers invoke real handlers.
- 7 Create world: fields persist via AppState and SaveDB when the world starts.
- 8 Multiplayer: Host/Join/Server Browser entry points.
- 9 Server browser: saved server data only; no fabricated status.
- 10 Friends: live NetworkManager presence only.
- 12 World cards: SaveDB-backed recent worlds.
- 17 Settings: graphics/audio/control values connected to Settings.
- 18 Developer tools: live Engine/Performance/network/storage metrics.
- 19 Status bar: live connection/FPS/friends values.
- 20 Window controls: actual DisplayServer operations.
- 21 Responsive layout: Containers/anchors used for main shell and cards.
- 23 Animations: intro fade and themed hover/pressed states.
- 24/25 Loading/error: network errors and empty states are not replaced with fake success.
- 26 Online/offline: UI derives connection from MultiplayerPeer.
- 28 Data binding: UI reads providers rather than duplicating records.
- 29 Multiplayer flow: real NetworkManager connection path; world metadata from authority.
- 31 Save UI: SaveDB is used for resume/delete/rename/duplicate/backup.
- 32 Account: existing AuthClient/AppState integration point.
- 33 Security: UI does not substitute for server authorization.
- 34 Performance: lazy content refresh and no static screenshot as UI.
- 35 Assets: original local hero art, no copied game assets.
- 38 Notifications: truthful empty-state until a real notification backend exists.
- 41 World status: actual SaveDB metadata.
- 43 No mock UI: unavailable services are explicitly unavailable.
- 44 Godot client: implemented as native Control nodes.
- 45 Windows release settings: existing Windows export preset retained.
- 49 Documentation: architecture/build/traceability updated.

PARTIAL/BLOCKED:
- 13 thumbnail capture/actual world screenshot generation is not yet automatic.
- 15 global discovery/community metrics require a real service.
- 16 commerce requires payment/backend.
- 22 accessibility beyond keyboard/focus basics needs a dedicated QA pass.
- 36 full localization resource migration is not complete.
- 39 modding UI is architecture-only.
- 40 server invitation flow needs persistent social backend.
- 46 Windows runtime QA is blocked in this environment.
- 47 automated Godot UI tests are blocked by missing Godot runtime.
