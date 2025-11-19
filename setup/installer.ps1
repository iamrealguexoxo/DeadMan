<#
.SYNOPSIS
    Dead Man - One-Click Installer
    
.DESCRIPTION
    Automatically installs Dead Man to C:\DeadMan and creates desktop shortcut
    
.NOTES
    Version: 1.1
    Author: iamrealguexoxo
#>

param(
    [string]$InstallPath = "C:\DeadMan"
)

# ===================================================================
# Functions
# ===================================================================
function Write-Status {
    param([string]$msg, [string]$color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ===================================================================
# Banner
# ===================================================================
Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    💀 DEAD MAN INSTALLER v1.1 💀" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  by iamrealguexoxo" -ForegroundColor Gray
Write-Host ""

# ===================================================================
# Check if running from extracted folder
# ===================================================================
$currentDir = $PSScriptRoot
if (-not $currentDir) {
    $currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

Write-Status "Current location: $currentDir" "Gray"
Write-Host ""

# ===================================================================
# Check Admin Rights
# ===================================================================
if (-not (Test-Admin)) {
    Write-Status "This installer requires Administrator rights!" "Yellow"
    Write-Status "Restarting as Administrator..." "Yellow"
    Write-Host ""
    
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" -InstallPath `"$InstallPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

Write-Status "Running as Administrator ✓" "Green"
Write-Host ""

# ===================================================================
# Installation Path Selection
# ===================================================================
Write-Host "Default installation path: $InstallPath" -ForegroundColor White
$customPath = Read-Host "Press ENTER to use default, or type custom path"

if ($customPath -ne "") {
    $InstallPath = $customPath.Trim('"')
    if (-not [System.IO.Path]::IsPathRooted($InstallPath)) {
        Write-Status "Error: Please provide absolute path (e.g., C:\MyFolder)" "Red"
        pause
        exit
    }
}

Write-Status "Installation path: $InstallPath" "Cyan"
Write-Host ""

if ($InstallPath -ne $currentDir) {
    # Need to copy files
    if (Test-Path $InstallPath) {
        $response = Read-Host "Folder $InstallPath already exists. Overwrite? (Y/N)"
        if ($response -ne "Y" -and $response -ne "y") {
            Write-Status "Installation cancelled by user." "Yellow"
            pause
            exit
        }
        Write-Status "Removing old installation..." "Yellow"
        Remove-Item $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Status "Creating installation directory..." "Cyan"
    try {
        New-Item -ItemType Directory -Path $InstallPath -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Status "Failed to create installation directory: $($_.Exception.Message)" "Red"
        pause
        exit 1
    }    
    Write-Status "Copying files..." "Cyan"
    
    # Determine parent directory (where DeadMan.exe is)
    $parentDir = Split-Path -Parent $currentDir
    
    $filesToCopy = @(
        "DeadMan.exe",
        "DeadMan.ps1",
        "run.bat",
        "LICENSE",
        "README.md",
        "README_DE.md",
        "scripts",
        "media",
        "setup"
    )
    
    $copyErrors = @()
    foreach ($item in $filesToCopy) {
        $sourcePath = Join-Path $parentDir $item
        if (Test-Path $sourcePath) {
            try {
                Copy-Item -Path $sourcePath -Destination $InstallPath -Recurse -Force -ErrorAction Stop
                Write-Status "  $item" "Gray"
            } catch {
                $errorMsg = "Failed to copy $item : $($_.Exception.Message)"
                Write-Status "  $errorMsg" "Red"
                $copyErrors += $errorMsg
            }
        } else {
            $errorMsg = "$item not found at source location"
            Write-Status "  $errorMsg" "Yellow"
            $copyErrors += $errorMsg
        }
    }
    
    Write-Host ""
    
    # Verify critical files exist in installation directory
    $criticalFiles = @("DeadMan.exe", "DeadMan.ps1", "scripts", "setup")
    $missingFiles = @()
    
    foreach ($file in $criticalFiles) {
        $filePath = Join-Path $InstallPath $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0 -or $copyErrors.Count -gt 0) {
        Write-Status "Installation failed!" "Red"
        if ($missingFiles.Count -gt 0) {
            Write-Status "Missing critical files: $($missingFiles -join ', ')" "Red"
        }
        if ($copyErrors.Count -gt 0) {
            Write-Status "Copy errors occurred: $($copyErrors.Count) error(s)" "Red"
        }
        Write-Status "Cleaning up partial installation..." "Yellow"
        Remove-Item $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
        pause
        exit 1
    }    
    Write-Status "Files copied successfully!" "Green"
} else {
    Write-Status "Already in installation directory" "Green"
    
    # Verify critical files exist even for in-place installation
    $criticalFiles = @("DeadMan.exe", "DeadMan.ps1", "scripts", "setup")
    $missingFiles = @()
    
    foreach ($file in $criticalFiles) {
        $filePath = Join-Path $InstallPath $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Status "Installation validation failed!" "Red"
        Write-Status "Missing critical files: $($missingFiles -join ', ')" "Red"
        Write-Status "Please extract the complete package and try again." "Yellow"
        pause
        exit 1
    }
}
Write-Host ""

# ===================================================================
# Create Desktop Shortcut
# ===================================================================
Write-Status "Creating desktop shortcut..." "Cyan"

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Dead Man.lnk"
$targetPath = Join-Path $InstallPath "DeadMan.exe"

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.WorkingDirectory = $InstallPath
$shortcut.Description = "Dead Man - Automatic Data Destruction System"
$shortcut.IconLocation = $targetPath
$shortcut.Save()

Write-Status "Desktop shortcut created: Dead Man.lnk ✓" "Green"
Write-Host ""

# ===================================================================
# Install Windows Tasks
# ===================================================================
$response = Read-Host "Install Windows Scheduled Tasks now? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    Write-Host ""
    Write-Status "Installing Windows Scheduled Tasks..." "Cyan"
    Write-Host ""
    
    $setupScript = Join-Path $InstallPath "scripts\setup-tasks.ps1"
    & $setupScript
} else {
    Write-Host ""
    Write-Status "Skipped. You can install tasks later by running:" "Yellow"
    Write-Status "  - Double-click 'Dead Man' on Desktop → Select [2] Install" "Gray"
    Write-Status "  - Or run install.bat as Administrator" "Gray"
}

# ===================================================================
# Summary
# ===================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "    ✓ INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Status "Installed to: $InstallPath" "White"
Write-Status "Desktop shortcut: Dead Man.lnk" "White"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Double-click 'Dead Man' on your Desktop" -ForegroundColor White
Write-Host "  2. Select [1] GUI to configure" -ForegroundColor White
Write-Host "  3. Add items and test in Safe Mode!" -ForegroundColor White
Write-Host ""
Write-Status "⚠️  IMPORTANT: Always test in Safe Mode first!" "Yellow"
Write-Host ""

pause
