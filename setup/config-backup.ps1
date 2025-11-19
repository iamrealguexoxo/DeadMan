# Dead Man - Config Backup & Restore
# Export and import configuration settings

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("backup", "restore")]
    [string]$Action = ""
)

$configPath = Join-Path (Split-Path -Parent $PSScriptRoot) "config\config.json"
$backupFolder = [Environment]::GetFolderPath("MyDocuments")
$backupFileName = "DeadMan-Backup-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"

function Write-Status {
    param([string]$msg, [string]$color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

# Banner
Clear-Host
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DEAD MAN - CONFIG BACKUP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Action selection if not provided
if ($Action -eq "") {
    Write-Host "Select action:" -ForegroundColor White
    Write-Host "  [1] Backup - Export current configuration" -ForegroundColor Gray
    Write-Host "  [2] Restore - Import configuration from backup" -ForegroundColor Gray
    Write-Host ""
    
    $choice = Read-Host "Enter choice (1 or 2)"
    
    switch ($choice) {
        "1" { $Action = "backup" }
        "2" { $Action = "restore" }
        default {
            Write-Status "Invalid choice. Exiting." "Red"
            pause
            exit
        }
    }
    Write-Host ""
}

# BACKUP
if ($Action -eq "backup") {
    Write-Status "Starting backup..." "Cyan"
    Write-Host ""
    
    if (-not (Test-Path $configPath)) {
        Write-Status "Error: Configuration file not found at: $configPath" "Red"
        Write-Status "Please run the application first to create a configuration." "Yellow"
        pause
        exit
    }
    
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        
        Write-Host "Current Configuration:" -ForegroundColor White
        Write-Host "  Days without login: $($config.DaysWithoutLogin)" -ForegroundColor Gray
        Write-Host "  Safe Mode: $($config.SafeMode)" -ForegroundColor Gray
        Write-Host "  Items configured: $($config.Items.Count)" -ForegroundColor Gray
        Write-Host ""
        
        $defaultBackupPath = Join-Path $backupFolder $backupFileName
        Write-Host "Default backup location: $defaultBackupPath" -ForegroundColor White
        $customPath = Read-Host "Press ENTER to use default, or type custom path"
        
        if ($customPath -ne "") {
            $backupPath = $customPath.Trim('"')
        } else {
            $backupPath = $defaultBackupPath
        }
        
        Copy-Item $configPath $backupPath -Force
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  BACKUP SUCCESSFUL" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Status "Backup saved to: $backupPath" "Green"
        Write-Host ""
        
        $openFolder = Read-Host "Open backup folder? (Y/n)"
        if ($openFolder -ne "n" -and $openFolder -ne "N") {
            Start-Process (Split-Path $backupPath -Parent)
        }
        
    } catch {
        Write-Status "Backup failed: $($_.Exception.Message)" "Red"
        pause
        exit
    }
}

# RESTORE
if ($Action -eq "restore") {
    Write-Status "Starting restore..." "Cyan"
    Write-Host ""
    
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = $backupFolder
    $openFileDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*"
    $openFileDialog.Title = "Select backup file to restore"
    
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $backupPath = $openFileDialog.FileName
        
        Write-Status "Selected backup: $backupPath" "White"
        Write-Host ""
        
        try {
            $backupConfig = Get-Content $backupPath -Raw | ConvertFrom-Json
            
            Write-Host "Backup Configuration:" -ForegroundColor White
            Write-Host "  Days without login: $($backupConfig.DaysWithoutLogin)" -ForegroundColor Gray
            Write-Host "  Safe Mode: $($backupConfig.SafeMode)" -ForegroundColor Gray
            Write-Host "  Items configured: $($backupConfig.Items.Count)" -ForegroundColor Gray
            Write-Host ""
            
            Write-Host "WARNING: This will overwrite your current configuration!" -ForegroundColor Yellow
            $confirm = Read-Host "Continue with restore? (YES/no)"
            
            if ($confirm -ne "YES") {
                Write-Status "Restore cancelled." "Yellow"
                pause
                exit
            }
            
            Write-Host ""
            Write-Status "Restoring configuration..." "Cyan"
            
            # Create config directory if it doesn't exist
            $configDir = Split-Path $configPath -Parent
            if (-not (Test-Path $configDir)) {
                New-Item -ItemType Directory -Path $configDir -Force | Out-Null
            }
            
            Copy-Item $backupPath $configPath -Force
            
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "  RESTORE SUCCESSFUL" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Status "Configuration restored from backup." "Green"
            Write-Status "Please restart Dead Man to apply changes." "Yellow"
            Write-Host ""
            
        } catch {
            Write-Status "Restore failed: $($_.Exception.Message)" "Red"
            pause
            exit
        }
        
    } else {
        Write-Status "No file selected. Restore cancelled." "Yellow"
    }
}

Write-Host ""
pause
