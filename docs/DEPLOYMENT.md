# Deployment

## Windows client
Install Godot 4.7.2 stable and export the `Windows Desktop` preset. The resulting EXE contains the game project assets; it is not a browser wrapper.

## Dedicated server
Export the `Linux Dedicated Server` preset or run the project headless with the dedicated-server flag. Godot documents both dedicated-server exports and headless operation.

## Auth service
Build and run `server/auth-service` on Linux. Store `AETHRA_AUTH_SECRET` in deployment secrets and terminate HTTPS at a reverse proxy. The game server and auth service must share the same secret when token verification is enabled.

## Android/iOS
Use the Android/iOS presets with the appropriate platform SDK/signing setup. Android release packages require signing configuration; iOS release packaging requires the Xcode/Apple signing chain.
