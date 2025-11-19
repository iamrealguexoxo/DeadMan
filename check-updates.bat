@echo off
REM Dead Man - Quick Update Check

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\check-updates.ps1"
