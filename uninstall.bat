@echo off
REM Dead Man - Uninstaller
REM Removes Dead Man from your system

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\uninstaller.ps1"
