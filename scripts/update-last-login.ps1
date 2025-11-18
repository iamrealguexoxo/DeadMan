# ===================================================================
# Dead Man Switch - Update Last Login
# ===================================================================
# Zweck: Wird bei jedem erfolgreichen Login automatisch ausgeführt
#        und aktualisiert last_login.txt mit aktuellem Datum/Zeit
# ===================================================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

# Sicherstellen, dass der config-Ordner existiert
$configDir = Join-Path $root "config"
if (-not (Test-Path $configDir)) {
    try {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        Write-Host "config-Ordner wurde erstellt: $configDir"
    }
    catch {
        Write-Error "Fehler beim Erstellen des config-Ordners: $_"
        exit 1
    }
}

# Aktuelles Datum/Zeit in last_login.txt schreiben
$lastLoginPath = Join-Path $configDir "last_login.txt"

try {
    $timestamp = Get-Date
    $timestamp.ToString("o") | Set-Content $lastLoginPath -Force
    Write-Host "Last login wurde aktualisiert: $timestamp"
}
catch {
    Write-Error "Fehler beim Aktualisieren von last_login.txt: $_"
    exit 1
}

exit 0
