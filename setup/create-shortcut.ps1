# Create Shortcut with Custom Icon
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$PWD\Dead Man Switch.lnk")
$Shortcut.TargetPath = "$PWD\start.bat"
$Shortcut.WorkingDirectory = "$PWD"
$Shortcut.IconLocation = "$PWD\bart.gif,0"  # Oder eigenes .ico erstellen
$Shortcut.Description = "Dead Man Switch Control Panel"
$Shortcut.Save()

Write-Host "Shortcut created: Dead Man Switch.lnk" -ForegroundColor Green
