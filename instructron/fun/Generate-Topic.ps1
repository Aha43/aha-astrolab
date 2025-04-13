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
    if ($pages.Count -eq 0) {
        Write-Host "No pages found in $TopicName"
        return
    }

    for ($i = 0; $i -lt $pages.Count; $i++) {
        $file = $pages[$i]
        $raw = Get-Content $file.FullName -Raw
        $converted = Convert-TextToHtml $raw

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
