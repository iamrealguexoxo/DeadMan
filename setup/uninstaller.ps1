# Dead Man - Uninstaller
# Version: 1.1
# Author: iamrealguexoxo

# Functions
function Write-Status {
    param([string]$msg, [string]$color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Banner
Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Red
Write-Host "    DEAD MAN UNINSTALLER" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "  by iamrealguexoxo" -ForegroundColor Gray
Write-Host ""

# Check Admin Rights
if (-not (Test-Admin)) {
    Write-Status "This uninstaller requires Administrator rights!" "Yellow"
    Write-Status "Restarting as Administrator..." "Yellow"
    Write-Host ""
    
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

Write-Status "Running as Administrator" "Green"
Write-Host ""

# Confirmation
Write-Host "WARNING: This will remove Dead Man from your system!" -ForegroundColor Yellow
Write-Host ""
Write-Host "The following will be removed:" -ForegroundColor White
Write-Host "  - Windows Scheduled Tasks" -ForegroundColor Gray
Write-Host "  - Desktop shortcut" -ForegroundColor Gray
Write-Host "  - Configuration files (optional)" -ForegroundColor Gray
Write-Host ""

$confirm = (Read-Host "Are you sure you want to continue? (YES/no)").Trim().ToUpperInvariant()
if ($confirm -ne "YES") {
    Write-Status "Uninstallation cancelled." "Yellow"
    pause
    exit
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Uninstallation..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Remove Windows Scheduled Tasks
Write-Status "Removing Windows Scheduled Tasks..." "Cyan"

$tasks = @(
    "DeadMan-UpdateLastLogin",
    "DeadMan-SelfDestructCheck"
)

foreach ($taskName in $tasks) {
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Status "  Removed: $taskName" "Green"
        } else {
            Write-Status "  Not found: $taskName" "Gray"
        }
    } catch {
        Write-Status "  Error removing: $taskName" "Red"
    }
}

Write-Host ""

# Remove Desktop Shortcut
Write-Status "Removing desktop shortcut..." "Cyan"

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Dead Man.lnk"

if (Test-Path $shortcutPath) {
    Remove-Item $shortcutPath -Force
    Write-Status "Desktop shortcut removed" "Green"
} else {
    Write-Status "Desktop shortcut not found" "Gray"
}

Write-Host ""

# Remove Installation Folder (Optional)
# Attempt to resolve installation path safely
$installPath = $null

# Try $PSScriptRoot first (when running as script)
if ($PSScriptRoot -and $PSScriptRoot -ne "") {
    $installPath = Split-Path -Parent $PSScriptRoot
}

# Try $MyInvocation.MyCommand.Path as fallback
if (-not $installPath -or $installPath -eq "") {
    if ($MyInvocation.MyCommand.Path) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        if ($scriptPath) {
            $installPath = Split-Path -Parent $scriptPath
        }
    }
}

# Validate the resolved path exists and looks like a DeadMan installation
$isValidInstallPath = $false
if ($installPath -and (Test-Path $installPath)) {
    # Check for expected DeadMan files/folders
    $deadManExe = Join-Path $installPath "DeadMan.exe"
    $scriptsFolder = Join-Path $installPath "scripts"
    
    if ((Test-Path $deadManExe) -or (Test-Path $scriptsFolder)) {
        $isValidInstallPath = $true
    }
}

# If we cannot safely resolve the path, abort
if (-not $isValidInstallPath) {
    Write-Host ""
    Write-Status "ERROR: Cannot safely determine installation path" "Red"
    Write-Host ""
    Write-Host "The uninstaller could not locate the Dead Man installation folder." -ForegroundColor Yellow
    Write-Host "Please manually delete the installation folder if needed." -ForegroundColor Yellow
    Write-Host ""
    if ($installPath) {
        Write-Host "Attempted path: $installPath (validation failed)" -ForegroundColor Gray
    } else {
        Write-Host "Could not determine installation path" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Status "Tasks and shortcuts have been removed. Installation folder remains intact." "Yellow"
    pause
    exit 0
}
Write-Host "Installation folder: $installPath" -ForegroundColor White
Write-Host ""
Write-Host "WARNING: Do you want to DELETE the entire installation folder?" -ForegroundColor Yellow
Write-Host "         This will remove ALL configuration and log files!" -ForegroundColor Yellow
Write-Host ""

# Additional confirmation showing exact path
$confirmPath = Read-Host "Type the folder name to confirm (e.g., 'DeadMan')"
$expectedFolderName = Split-Path $installPath -Leaf

if (-not $confirmPath.Trim().Equals($expectedFolderName, [StringComparison]::OrdinalIgnoreCase)) {
    Write-Status "Folder name does not match. Installation folder kept for safety." "Yellow"
    Write-Status "You can manually delete it later if needed." "Gray"
    pause
    exit 0
}

Write-Host ""
Write-Status "Removing installation folder..." "Cyan"

try {
    Remove-Item $installPath -Recurse -Force
    Write-Status "Installation folder deleted" "Green"
} catch {
    Write-Status "Error: Cannot delete folder while script is running from it" "Red"
    Write-Status "Please manually delete: $installPath" "Yellow"
    Write-Status "Original error: $($_.Exception.Message)" "Gray"
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  UNINSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Status "Dead Man has been removed from your system." "White"
Write-Host ""

pause
