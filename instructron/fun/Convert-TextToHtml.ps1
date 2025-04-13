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