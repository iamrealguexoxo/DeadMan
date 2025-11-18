# Dead Man Switch - Task Scheduler Setup
# Erstellt zwei geplante Tasks fuer das Dead Man Switch System
# WICHTIG: Muss als Administrator ausgefuehrt werden!

# Pruefen, ob als Administrator ausgefuehrt
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "FEHLER: Dieses Script muss als Administrator ausgefuehrt werden!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Bitte starten Sie PowerShell als Administrator und fuehren Sie das Script erneut aus." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

# Task 1: Update Last Login (bei jedem Login)
Write-Host ""
Write-Host "=== Task 1: DeadMan-UpdateLastLogin ===" -ForegroundColor Cyan
Write-Host ""

$taskName1 = "DeadMan-UpdateLastLogin"
$scriptPath1 = Join-Path $root "scripts\update-last-login.ps1"

# Pruefen ob Script existiert
if (-not (Test-Path $scriptPath1)) {
    Write-Host "FEHLER: Script nicht gefunden: $scriptPath1" -ForegroundColor Red
    pause
    exit 1
}

# Bestehenden Task loeschen falls vorhanden
$existingTask1 = Get-ScheduledTask -TaskName $taskName1 -ErrorAction SilentlyContinue
if ($existingTask1) {
    Write-Host "Bestehender Task wird geloescht..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName1 -Confirm:$false
}

# Task Action erstellen
$action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath1`""

# Trigger erstellen (bei Login des aktuellen Benutzers)
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$trigger1 = New-ScheduledTaskTrigger -AtLogOn -User $currentUser

# Principal erstellen (laeuft mit Benutzerrechten)
$principal1 = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited

# Settings erstellen
$settings1 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Task registrieren
try {
    Register-ScheduledTask -TaskName $taskName1 -Action $action1 -Trigger $trigger1 -Principal $principal1 -Settings $settings1 -Description "Dead Man Switch: Aktualisiert last_login.txt bei jedem Login" -Force | Out-Null
    Write-Host "Task '$taskName1' erfolgreich erstellt!" -ForegroundColor Green
}
catch {
    Write-Host "FEHLER beim Erstellen des Tasks: $_" -ForegroundColor Red
    pause
    exit 1
}

# Task 2: Self Destruct Check (bei Systemstart)
Write-Host ""
Write-Host "=== Task 2: DeadMan-SelfDestructCheck ===" -ForegroundColor Cyan
Write-Host ""

$taskName2 = "DeadMan-SelfDestructCheck"
$scriptPath2 = Join-Path $root "scripts\selfdestruct-check.ps1"

# Pruefen ob Script existiert
if (-not (Test-Path $scriptPath2)) {
    Write-Host "FEHLER: Script nicht gefunden: $scriptPath2" -ForegroundColor Red
    pause
    exit 1
}

# Bestehenden Task loeschen falls vorhanden
$existingTask2 = Get-ScheduledTask -TaskName $taskName2 -ErrorAction SilentlyContinue
if ($existingTask2) {
    Write-Host "Bestehender Task wird geloescht..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName2 -Confirm:$false
}

# Task Action erstellen
$action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath2`""

# Trigger erstellen (bei Systemstart)
$trigger2 = New-ScheduledTaskTrigger -AtStartup

# Principal erstellen (laeuft als SYSTEM mit hoechsten Rechten)
$principal2 = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Settings erstellen
$settings2 = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Task registrieren
try {
    Register-ScheduledTask -TaskName $taskName2 -Action $action2 -Trigger $trigger2 -Principal $principal2 -Settings $settings2 -Description "Dead Man Switch: Prueft bei Systemstart die Login-Schwelle und fuehrt ggf. Loeschung aus" -Force | Out-Null
    Write-Host "Task '$taskName2' erfolgreich erstellt!" -ForegroundColor Green
}
catch {
    Write-Host "FEHLER beim Erstellen des Tasks: $_" -ForegroundColor Red
    pause
    exit 1
}

# Initial last_login.txt erstellen
Write-Host ""
Write-Host "=== Initiale last_login.txt wird erstellt ===" -ForegroundColor Cyan
Write-Host ""

$lastLoginPath = Join-Path $root "config\last_login.txt"
$configDir = Split-Path -Parent $lastLoginPath

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

$timestamp = Get-Date
$timestamp.ToString("o") | Set-Content $lastLoginPath -Force
Write-Host "last_login.txt erstellt: $timestamp" -ForegroundColor Green

# Default config.json erstellen falls nicht vorhanden
Write-Host ""
Write-Host "=== Initiale config.json wird erstellt ===" -ForegroundColor Cyan
Write-Host ""

$configJsonPath = Join-Path $root "config\config.json"
if (-not (Test-Path $configJsonPath)) {
    $defaultConfig = @{
        DaysWithoutLogin = 30
        SafeMode = $true
        Executed = $false
        ExecutedAt = $null
        Items = @()
    }
    $defaultConfig | ConvertTo-Json -Depth 5 | Set-Content $configJsonPath -Force
    Write-Host "config.json erstellt mit Default-Einstellungen (30 Tage, Safe Mode aktiviert)" -ForegroundColor Green
} else {
    Write-Host "config.json existiert bereits" -ForegroundColor Yellow
}

# Zusammenfassung
Write-Host ""
Write-Host "=== Setup abgeschlossen ===" -ForegroundColor Green
Write-Host ""
Write-Host "Folgende Tasks wurden erstellt:" -ForegroundColor White
Write-Host ""
Write-Host "  1. $taskName1" -ForegroundColor Cyan
Write-Host "     Trigger: Bei Login von $currentUser" -ForegroundColor Gray
Write-Host "     Aktion:  Aktualisiert last_login.txt" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. $taskName2" -ForegroundColor Cyan
Write-Host "     Trigger: Bei Systemstart" -ForegroundColor Gray
Write-Host "     Aktion:  Prueft Dead Man Switch und fuehrt ggf. Loeschung aus" -ForegroundColor Gray
Write-Host ""
Write-Host "Sie koennen die Tasks in der Aufgabenplanung ueberpruefen:" -ForegroundColor Yellow
Write-Host "  Win+R -> taskschd.msc" -ForegroundColor Yellow
Write-Host ""

pause
