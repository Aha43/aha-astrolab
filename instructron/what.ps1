$ContentDir = "content"
$topics = Get-ChildItem $ContentDir -Directory | Sort-Object Name

Write-Host "`n🚧 Content Work Report:`n"

foreach ($topic in $topics) {
    $topicName = $topic.Name
    $topicPath = $topic.FullName
    $files = Get-ChildItem $topicPath -Filter *.txt | Sort-Object Name

    $incomplete = @()

    if ($files.Count -eq 0) {
        Write-Host "📂 Topic: $topicName"
        Write-Host "  - No files yet"
        continue
    }

    foreach ($file in $files) {
        $lines = Get-Content $file.FullName
        $firstNonEmpty = $lines | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1
    
        $status = "wip"  # default
    
        if ($firstNonEmpty -match '^status:\s*(.+)$') {
            $status = $Matches[1].ToLower()
        }
    
        if ($status -ne "done") {
            $incomplete += $file.Name
            Write-Host "  - $($file.Name): $status"
        }
    }

}
