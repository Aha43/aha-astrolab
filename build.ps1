$ContentDir = "content"
$TemplatePath = "templates/layout.html"
$OutputDir = "docs"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$layout = Get-Content $TemplatePath -Raw

function Convert-ToDisplayName {
    param (
        [string]$rawName,
        [switch]$IsFile
    )

    # For files, remove everything after the first dot (extension)
    if ($IsFile) {
        $rawName = ($rawName -split '\.')[0]
    }

    # Remove prefix if name contains underscore
    if ($rawName -contains '_') {
        $parts = $rawName -split '_', 2
        $rawName = $parts[1]
    }

    # Replace dashes/underscores with spaces
    $cleaned = $rawName -replace '[-_]', ' '

    # Title-case each word, but preserve acronyms (e.g., GPS, LS60MT)
    $words = $cleaned -split '\s+' | ForEach-Object {
        if ($_ -cmatch '^[A-Z0-9]{3,}$') {
            $_
        }
        elseif ($_.Length -gt 0) {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower()
        }
    }

    return ($words -join ' ')
}

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
            $parts = $para -split "\s+", 3
            if ($parts.Count -ge 3) {
                $targetTopic = $parts[1]
                $linkText = $parts[2]
                $targetPath = Join-Path $ContentDir $targetTopic
                $firstFile = Get-ChildItem $targetPath -Filter *.txt | Sort-Object Name | Select-Object -First 1
                if ($firstFile) {
                    $targetFile = [System.IO.Path]::GetFileNameWithoutExtension($firstFile.Name) + ".html"
                    $htmlBlocks += "<p><a href='../$targetTopic/$targetFile'>$linkText</a></p>"
                }
                else {
                    $htmlBlocks += "<p>[Missing topic: $targetTopic]</p>"
                }
            }
            else {
                $htmlBlocks += "<p>[Invalid _link_ syntax]</p>"
            }
        }
        elseif ($para -like "_img_*") {
            $parts = $para -split "\s+", 4
            if ($parts.Count -ge 3) {
                $imgFile = $parts[1]
                $maybeSize = $parts[2]
                $desc = if ($parts.Count -eq 4) { $parts[3] } else { $parts[2] }
        
                # check if the 3rd part is a percentage
                if ($maybeSize -match '^\d{2,3}%$') {
                    $width = $maybeSize
                } else {
                    $width = "80%"  # default
                    $desc = $maybeSize + " " + $desc
                }
        
                $htmlBlocks += "<figure><img src='../images/$imgFile' alt='$desc' style='width:$width;' /><figcaption>$desc</figcaption></figure>"
            }
            else {
                $htmlBlocks += "<p>[Invalid _img_ line]</p>"
            }
        }        
        elseif ($para -like "_video_*") {
            $parts = $para -split "\s+", 4
            if ($parts.Count -ge 3) {
                $videoFile = $parts[1]
                $maybeSize = $parts[2]
                $desc = if ($parts.Count -eq 4) { $parts[3] } else { $parts[2] }
        
                if ($maybeSize -match '^\d{2,3}%$') {
                    $width = $maybeSize
                } else {
                    $width = "80%"
                    $desc = $maybeSize + " " + $desc
                }
        
                $htmlBlocks += @"
        <figure>
          <video controls style='width:$width;'>
            <source src='../videos/$videoFile' type='video/mp4'>
            Your browser does not support the video tag.
          </video>
          <figcaption>$desc</figcaption>
        </figure>
"@
            }
            else {
                $htmlBlocks += "<p>[Invalid _video_ line]</p>"
            }
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
    $topicName = $topic.Name
    $topicPath = Join-Path $OutputDir $topicName
    if (-not (Test-Path $topicPath)) {
        New-Item -ItemType Directory -Path $topicPath | Out-Null
    }

    $pages = Get-ChildItem $topic.FullName -Filter *.txt | Sort-Object Name
    if ($pages.Count -eq 0) {
        Write-Host "No pages found in $topicName"
        continue
    }

    for ($i = 0; $i -lt $pages.Count; $i++) {
        $file = $pages[$i]
        $raw = Get-Content $file.FullName -Raw
        $converted = Convert-TextToHtml $raw

        $title = $converted.Title
        $body = $converted.Content

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

        $finalHtml = $layout -replace '\{\{title\}\}', $title
        $finalHtml = $finalHtml -replace '\{\{content\}\}', $body

        $outputPath = Join-Path $topicPath ([System.IO.Path]::GetFileNameWithoutExtension($file.Name) + ".html")
        Set-Content -Path $outputPath -Value $finalHtml -Encoding UTF8

        Write-Host "Built $topicName/$($file.Name) -> $outputPath"
    }
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
