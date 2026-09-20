# Security

The multiplayer client is not authoritative. Server-side gates are required for:
- block changes
- inventory changes
- combat and damage
- movement sanity checks
- permissions

Authentication service stores password-derived hashes rather than plaintext passwords. Secrets belong in environment variables or deployment secret storage.

For Internet deployment, terminate TLS at a trusted reverse proxy and keep the game server on a private network whenever practical.
