# ===================================================================
# Dead Man Switch - Self Destruct Check
# ===================================================================
# Zweck: Wird beim Systemstart ausgeführt und prüft, ob die 
#        Login-Schwelle überschritten wurde. Führt dann je nach
#        Modus die Löschung aus oder simuliert sie.
# ===================================================================

param(
    [switch]$ForceSafeMode
)

# Basis-Pfade
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$configPath = Join-Path $root "config\config.json"
$lastLogin = Join-Path $root "config\last_login.txt"
$logPath = Join-Path $root "logs\log.txt"

# ===================================================================
# Logging-Funktion
# ===================================================================
function Write-Log {
    param([string]$msg)
    
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
    
    try {
        $logDir = Split-Path -Parent $logPath
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $logPath -Value $line -Force
        Write-Host $line
    }
    catch {
        Write-Host "FEHLER beim Logging: $_"
    }
}

# ===================================================================
# Start
# ===================================================================
Write-Log "=== Dead Man Switch Check gestartet ==="

# Prüfen, ob config.json existiert
if (-not (Test-Path $configPath)) {
    Write-Log "WARNUNG: config.json nicht gefunden unter $configPath"
    Write-Log "Bitte zuerst die GUI oeffnen und Konfiguration speichern, oder Installation erneut ausfuehren."
    Write-Log "Dead Man Switch Check wird beendet."
    exit 0
}

# Config laden
try {
    $configJson = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Log "Config erfolgreich geladen"
}
catch {
    Write-Log "FEHLER beim Laden der Config: $_"
    exit 1
}

# Prüfen, ob bereits ausgelöst (nur wenn nicht ForceSafeMode)
if ($configJson.Executed -eq $true -and -not $ForceSafeMode) {
    Write-Log "Dead Man Switch wurde bereits ausgelöst am: $($configJson.ExecutedAt)"
    Write-Log "Keine weitere Aktion erforderlich."
    exit 0
}

# Prüfen, ob last_login.txt existiert
if (-not (Test-Path $lastLogin)) {
    Write-Log "WARNUNG: last_login.txt nicht gefunden. Keine Prüfung möglich."
    exit 0
}

# Letztes Login-Datum laden
try {
    $lastLoginDate = Get-Content $lastLogin | Get-Date
    Write-Log "Letztes Login: $lastLoginDate"
}
catch {
    Write-Log "FEHLER beim Lesen von last_login.txt: $_"
    exit 1
}

# Differenz berechnen
$diff = (Get-Date) - $lastLoginDate
$daysSinceLogin = [int]$diff.TotalDays
Write-Log "Tage seit letztem Login: $daysSinceLogin"
Write-Log "Schwellenwert: $($configJson.DaysWithoutLogin) Tage"

# Prüfen, ob Schwelle erreicht
if ($daysSinceLogin -lt $configJson.DaysWithoutLogin) {
    Write-Log "Schwelle noch nicht erreicht. Keine Aktion erforderlich."
    exit 0
}

# Schwelle überschritten!
Write-Log "!!! SCHWELLE ÜBERSCHRITTEN !!!"

# Effective SafeMode bestimmen
$effectiveSafeMode = $configJson.SafeMode -or $ForceSafeMode

if ($effectiveSafeMode) {
    Write-Log "=== SIMULATION MODE AKTIV - Keine Dateien werden gelöscht ==="
}
else {
    Write-Log "=== LIVE MODE - Dateien werden WIRKLICH gelöscht ==="
}

# Items durchgehen und löschen (oder simulieren)
$deletedCount = 0
$errorCount = 0

foreach ($item in $configJson.Items) {
    $itemType = $item.Type
    $itemPath = $item.Path
    
    Write-Log "---"
    Write-Log "Verarbeite Item: Type=$itemType, Path=$itemPath"
    
    # Prüfen, ob Pfad existiert (nur bei Plain Items)
    if ($itemPath -and -not (Test-Path $itemPath)) {
        Write-Log "WARNUNG: Pfad existiert nicht: $itemPath"
        continue
    }
    
    # Je nach Typ unterschiedliche Behandlung
    try {
        switch ($itemType) {
            "PlainFolder" {
                if ($effectiveSafeMode) {
                    Write-Log "[SIMULATION] Würde Ordner löschen: $itemPath"
                }
                else {
                    Remove-Item -Path $itemPath -Recurse -Force -ErrorAction Stop
                    Write-Log "[GELÖSCHT] Ordner: $itemPath"
                    $deletedCount++
                }
            }
            
            "PlainFile" {
                if ($effectiveSafeMode) {
                    Write-Log "[SIMULATION] Würde Datei löschen: $itemPath"
                }
                else {
                    Remove-Item -Path $itemPath -Force -ErrorAction Stop
                    Write-Log "[GELÖSCHT] Datei: $itemPath"
                    $deletedCount++
                }
            }
            
            "VeraCryptContainer" {
                if ($effectiveSafeMode) {
                    Write-Log "[SIMULATION] Würde VeraCrypt-Container löschen: $itemPath"
                }
                else {
                    Remove-Item -Path $itemPath -Force -ErrorAction Stop
                    Write-Log "[GELÖSCHT] VeraCrypt-Container: $itemPath"
                    $deletedCount++
                }
            }
            
            "VeraCryptKeyfile" {
                if ($effectiveSafeMode) {
                    Write-Log "[SIMULATION] Würde VeraCrypt-Keyfile löschen: $itemPath"
                }
                else {
                    Remove-Item -Path $itemPath -Force -ErrorAction Stop
                    Write-Log "[GELÖSCHT] VeraCrypt-Keyfile: $itemPath"
                    $deletedCount++
                }
            }
            
            "BitLockerVolume" {
                $drive = $item.Drive
                if ($effectiveSafeMode) {
                    Write-Log "[SIMULATION] Würde BitLocker-Recovery-Keys für $drive löschen"
                }
                else {
                    # BitLocker Recovery Keys löschen
                    $recoveryKeys = (Get-BitLockerVolume -MountPoint $drive).KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
                    foreach ($key in $recoveryKeys) {
                        Remove-BitLockerKeyProtector -MountPoint $drive -KeyProtectorId $key.KeyProtectorId
                        Write-Log "[GELÖSCHT] BitLocker Recovery Key: $($key.KeyProtectorId)"
                        $deletedCount++
                    }
                }
            }
            
            "BitLockerRecoveryFile" {
                if ($effectiveSafeMode) {
                    Write-Log "[SIMULATION] Würde BitLocker-Recovery-Datei löschen: $itemPath"
                }
                else {
                    Remove-Item -Path $itemPath -Force -ErrorAction Stop
                    Write-Log "[GELÖSCHT] BitLocker-Recovery-Datei: $itemPath"
                    $deletedCount++
                }
            }
            
            default {
                Write-Log "WARNUNG: Unbekannter Typ: $itemType"
            }
        }
    }
    catch {
        Write-Log "FEHLER beim Löschen von $itemPath : $_"
        $errorCount++
    }
}

Write-Log "---"
Write-Log "Verarbeitung abgeschlossen."

if ($effectiveSafeMode) {
    Write-Log "Simulation: $($configJson.Items.Count) Items wurden simuliert"
}
else {
    Write-Log "Live-Modus: $deletedCount Items gelöscht, $errorCount Fehler"
    
    # Gelöschte Items aus Config entfernen
    $remainingItems = @()
    foreach ($item in $configJson.Items) {
        $itemPath = $item.Path
        $exists = $false
        
        if ($item.Type -eq "PlainFile") {
            $exists = Test-Path $itemPath -PathType Leaf
        }
        elseif ($item.Type -eq "PlainFolder") {
            $exists = Test-Path $itemPath -PathType Container
        }
        else {
            # Andere Typen (VeraCrypt, BitLocker) behalten
            $exists = $true
        }
        
        if ($exists) {
            $remainingItems += $item
        }
        else {
            Write-Log "Item aus Config entfernt (nicht mehr vorhanden): $itemPath"
        }
    }
    
    # Status in Config aktualisieren
    $configJson.Items = $remainingItems
    $configJson.Executed = $true
    $configJson.ExecutedAt = (Get-Date).ToString("o")
    
    try {
        $configJson | ConvertTo-Json -Depth 5 | Set-Content $configPath -Force
        Write-Log "Config aktualisiert: Executed=true, ExecutedAt=$($configJson.ExecutedAt)"
        Write-Log "Verbleibende Items in Config: $($remainingItems.Count)"
    }
    catch {
        Write-Log "FEHLER beim Speichern der Config: $_"
    }
}

Write-Log "=== Dead Man Switch Check beendet ==="
exit 0
