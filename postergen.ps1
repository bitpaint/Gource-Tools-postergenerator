# Get the first and last commit dates
$firstCommitDate = git log --reverse --format=%ci | Select-Object -First 1
$lastCommitDate = git log -1 --format=%ci

if (-not $firstCommitDate -or -not $lastCommitDate) {
    Write-Host "Error: Could not retrieve commit dates. Is this a valid Git repository?"
    exit 1
}

# Extract years
$firstYear = [int]($firstCommitDate.Substring(0, 4))
$lastYear = [int]($lastCommitDate.Substring(0, 4))

# Loop through each year
for ($year = $firstYear; $year -le $lastYear; $year++) {
    Write-Host "Generating poster for $year..."
    $startDate = "$year-01-01"
    $stopDate = "$year-12-31"
    $outputFile = "year_$year.png"

    # Check if there are commits in this year
    $commitCount = git rev-list --count --since="$startDate" --until="$stopDate" HEAD
    if ($commitCount -eq 0) {
        Write-Host "No commits found for $year. Skipping..."
        continue
    }

    # Run Gource
    gource -s 0.00001 --viewport 1920x1080 --start-date $startDate --stop-date $stopDate --stop-at-end --hide users,filenames,dirnames --disable-progress --output-ppm-stream temp.ppm

    # Check if temp.ppm exists and is non-empty
    if (Test-Path temp.ppm -and (Get-Item temp.ppm).Length -gt 0) {
        # Run FFmpeg to convert PPM to PNG
        ffmpeg -y -f image2 -i temp.ppm -frames:v 1 -update 1 $outputFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully generated $outputFile"
        } else {
            Write-Host "FFmpeg failed for $year"
        }
        # Clean up
        Remove-Item temp.ppm -ErrorAction SilentlyContinue
    } else {
        Write-Host "Warning: temp.ppm is missing or empty for $year. Skipping..."
    }
}

Write-Host "Done! Generated posters for years $firstYear to $lastYear."