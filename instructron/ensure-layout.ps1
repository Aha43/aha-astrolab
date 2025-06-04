# ensure-layout.ps1
# Sync the topics folder structure to match layout.txt exactly
# Deletes/creates/renames files and folders — only runs on clean git state

# Safety: require clean git state
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Error "Git state is not clean. Commit or stash changes before running ensure-layout.ps1."
    exit 1
}

$LayoutFile = "layout.txt"
$TopicsDir = "topics"

if (-not (Test-Path $LayoutFile)) {
    Write-Error "Missing layout.txt"
    exit 1
}

# Step 1: Parse layout.txt into [topic] -> [files] map
$layoutLines = Get-Content $LayoutFile
$layoutMap = @{}
$currentTopic = $null

foreach ($line in $layoutLines) {
    $trimmed = $line.TrimEnd()
    if ($trimmed -match '^\s*$') { continue }

    if ($line -match '^\S') {
        $currentTopic = $trimmed
        $layoutMap[$currentTopic] = @()
    }
    elseif ($currentTopic -ne $null) {
        $layoutMap[$currentTopic] += $trimmed.Trim()
    }
}

# Step 2: Remove topics not in layout
$existingTopics = Get-ChildItem $TopicsDir -Directory
foreach ($existing in $existingTopics) {
    $cleanName = $existing.Name -replace '^.*?_'
    if (-not $layoutMap.ContainsKey($cleanName)) {
        Write-Host "Removing topic folder not in layout: $existing.Name"
        Remove-Item $existing.FullName -Recurse -Force
    }
}

# Step 3: Recreate/match all layout topics and files
$topicIndex = 1
foreach ($topic in $layoutMap.Keys) {
    $topicPrefix = "{0:D3}" -f $topicIndex
    $topicFolderName = "${topicPrefix}_$topic"
    $topicPath = Join-Path $TopicsDir $topicFolderName

    # Rename folder if needed
    $existing = Get-ChildItem $TopicsDir -Directory | Where-Object {
        ($_ -replace '^.*?_', '') -eq $topic
    }
    if ($existing.Count -gt 0 -and $existing.Name -ne $topicFolderName) {
        Rename-Item -Path $existing.FullName -NewName $topicFolderName
    }

    if (-not (Test-Path $topicPath)) {
        Write-Host "Creating topic folder: $topicPath"
        New-Item -ItemType Directory -Path $topicPath | Out-Null
    }

    $desiredFiles = $layoutMap[$topic]

    if ($desiredFiles.Count -eq 0) {
        # No files listed for this topic, create default intro file
        $filePrefix = "001"
        $fileName = "${filePrefix}_${topic}.txt"
        $filePath = Join-Path $topicPath $fileName

        if (-not (Test-Path $filePath)) {
            Write-Host "Creating default intro file: $filePath"
            Set-Content -Path $filePath -Value @"
Work in progress

This page has not been written yet.
"@ -Encoding UTF8
        }
    }
    else {
        # Remove .txt files not listed in layout
        $existingFiles = Get-ChildItem $topicPath -Filter *.txt
        foreach ($file in $existingFiles) {
            $clean = ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) -replace '^.*?_')
            if ($clean -notin $desiredFiles) {
                Write-Host "Removing file not in layout: $file.Name"
                Remove-Item $file.FullName
            }
        }

        # Create/rewrite files with correct prefix
        for ($i = 0; $i -lt $desiredFiles.Count; $i++) {
            $fileName = $desiredFiles[$i]
            $filePrefix = "{0:D3}" -f ($i + 1)
            $finalName = "${filePrefix}_$fileName.txt"
            $filePath = Join-Path $topicPath $finalName

            if (-not (Test-Path $filePath)) {
                Write-Host "Creating placeholder: $filePath"
                Set-Content -Path $filePath -Value @"
Work in progress

This page has not been written yet.
"@ -Encoding UTF8
            }
            else {
                # Rename if wrong prefix
                $matching = Get-ChildItem $topicPath -Filter "*_$fileName.txt"
                foreach ($m in $matching) {
                    if ($m.Name -ne $finalName) {
                        if (Test-Path $filePath) {
                            Remove-Item $filePath -Force
                        }
                        Rename-Item -Path $m.FullName -NewName $finalName
                    }
                }
            }
        }
    }

    $topicIndex++
}

Write-Host "✅ ensure-layout.ps1 complete — structure matches layout.txt"
