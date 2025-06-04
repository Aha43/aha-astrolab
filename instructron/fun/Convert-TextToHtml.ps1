function Convert-TextToHtml {
    param (
        [string]$Text,
        [string]$ContentDir
    )

    Write-Host("Converting text to HTML...")

    Write-Host("Text: $Text")
    Write-Host("ContentDir: $ContentDir")

    if (-not $Text -or -not $Text.Trim()) {
        return @{
            Title   = "<h1>Work in progress: $ContentDir<h1>"
            Content = " "
        }
    }    

    $blocks = Split-IntoBlocks $Text

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
