param(
    [string]$AddOnsRoot = 'F:\World of Warcraft\_anniversary_\Interface\AddOns'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')
$source = Join-Path $repoRoot 'TBCGearExporter'
$target = Join-Path $AddOnsRoot 'TBCGearExporter'

if (-not (Test-Path -LiteralPath $source)) {
    throw "Addon source folder not found: $source"
}

if (-not (Test-Path -LiteralPath $AddOnsRoot)) {
    throw "WoW AddOns folder not found: $AddOnsRoot"
}

New-Item -ItemType Directory -Path $target -Force | Out-Null

Get-ChildItem -LiteralPath $source -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
}

Write-Host "Installed TBCGearExporter to $target"
