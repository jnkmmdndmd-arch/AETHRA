@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_windows_auto.ps1" -CopyToDesktop
if errorlevel 1 pause
