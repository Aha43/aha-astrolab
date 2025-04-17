function Generate-Topic {
    param (
        [string]$TopicSourcePath,
        [string]$TopicName,
        [string]$OutputDir,
        [string]$Template,
        [string]$ContentDir
    )

    $topicOutputPath = Join-Path $OutputDir $TopicName
    if (-not (Test-Path $topicOutputPath)) {
        New-Item -ItemType Directory -Path $topicOutputPath | Out-Null
    }

    $pages = Get-ChildItem $TopicSourcePath -Filter *.txt | Sort-Object Name

    # If no pages, create a placeholder .txt file
    if ($pages.Count -eq 0) {
        $baseName = $TopicName -replace '^.*?_'  # Strip any prefix
        $placeholderPath = Join-Path $TopicSourcePath "001_${baseName}.txt"
        #$placeholderText = "Work in progress: $baseName"
        #Set-Content -Path $placeholderPath -Value ""
        New-Item -ItemType File -Path $placeholderPath
        Write-Host "Created placeholder: $placeholderPath"

        # Re-fetch pages after placeholder is added
        $pages = Get-ChildItem $TopicSourcePath -Filter *.txt | Sort-Object Name
    }

    for ($i = 0; $i -lt $pages.Count; $i++) {
        $file = $pages[$i]
        $raw = Get-Content $file.FullName -Raw
        $converted = Convert-TextToHtml -Text $raw -ContentDir $ContentDir

        $title = $converted.Title
        $homeLink = "<p style='text-align: right;'><a href='../index.html'>🏠 Home</a></p>"
        $body = "$homeLink`n$($converted.Content)"

        $navLinks = @()
        if ($i -gt 0) {
            $prevName = [System.IO.Path]::GetFileNameWithoutExtension($pages[$i - 1].Name) + ".html"
            $navLinks += "<a href='$prevName'>&laquo; Previous</a>"
        }
        if ($i -lt $pages.Count - 1) {
            $nextName = [System.IO.Path]::GetFileNameWithoutExtension($pages[$i + 1].Name) + ".html"
            $navLinks += "<a href='$nextName'>Next &raquo;</a>"
        }

        if ($navLinks.Count -gt 0) {
            $navHtml = $navLinks -join " | "
            $body += "`n<hr/>`n<p>$navHtml</p>"
        }

        $finalHtml = $Template -replace '\{\{title\}\}', $title
        $finalHtml = $finalHtml -replace '\{\{content\}\}', $body

        $outputFileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) + ".html"

        $outputPath = Join-Path $topicOutputPath $outputFileName
        Set-Content -Path $outputPath -Value $finalHtml -Encoding UTF8

        Write-Host "Built $TopicName/$($file.Name) -> $outputPath"
    }
}
