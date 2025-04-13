. $PSScriptRoot/fun/Convert-ToDisplayName.ps1
. $PSScriptRoot/fun/Link.ps1
. $PSScriptRoot/fun/Generate-Topic.ps1

$ContentDir = "content"
$TemplatePath = "templates/layout.html"
$OutputDir = "docs"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$layout = Get-Content $TemplatePath -Raw

function Split-IntoBlocks {
    param (
        [string]$text
    )

    # Normalize line endings: CRLF, CR, or LF → LF
    $normalized = $text -replace "`r`n?", "`n"

    $lines = $normalized -split "`n"
    $blocks = @()
    $currentBlock = @()

    foreach ($line in $lines) {
        if ($line.Trim() -eq "") {
            if ($currentBlock.Count -gt 0) {
                $blocks += ($currentBlock -join " ")
                $currentBlock = @()
            }
        }
        else {
            $currentBlock += $line.Trim()
        }
    }

    if ($currentBlock.Count -gt 0) {
        $blocks += ($currentBlock -join " ")
    }

    return $blocks
}

function Convert-TextToHtml {
    param ($text)

    Write-Host("Converting text to HTML...")

    $blocks = Split-IntoBlocks $text

    if ($blocks.Count -eq 0) {
        Write-Host("No blocks found in text.")
        return
    }
    $title = $blocks[0]
    $paragraphs = $blocks[1..($blocks.Count - 1)]

    $htmlBlocks = @()
    foreach ($para in $paragraphs) {
        if ($para -like "_link_*") {
            $htmlBlocks += Convert-LinkLineToHtml -line $para -contentDir $ContentDir
        }
        elseif ($para -like "_img_*") {
            $htmlBlocks += Convert-ImageLineToHtml -line $para
        }        
        elseif ($para -like "_video_*") {
            $htmlBlocks += Convert-VideoLineToHtml -line $para
        }        
        else {
            $htmlBlocks += "<p>$para</p>"
        }
    }

    return @{ Title = $title; Content = ($htmlBlocks -join "`n") }
}

# Ensure output subfolders exist
$OutputImageDir = Join-Path $OutputDir "images"
$OutputVideoDir = Join-Path $OutputDir "videos"

if (Test-Path $OutputImageDir) { Remove-Item $OutputImageDir -Recurse -Force }
if (Test-Path $OutputVideoDir) { Remove-Item $OutputVideoDir -Recurse -Force }

Copy-Item "images" $OutputDir -Recurse
Copy-Item "videos" $OutputDir -Recurse


# Build list of all topics and their files (sorted)
$topics = Get-ChildItem $ContentDir -Directory | Sort-Object Name
if ($topics.Count -eq 0) {
    Write-Host "No topics found in $ContentDir"
    exit
}

foreach ($topic in $topics) {
    Generate-Topic -TopicSourcePath $topic.FullName `
                   -TopicName $topic.Name `
                   -OutputDir $OutputDir `
                   -Template $layout `
                   -ContentDir $ContentDir
}

# Generate global TOC at output/index.html
$tocEntries = @()

foreach ($topic in $topics) {
    $topicName = $topic.Name
    $pages = Get-ChildItem $topic.FullName -Filter *.txt | Sort-Object Name

    if ($pages.Count -gt 0) {
        $firstFile = $pages[0]
        $firstFileName = [System.IO.Path]::GetFileNameWithoutExtension($firstFile.Name) + ".html"
        $relativeLink = "$topicName/$firstFileName"

        # Use the folder name as link text
        $displayTitle = Convert-ToDisplayName $topicName

        $tocEntries += "<li><a href='$relativeLink'>$displayTitle</a></li>"
    }
}

$tocHtml = "<ul>`n$tocEntries`n</ul>"
$globalBody = "<h1>Contents</h1>`n$tocHtml"

$globalHtml = $layout.Replace('{{title}}', "Contents").Replace('{{content}}', $globalBody)
$globalIndexPath = Join-Path $OutputDir "index.html"
Set-Content -Path $globalIndexPath -Value $globalHtml -Encoding UTF8

Write-Host "Built global TOC: $globalIndexPath"
