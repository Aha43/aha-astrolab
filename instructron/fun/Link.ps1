function Convert-LinkLineToHtml {
    param (
        [string]$line,
        [string]$contentDir
    )

    Write-Host "Converting link line to HTML: $line"

    $parts = $line -split "\s+", 3
    if ($parts.Count -ge 3) {
        $targetTopic = $parts[1]
        $linkText = $parts[2]
        $targetPath = Join-Path $contentDir $targetTopic
        $firstFile = Get-ChildItem $targetPath -Filter *.txt | Sort-Object Name | Select-Object -First 1

        if ($firstFile) {
            $targetFile = [System.IO.Path]::GetFileNameWithoutExtension($firstFile.Name) + ".html"
            return "<p><a href='../$targetTopic/$targetFile'>$linkText</a></p>"
        }
        else {
            return "<p>[Missing topic: $targetTopic]</p>"
        }
    }
    else {
        return "<p>[Invalid _link_ syntax]</p>"
    }
}

function Convert-ImageLineToHtml {
    param (
        [string]$line
    )

    $parts = $line -split "\s+", 4
    if ($parts.Count -ge 3) {
        $imgFile = $parts[1]
        $maybeSize = $parts[2]
        $desc = if ($parts.Count -eq 4) { $parts[3] } else { $parts[2] }

        # Check if it's a width percentage like "60%"
        if ($maybeSize -match '^\d{2,3}%$') {
            $width = $maybeSize
        } else {
            $width = "80%"
            $desc = $maybeSize + " " + $desc
        }

        return "<figure><img src='../images/$imgFile' alt='$desc' style='width:$width;' /><figcaption>$desc</figcaption></figure>"
    }
    else {
        return "<p>[Invalid _img_ line]</p>"
    }
}

function Convert-VideoLineToHtml {
    param (
        [string]$line
    )

    $parts = $line -split "\s+", 4
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

        return @"
<figure>
  <video controls style='width:$width; display: block; margin: 0 auto;'>
    <source src='../videos/$videoFile' type='video/mp4'>
    Your browser does not support the video tag.
  </video>
  <figcaption>$desc</figcaption>
</figure>
"@
    }
    else {
        return "<p>[Invalid _video_ line]</p>"
    }
}
