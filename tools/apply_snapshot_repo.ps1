$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$repoFile = Join-Path $root 'config\snapshot.repo'
$yamlPath = Join-Path $root 'config\sources.yaml'
if (-not (Test-Path $repoFile)) {
  Write-Host '[INFO] config\snapshot.repo missing; snapshot.defaultUrl stays empty until this repo is on GitHub.'
  exit 0
}
$repo = (Get-Content -Raw -Path $repoFile).Trim()
if ($repo -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
  Write-Error "config\snapshot.repo must be owner/repo, got: $repo"
  exit 1
}
$url = "https://cdn.jsdelivr.net/gh/$repo@main/data/snapshot.json"
$text = Get-Content -Raw -Path $yamlPath
$updated = [regex]::Replace($text, '(?m)^  defaultUrl:.*$', "  defaultUrl: `"$url`"", 1)
if ($updated -eq $text) {
  Write-Error 'Could not find snapshot.defaultUrl in config\sources.yaml'
  exit 1
}
[System.IO.File]::WriteAllText($yamlPath, $updated)
Write-Host "[OK] snapshot.defaultUrl -> $url"
