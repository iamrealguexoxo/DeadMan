# Dead Man - Update Checker
# Compares local version with latest GitHub release

param(
    [switch]$Silent
)

$repoOwner = "iamrealguexoxo"
$repoName = "DeadMan"
$localVersion = "1.1"

function Write-Status {
    param([string]$msg, [string]$color = "White")
    if (-not $Silent) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
    }
}

function Compare-Versions {
    param([string]$v1, [string]$v2)
    
    $ver1 = $null
    $ver2 = $null
    
    # Try to parse first version
    try {
        $ver1 = [version]$v1
    } catch {
        Write-Status "Warning: Malformed version string: $v1" "Yellow"
    }
    
    # Try to parse second version
    try {
        $ver2 = [version]$v2
    } catch {
        Write-Status "Warning: Malformed version string: $v2" "Yellow"
    }
    
    # Handle comparison with null versions
    if ($null -eq $ver1 -and $null -eq $ver2) {
        return 0  # Both malformed, treat as equal
    } elseif ($null -eq $ver1) {
        return -1  # Local version malformed, treat as older
    } elseif ($null -eq $ver2) {
        # Remote version malformed - log error and return -1 to prompt for updates
        Write-Host "ERROR: Failed to parse remote version string: '$v2'" -ForegroundColor Red
        Write-Host "       Unable to determine if updates are available." -ForegroundColor Yellow
        return -1  # Treat as comparison failure, err on side of checking for updates
    }
    
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
    
    if ($null -eq $response.tag_name -or [string]::IsNullOrWhiteSpace($response.tag_name)) {
        throw "GitHub API response missing tag_name"
    }
    $latestVersion = $response.tag_name -replace 'v', ''    
    # Validate assets array exists and has elements
    if ($null -eq $response.assets -or $response.assets.Count -eq 0) {
        # Fallback message if no assets available
        Write-Status "Note: No release assets found, using source tarball" "Yellow"
    }
    
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
        
        # Validate html_url exists before using it
        if ($null -ne $response -and -not [string]::IsNullOrWhiteSpace($response.html_url)) {
            Write-Host "Download: $($response.html_url)" -ForegroundColor Cyan
        } else {
            Write-Host "Download: URL not available" -ForegroundColor Yellow
        }
        Write-Host ""
        
        if (-not $Silent) {
            if ($null -ne $response -and -not [string]::IsNullOrWhiteSpace($response.html_url)) {
                $open = Read-Host "Open release page in browser? (Y/n)"
                if ($open -ne "n" -and $open -ne "N") {
                    Start-Process $response.html_url
                }
            }
        }
        
        if (-not $Silent) {
            Write-Host ""
            pause
        }
        exit 1
    } elseif ($comparison -eq 0) {
        Write-Host "You are running the latest version." -ForegroundColor Green
        if (-not $Silent) {
            Write-Host ""
            pause
        }
        exit 0
    } else {
        Write-Host "You are running a newer version than released." -ForegroundColor Yellow
        if (-not $Silent) {
            Write-Host ""
            pause
        }
        exit 0
    }
    
} catch {
    Write-Status "Failed to check for updates." "Red"
    Write-Status "Error: $($_.Exception.Message)" "Red"
    Write-Host ""
    Write-Status "Please check manually: https://github.com/$repoOwner/$repoName/releases" "Yellow"
    if (-not $Silent) {
        Write-Host ""
        pause
    }
    exit 2
}
