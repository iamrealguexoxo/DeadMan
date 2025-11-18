@echo off
REM ===================================================================
REM Dead Man Switch - Installation Script
REM ===================================================================
REM Installs and configures the Dead Man Switch system
REM ===================================================================

title Dead Man - Installation by iamrealguexoxo

REM Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo ===================================================================
echo Dead Man Switch - Installation
echo ===================================================================
echo.

REM Navigate to script directory
cd /d "%~dp0"

REM Run the setup script
echo Running setup tasks...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0scripts\setup-tasks.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ===================================================================
    echo Installation completed successfully!
    echo ===================================================================
    echo.
    echo You can now run start.bat to configure the system.
    echo.
) else (
    echo.
    echo [ERROR] Installation failed!
    echo.
)

pause
