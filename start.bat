@echo off
REM ===================================================================
REM Dead Man Switch - GUI Launcher
REM ===================================================================
REM Starts the Dead Man Switch Configuration GUI
REM ===================================================================

title Dead Man - by iamrealguexoxo

REM Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [WARNING] Not running as Administrator!
    echo Some features may require elevated privileges.
    echo.
    pause
)

REM Navigate to script directory
cd /d "%~dp0"

REM Start the GUI
echo Starting Dead Man Control Panel...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0scripts\gui-config.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to start GUI!
    pause
)
