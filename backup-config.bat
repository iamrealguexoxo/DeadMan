@echo off
REM Dead Man - Config Backup & Restore

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\config-backup.ps1"
