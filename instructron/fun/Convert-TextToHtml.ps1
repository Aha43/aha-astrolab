function Convert-TextToHtml {
    param ($text)

    Write-Host("Converting text to HTML...")

    if (-not $text -or -not $text.Trim()) {
        return @{
            Title   = "Work in progress"
            Content = "<h1>Work in progress</h1><p>This page has not been written yet.</p>"
        }
    }    

    $blocks = Split-IntoBlocks $text

    if ($blocks.Count -eq 0) {
        Write-Host("No blocks found in text.")
        return
    }

    # Handle status: done / wip metadata
    $firstBlock = $blocks[0]
    if ($firstBlock -match '^status:\s*(.+)$') {
        $status = $Matches[1].ToLower()
        # Remove the block entirely
        $blocks = $blocks[1..($blocks.Count - 1)]
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
