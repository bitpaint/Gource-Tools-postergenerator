# Set up script root directory for consistent path handling
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent -Path $MyInvocation.MyCommand.Path }
if (!$scriptRoot) {
    $scriptRoot = Get-Location
}

# Function to show stylish ASCII header
function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "        ┌─┐┌─┐┬ ┬┬─┐┌─┐┌─┐  ┌┬┐┌─┐┌─┐┬  ┌─┐" -ForegroundColor White
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
    
    # Create Repos directory if it doesn't exist
    $reposDir = Join-Path -Path $scriptRoot -ChildPath "repos"
    if (-not (Test-Path $reposDir)) {
        New-Item -ItemType Directory -Path $reposDir | Out-Null
        Write-Host "   [+] Created repos directory" -ForegroundColor White
    }
    
    # Create specific directory for this repository
    $repoDir = Join-Path -Path $reposDir -ChildPath $repoName
    
    # Check if the repository directory already exists
    if (Test-Path $repoDir) {
        Write-Host "   [!] Directory '$repoName' already exists. Pulling the latest changes..." -ForegroundColor White
        Set-Location $repoDir
        # Capture the output from git pull to prevent it from affecting directory names
        $gitOutput = git pull 2>&1
        # Display output to user
        Write-Host "   [+] Git Output: $gitOutput" -ForegroundColor Gray
    } else {
        # Use the correct command to clone the repository
        Write-Host "   [+] Cloning repository..." -ForegroundColor White
        $cloneDir = $reposDir
        Set-Location $cloneDir
        $gitOutput = git clone "https://$repoUrl" 2>&1
        # Display output to user
        Write-Host "   [+] Git Output: $gitOutput" -ForegroundColor Gray
        # Change to the cloned repository directory
        Set-Location $repoName
    }
    
    # Return full path to the repository
    return (Get-Location).Path
}

# Function to use an existing repository
function Use-ExistingRepo {
    # Make the repos directory path
    $reposDir = Join-Path -Path $scriptRoot -ChildPath "repos"
    
    if (-not (Test-Path $reposDir)) {
        Write-Host "   [!] No repositories found. You need to clone repositories first." -ForegroundColor White
        Write-Host "   [?] Enter the path to the existing repository" -ForegroundColor White
        $repoPath = Read-Host "   > "
        
        # Check if the path is absolute
        if (-not [System.IO.Path]::IsPathRooted($repoPath)) {
            $repoPath = Join-Path -Path (Get-Location).Path -ChildPath $repoPath
        }
    } else {
        # Get all repositories and organizations
        $repoList = @()
        $orgList = @()
        
        # First level - direct repos and organization folders
        Get-ChildItem -Path $reposDir -Directory | ForEach-Object {
            $itemPath = $_.FullName
            $itemName = $_.Name
            
            # Check if it's a git repository
            if (Test-Path (Join-Path -Path $itemPath -ChildPath ".git")) {
                $repoList += @{
                    Name = $itemName
                    Path = $itemPath
                    Type = "Repository"
                }
            } else {
                # Check if it's an organization/user folder with repositories inside
                $hasRepos = $false
                Get-ChildItem -Path $itemPath -Directory | ForEach-Object {
                    if (Test-Path (Join-Path -Path $_.FullName -ChildPath ".git")) {
                        $hasRepos = $true
                    }
                }
                
                if ($hasRepos) {
                    $orgList += @{
                        Name = $itemName
                        Path = $itemPath
                        Type = "Organization/User"
                    }
                }
            }
        }
        
        # Combine lists with indexes for display
        $displayList = @()
        $displayList += @{ Name = "Enter custom path"; Path = "custom"; Type = "Custom" }
        
        $repoList | ForEach-Object { $displayList += $_ }
        $orgList | ForEach-Object { $displayList += $_ }
        
        # Display the list
        Write-Host "   ┌────────────────────────────────────────────────────────┐" -ForegroundColor White
        Write-Host "   │              SELECT EXISTING REPOSITORY                │" -ForegroundColor White
        Write-Host "   ├────────────────────────────────────────────────────────┤" -ForegroundColor White
        
        for ($i = 0; $i -lt $displayList.Count; $i++) {
            $item = $displayList[$i]
            $padding = " " * (4 - "$i".Length)
            
            if ($item.Type -eq "Custom") {
                Write-Host "   │  $i)$padding$($item.Name)" -ForegroundColor Cyan
            } elseif ($item.Type -eq "Organization/User") {
                Write-Host "   │  $i)$padding$($item.Name) (Organization/User)" -ForegroundColor Yellow
            } else {
                Write-Host "   │  $i)$padding$($item.Name)" -ForegroundColor White
            }
        }
        
        Write-Host "   └────────────────────────────────────────────────────────┘" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "   [+] Enter your choice (0-$($displayList.Count - 1))"
        
        # Validate choice
        if ($choice -match '^\d+$' -and [int]$choice -ge 0 -and [int]$choice -lt $displayList.Count) {
            $selectedItem = $displayList[[int]$choice]
            
            if ($selectedItem.Type -eq "Custom") {
                # User chose to enter a custom path
                Write-Host "   [?] Enter the path to the existing repository" -ForegroundColor White
                $repoPath = Read-Host "   > "
                
                # Check if the path is absolute
                if (-not [System.IO.Path]::IsPathRooted($repoPath)) {
                    $repoPath = Join-Path -Path (Get-Location).Path -ChildPath $repoPath
                }
            } elseif ($selectedItem.Type -eq "Organization/User") {
                # User chose an organization - show its repositories
                $orgPath = $selectedItem.Path
                $orgRepos = @()
                
                Get-ChildItem -Path $orgPath -Directory | ForEach-Object {
                    if (Test-Path (Join-Path -Path $_.FullName -ChildPath ".git")) {
                        $orgRepos += @{
                            Name = $_.Name
                            Path = $_.FullName
                        }
                    }
                }
                
                # Display repositories in the organization
                Write-Host "   ┌────────────────────────────────────────────────────────┐" -ForegroundColor White
                Write-Host "   │      SELECT REPOSITORY FROM $($selectedItem.Name)" -ForegroundColor White
                Write-Host "   ├────────────────────────────────────────────────────────┤" -ForegroundColor White
                
                # Add Combined Logs option as the first choice
                Write-Host "   │  0)   Combined Logs (all repositories)" -ForegroundColor Cyan
                
                for ($i = 0; $i -lt $orgRepos.Count; $i++) {
                    $repo = $orgRepos[$i]
                    $padding = " " * (4 - "$($i+1)".Length)
                    Write-Host "   │  $($i+1))$padding$($repo.Name)" -ForegroundColor White
                }
                
                Write-Host "   └────────────────────────────────────────────────────────┘" -ForegroundColor White
                Write-Host ""
                
                $repoChoice = Read-Host "   [+] Enter your choice (0-$($orgRepos.Count))"
                
                # Validate repository choice
                if ($repoChoice -match '^\d+$' -and [int]$repoChoice -ge 0 -and [int]$repoChoice -le $orgRepos.Count) {
                    if ([int]$repoChoice -eq 0) {
                        # Combined logs option selected
                        Write-Host ""
                        Write-Host "   ┌─────────────────────────────────────────────────┐" -ForegroundColor White
                        Write-Host "   │             COMBINING REPOSITORY LOGS           │" -ForegroundColor White
                        Write-Host "   └─────────────────────────────────────────────────┘" -ForegroundColor White
                        
                        # Create a properly named directory for combined logs
                        $combinedName = "$($selectedItem.Name)-combined"
                        $combinedDir = Join-Path -Path $reposDir -ChildPath $combinedName
                        if (-not (Test-Path $combinedDir)) {
                            New-Item -ItemType Directory -Path $combinedDir -Force | Out-Null
                        } else {
                            # Clean up any existing files
                            Remove-Item -Path (Join-Path -Path $combinedDir -ChildPath "*") -Force
                        }
                        
                        # Path for the combined Gource log
                        $combinedLogFile = Join-Path -Path $combinedDir -ChildPath "gource_combined_log.txt"
                        
                        # Process each repository and generate Gource logs
                        $allTimestamps = @()
                        
                        foreach ($repo in $orgRepos) {
                            $repoName = $repo.Name
                            $repoPath = $repo.Path
                            
                            Write-Host "   [+] Processing repository: $repoName" -ForegroundColor White
                            
                            # Enter the repository
                            Set-Location $repoPath
                            
                            # Create Gource log entries
                            git log --all --date-order --format=format:"%at|%an" --name-status | ForEach-Object {
                                if ($_ -match '^(\d+)\|(.+)$') {
                                    # This is a timestamp line
                                    $timestamp = $matches[1]
                                    $author = $matches[2]
                                    $currentTimestamp = $timestamp
                                    $currentAuthor = $author
                                    
                                    # Add to all timestamps for year range calculation
                                    $allTimestamps += [int]$timestamp
                                } elseif ($_ -match '^([MADRCT])\t(.+)$') {
                                    # This is a file change line
                                    $changeType = $matches[1]
                                    $file = $matches[2]
                                    
                                    # Convert git change type to Gource change type
                                    $gourceType = switch($changeType) {
                                        "A" { "A" } # Added
                                        "M" { "M" } # Modified
                                        "D" { "D" } # Deleted
                                        "R" { "M" } # Renamed (treat as modified)
                                        "C" { "A" } # Copied (treat as added)
                                        "T" { "M" } # Type changed (treat as modified)
                                        default { "M" }
                                    }
                                    
                                    # Format for Gource: timestamp|author|action|file
                                    "$currentTimestamp|$currentAuthor|$gourceType|$repoName/$file"
                                }
                            } | Where-Object { $_ -match '^\d+\|.+\|[AMD]\|.+$' } | Add-Content -Path $combinedLogFile
                        }
                        
                        # Sort the combined log file by timestamp
                        Write-Host "   [+] Sorting combined log file..." -ForegroundColor White
                        $sortedLogFile = Join-Path -Path $combinedDir -ChildPath "sorted_gource_log.txt"
                        
                        Get-Content $combinedLogFile | Sort-Object -Property { 
                            try {
                                [int]($_ -split '\|', 2)[0]
                            } catch {
                                [int]::MaxValue # Put invalid entries at the end
                            }
                        } | Get-Unique | Set-Content $sortedLogFile
                        
                        # Create a proper git environment to avoid confusion with other parts of the script
                        # Just make a basic git structure so the directory is recognized as a git repo
                        $gitDir = Join-Path -Path $combinedDir -ChildPath ".git"
                        if (-not (Test-Path $gitDir)) {
                            New-Item -ItemType Directory -Path $gitDir -Force | Out-Null
                            # Create minimal Git structure
                            Set-Content -Path (Join-Path -Path $gitDir -ChildPath "HEAD") -Value "ref: refs/heads/main"
                            New-Item -ItemType Directory -Path (Join-Path -Path $gitDir -ChildPath "refs/heads") -Force | Out-Null
                            # Create config file
                            $configContent = @"
[core]
        repositoryformatversion = 0
        filemode = false
        bare = false
[remote "origin"]
        url = https://github.com/$($selectedItem.Name)/$combinedName
"@
                            Set-Content -Path (Join-Path -Path $gitDir -ChildPath "config") -Value $configContent
                        }
                        
                        # Calculate the date range based on detected timestamps
                        if ($allTimestamps.Count -gt 0) {
                            $firstTimestamp = ($allTimestamps | Sort-Object)[0]
                            $lastTimestamp = ($allTimestamps | Sort-Object)[-1]
                            
                            Write-Host "   [+] DEBUG: Earliest timestamp: $firstTimestamp" -ForegroundColor Yellow
                            Write-Host "   [+] DEBUG: Latest timestamp: $lastTimestamp" -ForegroundColor Yellow
                            
                            # Convert timestamps to dates for reference
                            try {
                                $firstDate = (Get-Date 01.01.1970).AddSeconds($firstTimestamp)
                                $lastDate = (Get-Date 01.01.1970).AddSeconds($lastTimestamp)
                                
                                Write-Host "   [+] DEBUG: First date: $($firstDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
                                Write-Host "   [+] DEBUG: Last date: $($lastDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
                                
                                # Store dates in files for reference by other parts of the script
                                Set-Content -Path (Join-Path -Path $combinedDir -ChildPath "first_commit_date") -Value $firstDate.ToString("yyyy-MM-dd HH:mm:ss")
                                Set-Content -Path (Join-Path -Path $combinedDir -ChildPath "last_commit_date") -Value $lastDate.ToString("yyyy-MM-dd HH:mm:ss")
                                
                                # Also store first and last year explicitly
                                Set-Content -Path (Join-Path -Path $combinedDir -ChildPath "first_year") -Value $firstDate.Year
                                Set-Content -Path (Join-Path -Path $combinedDir -ChildPath "last_year") -Value $lastDate.Year
                                
                                Write-Host "   [+] DEBUG: Date range: $($firstDate.Year) to $($lastDate.Year)" -ForegroundColor Yellow
                                
                                # Set global variables that will be used later
                                $script:detectedFirstYear = $firstDate.Year
                                $script:detectedLastYear = $lastDate.Year
                                
                                # Create a temporary file in the script root to ensure years are preserved
                                $yearDataFile = Join-Path -Path $scriptRoot -ChildPath "temp_year_data.txt"
                                "$($firstDate.Year)|$($lastDate.Year)" | Set-Content -Path $yearDataFile
                            } catch {
                                Write-Host "   [!] ERROR parsing dates: $_" -ForegroundColor Red
                            }
                        } else {
                            Write-Host "   [!] ERROR: No timestamps found in repositories" -ForegroundColor Red
                        }
                        
                        Write-Host "   [✓] Successfully created combined log file" -ForegroundColor White
                        
                        # Return to combined logs directory
                        Set-Location $combinedDir
                        $repoPath = $combinedDir
                        
                        # Return the repository name as the combined name
                        $repoName = $combinedName
                    } else {
                        # User selected a specific repository
                        $repoPath = $orgRepos[[int]$repoChoice - 1].Path
                    }
                } else {
                    Write-Host "   [!] Invalid choice. Exiting." -ForegroundColor White
                    exit
                }
            } else {
                # User chose a direct repository
                $repoPath = $selectedItem.Path
            }
        } else {
            Write-Host "   [!] Invalid choice. Exiting." -ForegroundColor White
            exit
        }
    }
    
    if (-Not (Test-Path $repoPath)) {
        Write-Host "   [!] Directory does not exist. Please check the path." -ForegroundColor White
        exit
    }
    
    # Check if it's a git repository (skip for combined logs)
    if (-Not $isCombinedLogs -and -Not (Test-Path (Join-Path -Path $repoPath -ChildPath ".git"))) {
        Write-Host "   [!] The selected directory is not a Git repository." -ForegroundColor White
        exit
    }
    
    Set-Location $repoPath
    Write-Host "   [+] Using repository at: $repoPath" -ForegroundColor White
    
    # Return full path to the repository
    return (Get-Location).Path
}

# Function to clone all repositories for a GitHub user/organization
function Get-GitHubRepos {
    Write-Host "   [?] Enter GitHub username or organization" -ForegroundColor White
    $githubUser = Read-Host "   > "
    
    Write-Host "   [?] Is this a user or an organization? (1: User, 2: Org)" -ForegroundColor White
    $typeChoice = Read-Host "   > "
    
    $type = if ($typeChoice -eq "2") { "orgs" } else { "users" }
    
    # Create Repos directory if it doesn't exist
    $reposDir = Join-Path -Path $scriptRoot -ChildPath "repos"
    if (-not (Test-Path $reposDir)) {
        New-Item -ItemType Directory -Path $reposDir | Out-Null
        Write-Host "   [+] Created repos directory" -ForegroundColor White
    }
    
    # Create user/org specific directory
    $userDir = Join-Path -Path $reposDir -ChildPath $githubUser
    if (-not (Test-Path $userDir)) {
        New-Item -ItemType Directory -Path $userDir | Out-Null
        Write-Host "   [+] Created directory for $githubUser" -ForegroundColor White
    }
    
    # Change to the user directory
    Set-Location $userDir
    
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
        
        # Create Gource-compatible log file
        $gourceLogFile = "gource_combined_log.txt"
        if (Test-Path $gourceLogFile) {
            Remove-Item $gourceLogFile
        }
        
        # Clone each repository
        foreach ($repo in $ownRepos) {
            $repoName = $repo.name
            Write-Host "   [*] Processing repository: $repoName" -ForegroundColor White
            
            if (Test-Path $repoName) {
                Write-Host "   [!] Directory '$repoName' already exists. Pulling the latest changes..." -ForegroundColor White
                Set-Location $repoName
                # Capture git output to prevent it from affecting directory names
                $gitOutput = git pull 2>&1
                Write-Host "   [+] Git Output: $gitOutput" -ForegroundColor Gray
                Set-Location ..
            } else {
                Write-Host "   [+] Cloning repository $repoName..." -ForegroundColor White
                # Capture git output
                $gitOutput = git clone $repo.clone_url 2>&1
                Write-Host "   [+] Git Output: $gitOutput" -ForegroundColor Gray
            }
            
            # Process repository for Gource log if it was successfully cloned
            if (Test-Path $repoName) {
                Set-Location $repoName
                
                # Create Gource-compatible log format
                # Format: UNIX_TIMESTAMP|AUTHOR|TYPE|FILE
                Write-Host "   [+] Generating Gource log for $repoName..." -ForegroundColor White
                
                # Run git log with raw format to get file changes
                git log --all --date-order --format=format:"%at|%an" --name-status | ForEach-Object {
                    if ($_ -match '^(\d+)\|(.+)$') {
                        # This is a timestamp line
                        $timestamp = $matches[1]
                        $author = $matches[2]
                        $currentTimestamp = $timestamp
                        $currentAuthor = $author
                    } elseif ($_ -match '^([MADRCT])\t(.+)$') {
                        # This is a file change line
                        $changeType = $matches[1]
                        $file = $matches[2]
                        
                        # Convert git change type to Gource change type (A=add, M=modify, D=delete)
                        $gourceType = switch($changeType) {
                            "A" { "A" } # Added
                            "M" { "M" } # Modified
                            "D" { "D" } # Deleted
                            "R" { "M" } # Renamed (treat as modified)
                            "C" { "A" } # Copied (treat as added)
                            "T" { "M" } # Type changed (treat as modified)
                            default { "M" }
                        }
                        
                        # Format for Gource: timestamp|author|action|file
                        # Prepend repository name to file path for multi-repo visualization
                        "$currentTimestamp|$currentAuthor|$gourceType|$repoName/$file"
                    }
                } | Where-Object { $_ -match '^\d+\|.+\|[AMD]\|.+$' } | Add-Content -Path "../$gourceLogFile"
                
                Set-Location ..
            } else {
                Write-Host "   [!] Failed to process repository: $repoName" -ForegroundColor White
            }
        }
        
        # Sort the Gource log
        Write-Host "   [+] Sorting Gource log file..." -ForegroundColor White
        $sortedGourceLogFile = "sorted_gource_log.txt"
        
        if (Test-Path $gourceLogFile) {
            Get-Content $gourceLogFile | Sort-Object -Property { 
                try {
                    [int]($_ -split '\|', 2)[0]
                } catch {
                    [int]::MaxValue # Put invalid entries at the end
                }
            } | Set-Content $sortedGourceLogFile
            
            Write-Host "   [+] Created Gource-compatible log file: $sortedGourceLogFile" -ForegroundColor White
        } else {
            Write-Host "   [!] Error: No log file was created" -ForegroundColor White
            exit 1
        }
        
        # Return the user/org name and the full path to the directory
        return @{
            "Name" = $githubUser
            "Path" = (Get-Location).Path
        }
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
    Write-Host "   │  7) 5120x2880 (5K)             │" -ForegroundColor White
    Write-Host "   │  8) 6144x3456 (6K)             │" -ForegroundColor White
    Write-Host "   │  9) 7680x4320 (8K)             │" -ForegroundColor White
    Write-Host "   │ 10) 15360x8640 (16K)           │" -ForegroundColor White
    Write-Host "   └────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    $resolutionChoice = Read-Host "   [+] Enter your choice (1-10)"
    
    switch ($resolutionChoice) {
        1 { return "320x240" }
        2 { return "640x360" }
        3 { return "1280x720" }
        4 { return "1920x1080" }
        5 { return "2560x1440" }
        6 { return "3840x2160" }
        7 { return "5120x2880" }
        8 { return "6144x3456" }
        9 { return "7680x4320" }
        10 { return "15360x8640" }
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
    # Reduced by approximately 15% from original values
    switch ($width) {
        { $_ -le 320 } { return 20 }  # 240p (was 24)
        { $_ -le 640 } { return 30 }  # 360p (was 36)
        { $_ -le 1280 } { return 40 } # 720p (was 48)
        { $_ -le 1920 } { return 54 } # 1080p (was 64)
        { $_ -le 2560 } { return 73 } # 1440p (was 86)
        { $_ -le 3840 } { return 108 } # 4K (was 128)
        { $_ -le 7680 } { return 162 } # 8K (was 192)
        default { return 218 }          # 16K and above (was 256)
    }
}

# Main script
Show-Header
$choice = Show-Menu

$repoInfo = switch ($choice) {
    1 { 
        $repoPath = New-Repo
        $repoName = Split-Path -Leaf $repoPath
        @{
            "Name" = $repoName
            "Path" = $repoPath
        }
    }
    2 { 
        $repoPath = Use-ExistingRepo
        $repoName = Split-Path -Leaf $repoPath
        @{
            "Name" = $repoName
            "Path" = $repoPath
        }
    }
    3 { Get-GitHubRepos }
    default {
        Write-Host "   [!] Invalid choice. Exiting." -ForegroundColor White
        exit
    }
}

# Extract repo name and path
$repoName = $repoInfo.Name
$repoPath = $repoInfo.Path

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

# Create posters directory if it doesn't exist
$postersDir = Join-Path -Path $scriptRoot -ChildPath "posters"
if (-not (Test-Path $postersDir)) {
    New-Item -ItemType Directory -Force -Path $postersDir | Out-Null
    Write-Host "   [+] Created posters directory" -ForegroundColor White
}

# Create repository-specific directory for the output files
$repoExportPath = Join-Path -Path $postersDir -ChildPath $repoName
New-Item -ItemType Directory -Force -Path $repoExportPath | Out-Null

# Define standard Gource command arguments for consistency
$gourceArgs = @(
    "-s 0.00001",
    "--viewport $viewport",
    "--stop-at-end",
    "--hide root,filenames,progress,mouse,users",
    "--highlight-dirs",
    "--dir-name-depth 2",
    "--dir-name-position 1",
    "--padding 1.25",
    "--date-format '%Y'",
    "--font-size $fontSize",
    "--font-file 'C:\Windows\Fonts\arialbd.ttf'"
)

# Logic for different modes
if ($choice -eq "3" -or $repoName -like "*-combined") {
    # For GitHub user/org repositories or combined repositories, use the combined log
    Write-Host ""
    Write-Host "   [*] Preparing to generate visualizations for $repoName's repositories..." -ForegroundColor White
    
    # Direct fix: If this is a combined repository, force the correct year range
    if ($repoName -like "*-combined") {
        Write-Host "   [*] DIRECT FIX: Detected combined repository: $repoName" -ForegroundColor Magenta
        
        # Force a full scan of the log file to get accurate years
        $sortedGourceLogFile = Join-Path -Path $repoPath -ChildPath "sorted_gource_log.txt"
        if (Test-Path $sortedGourceLogFile) {
            $allTimestamps = @()
            Get-Content $sortedGourceLogFile | ForEach-Object {
                if ($_ -match '^(\d+)\|') {
                    $allTimestamps += [int]$matches[1]
                }
            }
            
            if ($allTimestamps.Count -gt 0) {
                $firstTimestamp = ($allTimestamps | Sort-Object)[0]
                $lastTimestamp = ($allTimestamps | Sort-Object)[-1]
                
                # Use the most reliable method for date conversion
                $firstDate = (Get-Date 01.01.1970).AddSeconds($firstTimestamp)
                $lastDate = (Get-Date 01.01.1970).AddSeconds($lastTimestamp)
                
                $firstYear = $firstDate.Year
                $lastYear = $lastDate.Year
                
                Write-Host "   [*] DIRECT FIX: Found years $firstYear to $lastYear directly from log" -ForegroundColor Magenta
            } else {
                # Absolute fallback
                $firstYear = 2020
                $lastYear = (Get-Date).Year
                Write-Host "   [*] DIRECT FIX: Fallback to hardcoded years $firstYear to $lastYear" -ForegroundColor Red
            }
        } else {
            # Absolute fallback
            $firstYear = 2020
            $lastYear = (Get-Date).Year
            Write-Host "   [*] DIRECT FIX: Log file not found, using years $firstYear to $lastYear" -ForegroundColor Red
        }
    }
    # Otherwise continue with the normal flow for GitHub repositories
    else {
        # Check for the temporary year data file first - most reliable
        $yearDataFile = Join-Path -Path $scriptRoot -ChildPath "temp_year_data.txt"
        if (Test-Path $yearDataFile) {
            $yearData = Get-Content $yearDataFile -ErrorAction SilentlyContinue
            if ($yearData -match '(\d{4})\|(\d{4})') {
                $firstYear = [int]$matches[1]
                $lastYear = [int]$matches[2]
                Write-Host "   [*] FIXED: Using years from temp data: $firstYear to $lastYear" -ForegroundColor Green
                # Delete the temporary file so it doesn't affect future runs
                Remove-Item $yearDataFile -Force -ErrorAction SilentlyContinue
            }
        }
        # If we already have the years from the script variables, use those
        elseif ($script:detectedFirstYear -and $script:detectedLastYear) {
            $firstYear = $script:detectedFirstYear
            $lastYear = $script:detectedLastYear
            Write-Host "   [*] FIXED: Using years from script variables: $firstYear to $lastYear" -ForegroundColor Green
        }
        # Otherwise continue with the normal detection process
        else {
            # Get years from the combined log
            $sortedGourceLogFile = Join-Path -Path $repoPath -ChildPath "sorted_gource_log.txt"
            
            # Check if the file exists and has content
            if (-not (Test-Path $sortedGourceLogFile) -or (Get-Item $sortedGourceLogFile).Length -eq 0) {
                Write-Host "   [!] Error: Sorted Gource log file is empty or not found" -ForegroundColor White
                exit 1
            }
            
            # EMERGENCY FIX: Direct attempt to extract years from the log file
            $allTimestamps = @()
            Get-Content $sortedGourceLogFile | ForEach-Object {
                if ($_ -match '^(\d+)\|') {
                    $allTimestamps += [int]$matches[1]
                }
            }
            
            if ($allTimestamps.Count -gt 0) {
                $firstTimestamp = ($allTimestamps | Sort-Object)[0]
                $lastTimestamp = ($allTimestamps | Sort-Object)[-1]
                
                Write-Host "   [*] EMERGENCY FIX: First timestamp = $firstTimestamp, Last timestamp = $lastTimestamp" -ForegroundColor Magenta
                
                # Use the most reliable method for date conversion
                $firstDate = (Get-Date 01.01.1970).AddSeconds($firstTimestamp)
                $lastDate = (Get-Date 01.01.1970).AddSeconds($lastTimestamp)
                
                $firstYear = $firstDate.Year
                $lastYear = $lastDate.Year
                
                Write-Host "   [*] EMERGENCY FIX: Determined years: $firstYear to $lastYear" -ForegroundColor Magenta
            }
            else {
                # Check if this is a combined logs repository (has a first_year file)
                $firstYearFile = Join-Path -Path $repoPath -ChildPath "first_year"
                $lastYearFile = Join-Path -Path $repoPath -ChildPath "last_year"
                
                if (Test-Path $firstYearFile -and Test-Path $lastYearFile) {
                    # Use the explicitly stored years - most reliable method
                    $firstYear = [int](Get-Content $firstYearFile)
                    $lastYear = [int](Get-Content $lastYearFile)
                    Write-Host "   [*] Using years from stored files: $firstYear to $lastYear" -ForegroundColor Cyan
                } elseif (Test-Path $firstCommitDateFile -and Test-Path $lastCommitDateFile) {
                    # Use the pre-calculated dates from the combined logs generation
                    $firstCommitDate = Get-Content $firstCommitDateFile
                    $lastCommitDate = Get-Content $lastCommitDateFile
                    
                    Write-Host "   [*] DEBUG: First commit date from file: $firstCommitDate" -ForegroundColor Yellow
                    Write-Host "   [*] DEBUG: Last commit date from file: $lastCommitDate" -ForegroundColor Yellow
                    
                    # Extract years from the date strings
                    try {
                        $firstYear = [datetime]::ParseExact($firstCommitDate, "yyyy-MM-dd HH:mm:ss", $null).Year
                        $lastYear = [datetime]::ParseExact($lastCommitDate, "yyyy-MM-dd HH:mm:ss", $null).Year
                        Write-Host "   [*] DEBUG: Parsed years: $firstYear to $lastYear" -ForegroundColor Yellow
                    } catch {
                        Write-Host "   [!] ERROR parsing date strings: $_" -ForegroundColor Red
                        # Fallback to current range
                        $firstYear = (Get-Date).Year - 5
                        $lastYear = (Get-Date).Year
                    }
                } else {
                    # Fall back to extracting timestamp from the first and last lines of the log
                    $firstLine = Get-Content $sortedGourceLogFile -First 1
                    $lastLine = Get-Content $sortedGourceLogFile -Last 1
                    
                    Write-Host "   [*] DEBUG: First log line: $firstLine" -ForegroundColor Yellow
                    Write-Host "   [*] DEBUG: Last log line: $lastLine" -ForegroundColor Yellow
                    
                    if (!$firstLine -or !$lastLine) {
                        Write-Host "   [!] Error: Sorted Gource log file is empty" -ForegroundColor White
                        exit 1
                    }
                    
                    # Safely parse timestamps
                    try {
                        $firstParts = $firstLine -split '\|'
                        $lastParts = $lastLine -split '\|'
                        
                        if ($firstParts.Count -ge 1 -and $lastParts.Count -ge 1) {
                            $firstTimestamp = [int]$firstParts[0]
                            $lastTimestamp = [int]$lastParts[0]
                            
                            Write-Host "   [*] DEBUG: First timestamp: $firstTimestamp" -ForegroundColor Yellow
                            Write-Host "   [*] DEBUG: Last timestamp: $lastTimestamp" -ForegroundColor Yellow
                            
                            # Try multiple methods to convert Unix timestamps to DateTime
                            try {
                                # Method 1: DateTimeOffset
                                $firstDateTime = [DateTimeOffset]::FromUnixTimeSeconds($firstTimestamp).DateTime
                                $lastDateTime = [DateTimeOffset]::FromUnixTimeSeconds($lastTimestamp).DateTime
                            } catch {
                                # Method 2: Add seconds to Unix epoch
                                $firstDateTime = (Get-Date 01.01.1970).AddSeconds($firstTimestamp)
                                $lastDateTime = (Get-Date 01.01.1970).AddSeconds($lastTimestamp)
                            }
                            
                            Write-Host "   [*] DEBUG: First date: $firstDateTime" -ForegroundColor Yellow
                            Write-Host "   [*] DEBUG: Last date: $lastDateTime" -ForegroundColor Yellow
                            
                            $firstYear = $firstDateTime.Year
                            $lastYear = $lastDateTime.Year
                            
                            Write-Host "   [*] DEBUG: Final year range: $firstYear to $lastYear" -ForegroundColor Yellow
                        } else {
                            throw "Invalid log format"
                        }
                    } catch {
                        Write-Host "   [!] Error parsing timestamps from log file: $_" -ForegroundColor White
                        Write-Host "   [!] Using current date range instead." -ForegroundColor White
                        $firstYear = (Get-Date).Year - 5 # Go back 5 years as a fallback
                        $lastYear = (Get-Date).Year
                    }
                }
            }
        }
    }
    
    # SANITY CHECK - If years detection is still wrong, force correct values
    if ($firstYear -eq $lastYear -and $firstYear -eq (Get-Date).Year) {
        Write-Host "   [!] CRITICAL ERROR: Years still detected incorrectly, forcing correction..." -ForegroundColor Red
        
        # Attempt one more time to read the first year file
        $firstYearFile = Join-Path -Path $repoPath -ChildPath "first_year" 
        if (Test-Path $firstYearFile) {
            $firstYear = [int](Get-Content $firstYearFile)
            Write-Host "   [+] Corrected first year to: $firstYear" -ForegroundColor Green
        } else {
            $firstYear = 2020  # Hard fallback if everything else fails
            Write-Host "   [+] Forcing first year to: $firstYear" -ForegroundColor Red
        }
        
        $lastYear = (Get-Date).Year
        Write-Host "   [+] Forcing last year to: $lastYear" -ForegroundColor Red
    }
    
    Write-Host "   [+] Detected repository history from $firstYear to $lastYear" -ForegroundColor White
    
    # Loop through each year
    for ($year = $firstYear; $year -le $lastYear; $year++) {
        Write-Host "   [*] Generating poster for $year..." -ForegroundColor White
        $stopDate = Get-Date -Date "$year-12-31" -UFormat %s
        $outputFile = Join-Path -Path $repoExportPath -ChildPath "$year.png"
        
        # Direct fix for combined logs - don't check entries
        $skipEntryCheck = $repoName -like "*-combined"
        
        # Check if there are entries in this year
        $hasEntries = $true
        if (-not $skipEntryCheck) {
            $entriesInYear = Get-Content $sortedGourceLogFile | Where-Object { 
                try {
                    $timestamp = [int]($_ -split '\|', 2)[0]
                    $timestamp -le $stopDate
                } catch {
                    # Skip invalid entries
                    $false
                }
            }
            
            if (!$entriesInYear) {
                Write-Host "   [!] No entries found for $year. Skipping..." -ForegroundColor White
                $hasEntries = $false
            }
        }
        
        if ($hasEntries) {
            # Run Gource with custom log file
            Write-Host "   [+] Running Gource visualization..." -ForegroundColor White
            try {
                # Build the Gource command with arguments and add the year-specific stop date
                $gourceYearArgs = $gourceArgs + @("--stop-date '$year-12-31'", "--output-ppm-stream -")
                $gourceCmd = "gource $sortedGourceLogFile $($gourceYearArgs -join ' ') | ffmpeg -y -f image2pipe -vcodec ppm -i - -update 1 $outputFile"
                
                # Execute the Gource command
                $gourceOutput = Invoke-Expression $gourceCmd 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   [✓] Successfully generated $outputFile" -ForegroundColor White
                } else {
                    Write-Host "   [✗] Failed to generate $outputFile (Exit code: $LASTEXITCODE)" -ForegroundColor White
                    Write-Host "   [!] Gource Output: $gourceOutput" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "   [✗] Error running Gource: $_" -ForegroundColor White
            }
        }
    }
} else {
    # For single repository
    Set-Location $repoPath
    
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
        $outputFile = Join-Path -Path $repoExportPath -ChildPath "$year.png"
        
        # Check if there are commits in this year
        $commitCount = git rev-list --count --until="$stopDate" HEAD
        if ($commitCount -eq 0) {
            Write-Host "   [!] No commits found for $year. Skipping..." -ForegroundColor White
            continue
        }
        
        # Run Gource with pipe output to capture the last frame
        Write-Host "   [+] Running Gource visualization..." -ForegroundColor White
        try {
            # Build the Gource command with arguments and add the year-specific stop date
            $gourceYearArgs = $gourceArgs + @("--stop-date '$year-12-31'", "--output-ppm-stream -")
            $gourceCmd = "gource $($gourceYearArgs -join ' ') | ffmpeg -y -f image2pipe -vcodec ppm -i - -update 1 $outputFile"
            
            # Execute the Gource command
            $gourceOutput = Invoke-Expression $gourceCmd 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   [✓] Successfully generated $outputFile" -ForegroundColor White
            } else {
                Write-Host "   [✗] Failed to generate $outputFile (Exit code: $LASTEXITCODE)" -ForegroundColor White
                Write-Host "   [!] Gource Output: $gourceOutput" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "   [✗] Error running Gource: $_" -ForegroundColor White
        }
    }
}

# Return to script root
Set-Location $scriptRoot

Write-Host ""
Write-Host "   ┌────────────────────────────────────────────────────────────┐" -ForegroundColor White
Write-Host "   │                        COMPLETED                           │" -ForegroundColor White
Write-Host "   ├────────────────────────────────────────────────────────────┤" -ForegroundColor White
Write-Host "   │  Generated posters for years $firstYear to $lastYear                │" -ForegroundColor White
Write-Host "   │  Repository: $repoPath     │" -ForegroundColor White
Write-Host "   │  Output directory: $repoExportPath │" -ForegroundColor White
Write-Host "   └────────────────────────────────────────────────────────────┘" -ForegroundColor White

# Cleanup combined repository folder and temporary data if used
if ($repoName -like '*-combined') {
    $combinedFolder = Join-Path -Path $scriptRoot -ChildPath "repos\$repoName"
    if (Test-Path $combinedFolder) {
        Remove-Item -Path $combinedFolder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "   [+] Cleaned up combined repository folder: $combinedFolder" -ForegroundColor White
    }
    $tempYearFile = Join-Path -Path $scriptRoot -ChildPath 'temp_year_data.txt'
    if (Test-Path $tempYearFile) { Remove-Item -Path $tempYearFile -Force -ErrorAction SilentlyContinue }
}