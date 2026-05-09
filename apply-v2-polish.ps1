param(
  [string]$PatchZip = "$env:USERPROFILE\Downloads\sozorock-ai-lab-v2-production-polish.zip"
)

$ErrorActionPreference = "Stop"

if (!(Test-Path ".git")) {
  throw "Run this script from the root of the sozorock-ai-lab repository."
}

if (!(Test-Path $PatchZip)) {
  throw "Patch zip not found at $PatchZip"
}

$extractTo = Join-Path $env:TEMP "sozorock-ai-lab-v2-production-polish"
Remove-Item $extractTo -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -Path $PatchZip -DestinationPath $extractTo -Force

$patchRoot = Join-Path $extractTo "sozorock-ai-lab-v2-production-polish"
if (!(Test-Path $patchRoot)) { $patchRoot = $extractTo }

Copy-Item "$patchRoot\*" "." -Recurse -Force
Remove-Item ".\dist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item ".\dist-ai-lab-prefix" -Recurse -Force -ErrorAction SilentlyContinue

$env:Path += ";C:\Program Files\Git\bin"
npm run build

git status
Write-Host "Patch applied and build completed. Review git status, then commit and push." -ForegroundColor Green
