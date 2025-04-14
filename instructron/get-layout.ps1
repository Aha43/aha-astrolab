# Ensure clean git state
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Error "Git state is not clean. Commit or stash changes before running get-layout.ps1."
    exit 1
}

$lines = @()

foreach ($topic in $topics) {
    $topicName = $topic.Name -replace '^.*?_'
    $lines += $topicName

    $files = Get-ChildItem $topic.FullName -Filter *.txt | Sort-Object Name
    foreach ($file in $files) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) -replace '^.*?_'
        $lines += "  $fileName"
    }
}

Set-Content -Path "layout.txt" -Value $lines -Encoding UTF8
Write-Host "layout.txt generated"
