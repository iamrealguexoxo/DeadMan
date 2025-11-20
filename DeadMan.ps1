param([switch]$GUI, [switch]$Install)

# Fix for compiled EXE: Use current directory
$root = Get-Location
$root = $root.Path

if ($GUI) {
    & "$root\scripts\gui-config.ps1"
}
elseif ($Install) {
    & "$root\scripts\setup-tasks.ps1"
}
else {
    # Hauptmenü in Schleife
    do {
        Clear-Host
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "    💀 DEAD MAN v1.2 💀" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  by iamrealguexoxo" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  [1] Launch GUI" -ForegroundColor White
        Write-Host "  [2] Install Tasks (Admin required)" -ForegroundColor White
        Write-Host "  [3] Check for Updates" -ForegroundColor White
        Write-Host "  [4] Backup/Restore Config" -ForegroundColor White
        Write-Host "  [5] Create Desktop Shortcut" -ForegroundColor White
        Write-Host "  [6] Exit" -ForegroundColor White
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        $choice = Read-Host "Select option"
        
        if ($choice -eq "1") { 
            & "$root\scripts\gui-config.ps1"
            Write-Host ""
            Write-Host "Press any key to return to menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        elseif ($choice -eq "2") { 
            & "$root\scripts\setup-tasks.ps1"
            Write-Host ""
            Write-Host "Press any key to return to menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        elseif ($choice -eq "3") {
            & "$root\setup\check-updates.ps1"
            Write-Host ""
            Write-Host "Press any key to return to menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        elseif ($choice -eq "4") {
            & "$root\setup\config-backup.ps1"
            Write-Host ""
            Write-Host "Press any key to return to menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        elseif ($choice -eq "5") {
            Write-Host ""
            Write-Host "Creating desktop shortcut..." -ForegroundColor Cyan
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "Dead Man.lnk"
            $targetPath = Join-Path $root "DeadMan.exe"
            
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $targetPath
            $shortcut.WorkingDirectory = $root
            $shortcut.Description = "Dead Man - Automatic Data Destruction System"
            $shortcut.IconLocation = $targetPath
            $shortcut.Save()
            
            if (Test-Path $shortcutPath) {
                Write-Host "Desktop shortcut created successfully!" -ForegroundColor Green
            } else {
                Write-Host "Failed to create desktop shortcut!" -ForegroundColor Red
            }
            Write-Host ""
            Write-Host "Press any key to return to menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        elseif ($choice -eq "6") {
            exit
        }
        else {
            Write-Host ""
            Write-Host "Invalid option!" -ForegroundColor Red
            Write-Host "Press any key to return to menu..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    } while ($choice -ne "6")
}
