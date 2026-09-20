# Commercial Release Gates

AETHRA is not declared commercially complete until all of the following are demonstrated on target hardware/infrastructure:

1. Godot project opens without errors in the chosen stable engine.
2. Windows release export launches and survives 30-minute soak.
3. Android AAB/APK release export installs on supported devices.
4. iOS release export builds in Xcode and passes signing/archive checks.
5. Dedicated Linux server runs headless and survives reconnect tests.
6. Remote authentication runs behind TLS with a production secret.
7. Multiplayer load test covers the announced player capacity.
8. Movement, inventory, block and combat server authority tests pass under tampered packets.
9. Save/recovery tests cover crash during snapshot write.
10. Profiling reports meet frame-time and server-tick budgets for each target tier.
11. Security assessment records packet validation, rate limiting, permission enforcement and secret handling.
12. Asset provenance/license records are complete.
