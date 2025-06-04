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