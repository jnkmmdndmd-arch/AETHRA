#!/usr/bin/env bash
set -euo pipefail
godot --headless --path . --export-release "Linux Dedicated Server" build/aethra-server
