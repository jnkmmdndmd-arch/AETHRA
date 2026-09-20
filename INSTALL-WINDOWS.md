# Windows installation / export

## Requirements

- Godot 4.7.2 stable (standard Windows build).
- Godot 4.7.2 Windows export templates.

## Build a single portable EXE

From a PowerShell terminal opened at the project root:

```powershell
.\build_windows.ps1 -Godot godot -Output build\AETHRA-Wildbound.exe -CopyToDesktop
```

The script:

1. Verifies the Godot version is 4.7.2.
2. Validates the project in headless mode.
3. Cleans the previous `build` directory.
4. Exports the `Windows Desktop` Release preset.
5. Verifies that `build` contains exactly one file: `AETHRA-Wildbound.exe`.
6. Writes `AETHRA-Wildbound.exe.sha256` outside the release directory.
7. With `-CopyToDesktop`, copies the verified EXE to the current Windows user's Desktop.

The Windows export preset uses x86_64 and embedded PCK resources so the release is intended to be a single portable executable.

## One-click Windows build

On a Windows 10/11 PC with internet access, double-click `BUILD-WINDOWS-ONECLICK.cmd`.
It downloads the official Godot 4.7.2 Windows runtime and export templates when needed, validates the project, exports `AETHRA-Wildbound.exe`, performs the one-file check, writes SHA-256, and copies the verified EXE to the Desktop.

`build_windows_auto.ps1` uses the official Godot 4.7.2 Windows x86_64 release package.

## GitHub Actions

The repository CI includes a Windows Release job using Godot 4.7.2 and export templates. It publishes `AETHRA-Wildbound.exe` as a GitHub Actions artifact after the standalone-file check.

## Important

A Windows runtime test must be performed on a real Windows 10/11 machine or VM before calling the release runtime-verified. Linux source/build checks do not prove Windows runtime behavior.
