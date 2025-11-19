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
        Write-Host "  Days without login: $(if ($config.DaysWithoutLogin) { $config.DaysWithoutLogin } else { 'N/A' })" -ForegroundColor Gray
        Write-Host "  Safe Mode: $(if ($null -ne $config.SafeMode) { $config.SafeMode } else { 'N/A' })" -ForegroundColor Gray
        Write-Host "  Items configured: $(if ($config.Items) { $config.Items.Count } else { 0 })" -ForegroundColor Gray        Write-Host ""
        
        $defaultBackupPath = Join-Path $backupFolder $backupFileName
        Write-Host "Default backup location: $defaultBackupPath" -ForegroundColor White
        $customPath = Read-Host "Press ENTER to use default, or type custom path"
        
        if ($customPath -ne "") {
            # Validate and sanitize custom path
            $customPath = $customPath.Trim().Trim('"')
            
            if ([string]::IsNullOrWhiteSpace($customPath)) {
                Write-Status "Error: Path cannot be empty or whitespace" "Red"
                pause
                exit
            }
            
            # Check for disallowed root/system folders
            $disallowedPaths = @('C:\', 'C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)', 'C:\ProgramData')
            foreach ($disallowed in $disallowedPaths) {
                $normalizedCustom = $customPath.TrimEnd('\')
                $normalizedDisallowed = $disallowed.TrimEnd('\')
                if ($normalizedCustom -eq $normalizedDisallowed -or $normalizedCustom -like "$normalizedDisallowed\*") {
                    Write-Status "Error: Cannot backup to system folder or its subdirectories: $disallowed" "Red"
                    pause
                    exit
                }
            }            
            # Disallow UNC administrative paths
            if ($customPath -match '^\\\\[^\\]+\\[Cc]\$' -or $customPath -match '^\\\\[^\\]+\\admin\$') {
                Write-Status "Error: Cannot backup to administrative UNC shares" "Red"
                pause
                exit
            }
            
            # Ensure absolute path
            if (-not [System.IO.Path]::IsPathRooted($customPath)) {
                $customPath = Join-Path $backupFolder $customPath
            }
            
            # Normalize path (remove .. segments)
            try {
                $customPath = [System.IO.Path]::GetFullPath($customPath)
            } catch {
                Write-Status "Error: Invalid path format" "Red"
                pause
                exit
            }
            
            # Ensure parent directory exists
            $parentDir = Split-Path $customPath -Parent
            if (-not (Test-Path $parentDir)) {
                $createDir = Read-Host "Directory does not exist. Create it? (Y/n)"
                if ($createDir -eq "n" -or $createDir -eq "N") {
                    Write-Status "Backup cancelled." "Yellow"
                    pause
                    exit
                }
                try {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                } catch {
                    Write-Status "Error: Could not create directory: $($_.Exception.Message)" "Red"
                    pause
                    exit
                }
            }
            
            # Check for existing file
            if (Test-Path $customPath) {
                $overwrite = Read-Host "File already exists. Overwrite? (Y/n)"
                if ($overwrite -eq "n" -or $overwrite -eq "N") {
                    Write-Status "Backup cancelled." "Yellow"
                    pause
                    exit
                }
            }
            
            $backupPath = $customPath
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
            
            if ($null -eq $backupConfig) {
                Write-Status "Error: Invalid backup file (empty or corrupt)" "Red"
                pause
                exit
            }
            
            # Validate required fields and types with flexible coercion
            $propertyNames = $backupConfig.PSObject.Properties.Name
            $validationErrors = @()
            
            # Check DaysWithoutLogin exists and is coercible to numeric
            if (-not ($propertyNames -contains 'DaysWithoutLogin')) {
                $validationErrors += "Missing required field: DaysWithoutLogin"
            } else {
                $numericValue = $null
                try {
                    $numericValue = [double]$backupConfig.DaysWithoutLogin
                    # Coerce to int for storage
                    $backupConfig.DaysWithoutLogin = [int]$numericValue
                } catch {
                    $validationErrors += "DaysWithoutLogin must be numeric (got: '$($backupConfig.DaysWithoutLogin)')"
                }
            }
            
            # Check SafeMode exists and is coercible to boolean
            if (-not ($propertyNames -contains 'SafeMode')) {
                $validationErrors += "Missing required field: SafeMode"
            } else {
                $boolValue = $null
                try {
                    # Try direct cast first
                    $boolValue = [bool]$backupConfig.SafeMode
                    $backupConfig.SafeMode = $boolValue
                } catch {
                    # Try string parsing for "true"/"false"
                    if ($backupConfig.SafeMode -is [string]) {
                        $strValue = $backupConfig.SafeMode.Trim().ToLower()
                        if ($strValue -eq "true") {
                            $backupConfig.SafeMode = $true
                        } elseif ($strValue -eq "false") {
                            $backupConfig.SafeMode = $false
                        } else {
                            $validationErrors += "SafeMode must be boolean or 'true'/'false' (got: '$($backupConfig.SafeMode)')"
                        }
                    } else {
                        $validationErrors += "SafeMode must be boolean or 'true'/'false' (got: '$($backupConfig.SafeMode)')"
                    }
                }
            }
            
            # Check Items exists and is coercible to a collection
            if (-not ($propertyNames -contains 'Items')) {
                $validationErrors += "Missing required field: Items"
            } elseif ($null -eq $backupConfig.Items) {
                $validationErrors += "Items field cannot be null"
            } else {
                # Accept arrays, IEnumerable, or single objects (convert to array)
                $isCollection = $false
                try {
                    if ($backupConfig.Items -is [Array]) {
                        $isCollection = $true
                    } elseif ($backupConfig.Items -is [System.Collections.IEnumerable] -and $backupConfig.Items -isnot [string]) {
                        $isCollection = $true
                    } else {
                        # Treat single object as a single-item collection
                        $backupConfig.Items = @($backupConfig.Items)
                        $isCollection = $true
                    }
                } catch {
                    $validationErrors += "Items must be an array, collection, or object (coercion failed)"
                }
                
                if (-not $isCollection) {
                    $validationErrors += "Items must be an array or collection"
                }
            }
            
            # If validation failed, abort
            if ($validationErrors.Count -gt 0) {
                Write-Status "Error: Invalid backup file. Missing or malformed required configuration fields." "Red"
                foreach ($error in $validationErrors) {
                    Write-Status "  - $error" "Yellow"
                }
                pause
                exit
            }
            
            # Safely extract properties with fallbacks
            $daysWithoutLogin = if ($backupConfig.PSObject.Properties['DaysWithoutLogin']) { $backupConfig.DaysWithoutLogin } else { "N/A" }
            $safeMode = if ($backupConfig.PSObject.Properties['SafeMode']) { $backupConfig.SafeMode } else { "N/A" }
            $itemCount = if ($backupConfig.PSObject.Properties['Items'] -and $null -ne $backupConfig.Items) { $backupConfig.Items.Count } else { 0 }
            
            Write-Host "Backup Configuration:" -ForegroundColor White
            Write-Host "  Days without login: $daysWithoutLogin" -ForegroundColor Gray
            Write-Host "  Safe Mode: $safeMode" -ForegroundColor Gray
            Write-Host "  Items configured: $itemCount" -ForegroundColor Gray
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
