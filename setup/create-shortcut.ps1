# Create Shortcut with Custom Icon
$WshShell = New-Object -ComObject WScript.Shell
$shortcutPath = "$PWD\Dead Man Switch.lnk"
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "$PWD\start.bat"
$Shortcut.WorkingDirectory = "$PWD"

# Use DeadMan.exe as icon source (valid icon resource)
$exePath = Join-Path (Split-Path -Parent $PWD) "DeadMan.exe"
if (Test-Path $exePath) {
    $Shortcut.IconLocation = "$exePath,0"
} else {
    # Fallback to system shell32.dll icon (skull/warning icon resource ID 238)
    $Shortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,-238"
}

$Shortcut.Description = "Dead Man Switch Control Panel"

try {
    $Shortcut.Save()
} catch {
    Write-Host "ERROR: Failed to save shortcut: $_" -ForegroundColor Red
    exit 1
}
# Verify shortcut was actually created
if (Test-Path $shortcutPath) {
    Write-Host "Shortcut created successfully: Dead Man Switch.lnk" -ForegroundColor Green
    exit 0
} else {
    Write-Host "ERROR: Failed to create shortcut at: $shortcutPath" -ForegroundColor Red
    exit 1
}
