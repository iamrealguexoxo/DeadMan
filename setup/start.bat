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

REM Check if GUI script exists
if not exist "%~dp0..\scripts\gui-config.ps1" (
    echo.
    echo [ERROR] GUI script not found!
    echo Expected location: %~dp0..\scripts\gui-config.ps1
    echo.
    pause
    exit /b 1
)

REM Start the GUI
echo Starting Dead Man Control Panel...
powershell.exe -ExecutionPolicy RemoteSigned -File "%~dp0..\scripts\gui-config.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to start GUI!
    pause
)
