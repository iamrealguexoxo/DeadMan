# Dead Man - Update Checker
# Compares local version with latest GitHub release

param(
    [switch]$Silent
)

$repoOwner = "iamrealguexoxo"
$repoName = "DeadMan"
$localVersion = "1.1.0.0"

function Write-Status {
    param([string]$msg, [string]$color = "White")
    if (-not $Silent) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
    }
}

function Compare-Versions {
    param([string]$v1, [string]$v2)
    
    $ver1 = [version]$v1
    $ver2 = [version]$v2
    
    return $ver1.CompareTo($ver2)
}

if (-not $Silent) {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  DEAD MAN - UPDATE CHECKER" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

Write-Status "Local version: v$localVersion" "White"
Write-Status "Checking GitHub for updates..." "Cyan"

try {
    $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/releases/latest"
    $response = Invoke-RestMethod -Uri $apiUrl -Method Get -ErrorAction Stop
    
    $latestVersion = $response.tag_name -replace 'v', ''
    $downloadUrl = $response.assets[0].browser_download_url
    $releaseDate = [DateTime]::Parse($response.published_at).ToString("yyyy-MM-dd")
    
    Write-Status "Latest version: v$latestVersion (released $releaseDate)" "White"
    Write-Host ""
    
    $comparison = Compare-Versions $localVersion $latestVersion
    
    if ($comparison -lt 0) {
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  UPDATE AVAILABLE!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Current: v$localVersion" -ForegroundColor Yellow
        Write-Host "  Latest:  v$latestVersion" -ForegroundColor Green
        Write-Host ""
        Write-Host "Download: $($response.html_url)" -ForegroundColor Cyan
        Write-Host ""
        
        if (-not $Silent) {
            $open = Read-Host "Open release page in browser? (Y/n)"
            if ($open -ne "n" -and $open -ne "N") {
                Start-Process $response.html_url
            }
        }
        
        exit 1
    } elseif ($comparison -eq 0) {
        Write-Host "You are running the latest version." -ForegroundColor Green
        exit 0
    } else {
        Write-Host "You are running a newer version than released." -ForegroundColor Yellow
        exit 0
    }
    
} catch {
    Write-Status "Failed to check for updates." "Red"
    Write-Status "Error: $($_.Exception.Message)" "Red"
    Write-Host ""
    Write-Status "Please check manually: https://github.com/$repoOwner/$repoName/releases" "Yellow"
    exit 2
}

if (-not $Silent) {
    Write-Host ""
    pause
}
