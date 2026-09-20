# Networking

Transport: ENet through Godot's `ENetMultiplayerPeer`.

RPC classes:
- profile join/presence
- block change request and authoritative broadcast
- chat

The server receives the sender peer ID from the transport and ignores the client-provided identity for authorization-sensitive operations.

Production hardening still required before public Internet deployment: packet rate limiting, server-side movement reconciliation, robust inventory replication, connection authentication with expiring tokens, and TLS-protected auth service.
