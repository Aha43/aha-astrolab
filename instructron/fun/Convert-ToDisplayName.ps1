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
    if ($rawName -like '*_*') {
        $parts = $rawName -split '_', 2
        $rawName = $parts[1]
    }
    Write-Host "rawName: $rawName"

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