# AETHRA: Wildbound — 0.2.3 corrected-final-source

## Continuation release boundary
- Previous Windows artifact: historical and superseded for this continuation pass.
- The engineering source revision `5a7529e` has a successful Windows artifact from CI run `35520501567`; a final documentation commit and CI rerun are required before delivery packaging.
- GUI gameplay, save/load, settings, and multiplayer remain blocked without real interactive Windows automation.

Status: SOURCE RELEASE CANDIDATE — Windows GUI runtime remains BLOCKED BY ENVIRONMENT

Verified in this environment: Godot editor validation, Godot self-test, Go auth-service tests, Go vet, and clean Windows export from the current source revision.
Not verified here: real Windows GUI launch, interactive gameplay validation, multiplayer runtime across Windows clients, and live auth/session integration across actual Windows clients.

Architecture-dependent features intentionally remain PARTIAL when their required backend/infrastructure is not present: social friends, global server discovery, notifications, per-world thumbnail capture, full anti-cheat, and production TLS deployment.
