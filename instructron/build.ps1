. $PSScriptRoot/fun/Convert-ToDisplayName.ps1
. $PSScriptRoot/fun/Link.ps1
. $PSScriptRoot/fun/Generate-Topic.ps1
. $PSScriptRoot/fun/Convert-TextToHtml.ps1
. $PSScriptRoot/fun/Split-IntoBlocks.ps1
. $PSScriptRoot/fun/Generate-GlobalToc.ps1

$ContentDir = "topics"
$TemplatePath = "templates/layout.html"
$OutputDir = "docs"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$layout = Get-Content $TemplatePath -Raw

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

Generate-GlobalToc -Topics $topics -ContentDir $ContentDir -OutputDir $OutputDir -Template $layout
