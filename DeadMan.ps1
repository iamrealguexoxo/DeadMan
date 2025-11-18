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
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    💀 DEAD MAN v1.1 💀" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  by iamrealguexoxo" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [1] Launch GUI" -ForegroundColor White
    Write-Host "  [2] Install Tasks (Admin required)" -ForegroundColor White
    Write-Host "  [3] Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    if ($choice -eq "1") { 
        & "$root\scripts\gui-config.ps1" 
    }
    elseif ($choice -eq "2") { 
        & "$root\scripts\setup-tasks.ps1" 
    }
    elseif ($choice -eq "3") {
        exit
    }
    else {
        Write-Host ""
        Write-Host "Invalid option!" -ForegroundColor Red
        pause
    }
}
