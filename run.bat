@echo off
REM Dead Man - Smart Launcher
REM Checks installation status and runs accordingly

REM Check if already installed by looking for scheduled tasks
schtasks /query /tn "DeadMan-UpdateLastLogin" >nul 2>&1
if %errorlevel% equ 0 (
    REM Already installed, just start
    "%~dp0DeadMan.exe"
) else (
    REM Not installed, run installer first
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup\installer.ps1"
)
