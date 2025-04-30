# Function to show stylish ASCII header
function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "        ┌─┐┌─┐┬ ┬┬─┐┌─┐┌─┐   ┌┬┐┌─┐┌─┐┬  ┌─┐" -ForegroundColor White
    Write-Host "        │ ┬│ ││ │├┬┘│  ├┤ ───│ │ ││ ││  └─┐" -ForegroundColor White
    Write-Host "        └─┘└─┘└─┘┴└─└─┘└─┘   ┴ └─┘└─┘┴─┘└─┘" -ForegroundColor White
    Write-Host "     ┌────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "     │               POSTER GENERATOR                 │" -ForegroundColor White
    Write-Host "     └────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
}

# Function to show menu
function Show-Menu {
    Write-Host "   ┌────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "   │                    MAIN MENU                       │" -ForegroundColor White
    Write-Host "   ├────────────────────────────────────────────────────┤" -ForegroundColor White
    Write-Host "   │  1) Clone a single repository                      │" -ForegroundColor White
    Write-Host "   │  2) Use an existing repository                     │" -ForegroundColor White
    Write-Host "   │  3) Clone all repos from a GitHub user/org         │" -ForegroundColor White
    Write-Host "   └────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "   [+] Enter your choice (1-3)"
    return $choice
}

# Function to create a new repository or pull if it already exists
function New-Repo {
    Write-Host "   [?] Enter the repository URL" -ForegroundColor White
    $repoUrl = Read-Host "   > "
    
    # Remove any 'https://' prefix if present
    $repoUrl = $repoUrl -replace '^https://', ''
    # Ensure the URL is correctly formatted
    if (-not $repoUrl.EndsWith(".git")) {
        $repoUrl += ".git"
    }
    # Extract repository name from URL
    $repoName = $repoUrl -replace '^.*/([^/]+)\.git$', '$1'
    
    Write-Host "   [*] Processing repository: $repoName" -ForegroundColor White
    
    # Check if the directory already exists
    if (Test-Path $repoName) {
        Write-Host "   [!] Directory '$repoName' already exists. Pulling the latest changes..." -ForegroundColor White
        Set-Location $repoName
        git pull
    } else {
        # Use the correct command to clone the repository
        Write-Host "   [+] Cloning repository..." -ForegroundColor White
        git clone "https://$repoUrl"
        # Change to the cloned repository directory
        Set-Location $repoName
    }
    
    return $repoName
}

# Function to use an existing repository
function Use-ExistingRepo {
    Write-Host "   [?] Enter the path to the existing repository" -ForegroundColor White
    $repoPath = Read-Host "   > "
    if (-Not (Test-Path $repoPath)) {
        Write-Host "   [!] Directory does not exist. Please check the path." -ForegroundColor White
        exit
    }
    Set-Location $repoPath
    return (Get-Item $repoPath).Name
}

# Function to clone all repositories for a GitHub user/organization
function Get-GitHubRepos {
    Write-Host "   [?] Enter GitHub username or organization" -ForegroundColor White
    $githubUser = Read-Host "   > "
    
    Write-Host "   [?] Is this a user or an organization? (1: User, 2: Org)" -ForegroundColor White
    $typeChoice = Read-Host "   > "
    
    $type = if ($typeChoice -eq "2") { "orgs" } else { "users" }
    
    $tempDir = "github_$githubUser"
    
    # Create a temporary directory for all repositories
    if (Test-Path $tempDir) {
        Write-Host "   [!] Directory '$tempDir' already exists. Using existing directory." -ForegroundColor White
    } else {
        Write-Host "   [+] Creating directory for repositories..." -ForegroundColor White
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    }
    
    Set-Location $tempDir
    
    Write-Host "   [*] Fetching repository list for $githubUser..." -ForegroundColor White
    
    # Use GitHub API to get list of repositories
    try {
        $page = 1
        $allRepos = @()
        
        do {
            $apiUrl = "https://api.github.com/$type/$githubUser/repos?per_page=100&page=$page"
            $repos = Invoke-RestMethod -Uri $apiUrl -Method Get
            $allRepos += $repos
            $page++
        } while ($repos.Count -eq 100)
        
        # Filter out forks
        $ownRepos = $allRepos | Where-Object { -not $_.fork }
        
        if ($ownRepos.Count -eq 0) {
            Write-Host "   [!] No repositories found for $githubUser" -ForegroundColor White
            exit
        }
        
        Write-Host "   [+] Found $($ownRepos.Count) repositories for $githubUser" -ForegroundColor White
        
        # Clone each repository
        foreach ($repo in $ownRepos) {
            $repoName = $repo.name
            Write-Host "   [*] Processing repository: $repoName" -ForegroundColor White
            
            if (Test-Path $repoName) {
                Write-Host "   [!] Directory '$repoName' already exists. Pulling the latest changes..." -ForegroundColor White
                Set-Location $repoName
                git pull
                Set-Location ..
            } else {
                Write-Host "   [+] Cloning repository $repoName..." -ForegroundColor White
                git clone $repo.clone_url
            }
        }
        
        # Create combined log file
        Write-Host "   [+] Creating combined log file..." -ForegroundColor White
        $logFile = "combined_log.txt"
        if (Test-Path $logFile) {
            Remove-Item $logFile
        }
        
        foreach ($repo in $ownRepos) {
            $repoName = $repo.name
            if (Test-Path $repoName) {
                Set-Location $repoName
                git log --pretty=format:"%at|%an|%ae|$repoName/%aD|%s" --all --date-order --name-status | foreach-object {
                    $timestamp, $rest = $_ -split '\|', 2
                    "$timestamp|$rest"
                } | Add-Content -Path "../$logFile"
                Set-Location ..
            }
        }
        
        # Sort the combined log file by timestamp
        Write-Host "   [+] Sorting combined log file..." -ForegroundColor White
        $sortedLogFile = "sorted_combined_log.txt"
        Get-Content $logFile | Sort-Object -Property { [int]($_ -split '\|', 2)[0] } | Set-Content $sortedLogFile
        
        return $githubUser
    }
    catch {
        Write-Host "   [!] Error fetching repositories: $_" -ForegroundColor White
        exit
    }
}

# Function to select resolution
function Select-Resolution {
    Write-Host "   ┌────────────────────────────────┐" -ForegroundColor White
    Write-Host "   │       SELECT RESOLUTION        │" -ForegroundColor White
    Write-Host "   ├────────────────────────────────┤" -ForegroundColor White
    Write-Host "   │  1) 320x240 (240p)             │" -ForegroundColor White
    Write-Host "   │  2) 640x360 (360p)             │" -ForegroundColor White
    Write-Host "   │  3) 1280x720 (720p)            │" -ForegroundColor White
    Write-Host "   │  4) 1920x1080 (1080p)          │" -ForegroundColor White
    Write-Host "   │  5) 2560x1440 (1440p)          │" -ForegroundColor White
    Write-Host "   │  6) 3840x2160 (4K)             │" -ForegroundColor White
    Write-Host "   │  7) 7680x4320 (8K)             │" -ForegroundColor White
    Write-Host "   │  8) 15360x8640 (16K)           │" -ForegroundColor White
    Write-Host "   └────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    $resolutionChoice = Read-Host "   [+] Enter your choice (1-8)"
    
    switch ($resolutionChoice) {
        1 { return "320x240" }
        2 { return "640x360" }
        3 { return "1280x720" }
        4 { return "1920x1080" }
        5 { return "2560x1440" }
        6 { return "3840x2160" }
        7 { return "7680x4320" }
        8 { return "15360x8640" }
        default {
            Write-Host "   [!] Invalid choice. Defaulting to 1920x1080." -ForegroundColor White
            return "1920x1080"
        }
    }
}

# Function to select orientation
function Select-Orientation {
    Write-Host "   ┌────────────────────────────────┐" -ForegroundColor White
    Write-Host "   │       SELECT ORIENTATION       │" -ForegroundColor White
    Write-Host "   ├────────────────────────────────┤" -ForegroundColor White
    Write-Host "   │  1) Landscape                  │" -ForegroundColor White
    Write-Host "   │  2) Portrait                   │" -ForegroundColor White
    Write-Host "   └────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    $orientationChoice = Read-Host "   [+] Enter your choice (1-2)"
    
    switch ($orientationChoice) {
        1 { return "landscape" }
        2 { return "portrait" }
        default {
            Write-Host "   [!] Invalid choice. Defaulting to landscape." -ForegroundColor White
            return "landscape"
        }
    }
}

# Function to determine font size based on resolution
function Get-FontSize {
    param (
        [string]$viewport
    )
    
    # Extract width from viewport string (e.g., "1920x1080" -> 1920)
    $width = [int]($viewport -replace 'x.*$', '')
    
    # Scale font size proportionally to viewport width
    switch ($width) {
        { $_ -le 320 } { return 24 }  # 240p
        { $_ -le 640 } { return 36 }  # 360p
        { $_ -le 1280 } { return 48 } # 720p
        { $_ -le 1920 } { return 64 } # 1080p
        { $_ -le 2560 } { return 86 } # 1440p
        { $_ -le 3840 } { return 128 } # 4K
        { $_ -le 7680 } { return 192 } # 8K
        default { return 256 }          # 16K and above
    }
}

# Main script
Show-Header
$choice = Show-Menu

$repoName = switch ($choice) {
    1 { New-Repo }
    2 { Use-ExistingRepo }
    3 { Get-GitHubRepos }
    default {
        Write-Host "   [!] Invalid choice. Exiting." -ForegroundColor White
        exit
    }
}

# Select resolution and orientation
Write-Host ""
Write-Host "   [*] Configuring visualization settings..." -ForegroundColor White
$viewport = Select-Resolution
$orientation = Select-Orientation

# Adjust viewport based on orientation
if ($orientation -eq "portrait") {
    $viewport = $viewport -replace '(\d+)x(\d+)', '$2x$1'  # Swap width and height for portrait
}

# Determine font size based on resolution
$fontSize = Get-FontSize -viewport $viewport

# Create export directory
$exportPath = Join-Path -Path (Split-Path -Path (Get-Location) -Parent) -ChildPath "Export/$repoName"
New-Item -ItemType Directory -Force -Path $exportPath | Out-Null

# Logic for different modes
if ($choice -eq "3") {
    # For GitHub user/org repositories, use the combined log
    Write-Host ""
    Write-Host "   [*] Preparing to generate visualizations for $repoName's repositories..." -ForegroundColor White
    
    # Get years from the combined log
    $sortedLogFile = "sorted_combined_log.txt"
    $firstLine = Get-Content $sortedLogFile -First 1
    $lastLine = Get-Content $sortedLogFile -Last 1
    
    if (!$firstLine -or !$lastLine) {
        Write-Host "   [!] Error: Combined log file is empty" -ForegroundColor White
        exit 1
    }
    
    $firstTimestamp = [int]($firstLine -split '\|', 2)[0]
    $lastTimestamp = [int]($lastLine -split '\|', 2)[0]
    
    $firstYear = (Get-Date -UnixTimeSeconds $firstTimestamp).Year
    $lastYear = (Get-Date -UnixTimeSeconds $lastTimestamp).Year
    
    Write-Host "   [+] Detected repository history from $firstYear to $lastYear" -ForegroundColor White
    
    # Loop through each year
    for ($year = $firstYear; $year -le $lastYear; $year++) {
        Write-Host "   [*] Generating poster for $year..." -ForegroundColor White
        $stopDate = Get-Date -Date "$year-12-31" -UFormat %s
        $outputFile = "$exportPath/$year.png"
        
        # Check if there are entries in this year
        $entriesInYear = Get-Content $sortedLogFile | Where-Object { 
            $timestamp = [int]($_ -split '\|', 2)[0]
            $timestamp -le $stopDate
        }
        
        if (!$entriesInYear) {
            Write-Host "   [!] No entries found for $year. Skipping..." -ForegroundColor White
            continue
        }
        
        # Run Gource with custom log file
        Write-Host "   [+] Running Gource visualization..." -ForegroundColor White
        gource $sortedLogFile -s 0.00001 --viewport $viewport --stop-at-end --hide root,users,filenames,progress,mouse --highlight-dirs --dir-name-depth 3 --dir-name-position 1 --date-format "%Y" --font-size $fontSize --font-file "C:\Windows\Fonts\arialbd.ttf" --stop-date "$year-12-31" --output-ppm-stream - | ffmpeg -y -f image2pipe -vcodec ppm -i - -update 1 $outputFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [✓] Successfully generated $outputFile" -ForegroundColor White
        } else {
            Write-Host "   [✗] Failed to generate $outputFile" -ForegroundColor White
        }
    }
} else {
    # For single repository
    Write-Host ""
    Write-Host "   [*] Preparing to generate visualizations for repository: $repoName" -ForegroundColor White
    
    # Get the first and last commit dates
    $firstCommitDate = git log --reverse --format=%ci | Select-Object -First 1
    $lastCommitDate = git log -1 --format=%ci
    
    if (-not $firstCommitDate -or -not $lastCommitDate) {
        Write-Host "   [!] Error: Could not retrieve commit dates. Is this a valid Git repository?" -ForegroundColor White
        exit 1
    }
    
    # Extract years
    $firstYear = [int]($firstCommitDate.Substring(0, 4))
    $lastYear = [int]($lastCommitDate.Substring(0, 4))
    
    Write-Host "   [+] Detected repository history from $firstYear to $lastYear" -ForegroundColor White
    
    # Loop through each year
    for ($year = $firstYear; $year -le $lastYear; $year++) {
        Write-Host "   [*] Generating poster for $year..." -ForegroundColor White
        $stopDate = Get-Date -Date "$year-12-31" -UFormat %s
        $outputFile = "$exportPath/$year.png"
        
        # Check if there are commits in this year
        $commitCount = git rev-list --count --until="$stopDate" HEAD
        if ($commitCount -eq 0) {
            Write-Host "   [!] No commits found for $year. Skipping..." -ForegroundColor White
            continue
        }
        
        # Run Gource with pipe output to capture the last frame
        Write-Host "   [+] Running Gource visualization..." -ForegroundColor White
        gource -s 0.00001 --viewport $viewport --stop-date $stopDate --stop-at-end --hide root,users,filenames,progress,mouse --highlight-dirs --dir-name-depth 3 --dir-name-position 1 --date-format "%Y" --font-size $fontSize --font-file "C:\Windows\Fonts\arialbd.ttf" --output-ppm-stream - | ffmpeg -y -f image2pipe -vcodec ppm -i - -update 1 $outputFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   [✓] Successfully generated $outputFile" -ForegroundColor White
        } else {
            Write-Host "   [✗] Failed to generate $outputFile" -ForegroundColor White
        }
    }
}

Write-Host ""
Write-Host "   ┌────────────────────────────────────────────────────────────┐" -ForegroundColor White
Write-Host "   │                        COMPLETED                           │" -ForegroundColor White
Write-Host "   ├────────────────────────────────────────────────────────────┤" -ForegroundColor White
Write-Host "   │  Generated posters for years $firstYear to $lastYear                │" -ForegroundColor White
Write-Host "   │  Output directory: $exportPath │" -ForegroundColor White
Write-Host "   └────────────────────────────────────────────────────────────┘" -ForegroundColor White