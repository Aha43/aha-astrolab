function Generate-GlobalToc {
    param (
        [System.IO.DirectoryInfo[]]$Topics,
        [string]$ContentDir,
        [string]$OutputDir,
        [string]$Template
    )

    $tocEntries = @()

    foreach ($topic in $Topics) {
        $topicName = $topic.Name
        $pages = Get-ChildItem $topic.FullName -Filter *.txt | Sort-Object Name

        if ($pages.Count -gt 0) {
            $firstFile = $pages[0]
            $firstFileName = [System.IO.Path]::GetFileNameWithoutExtension($firstFile.Name) + ".html"
            $relativeLink = "$topicName/$firstFileName"

            # Use the folder name as display title
            $displayTitle = Convert-ToDisplayName $topicName

            $tocEntries += "<li><a href='$relativeLink'>$displayTitle</a></li>"
        }
    }

    $tocHtml = "<ul>`n$tocEntries`n</ul>"
    $globalBody = "<h1>Contents</h1>`n$tocHtml"
    $globalHtml = $Template.Replace('{{title}}', "Contents").Replace('{{content}}', $globalBody)

    $globalIndexPath = Join-Path $OutputDir "index.html"
    Set-Content -Path $globalIndexPath -Value $globalHtml -Encoding UTF8

    Write-Host "Built global TOC: $globalIndexPath"
}
