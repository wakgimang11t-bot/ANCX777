#Requires -Version 5.1
<#
.SYNOPSIS
    Builds the GitHub release body for a tag from the release template.

.DESCRIPTION
    Fills docs/RELEASE_TEMPLATE.md with the tag's version, the matching section of
    CHANGELOG.md, per-release upgrade notes from docs/releases/<tag>.md, the short
    commit SHA and the current date. Writes release-body.md, which the release
    workflow then hands to the GitHub release action.

    Output goes to the repository root because the release action resolves
    body_path relative to the workspace.

.PARAMETER Tag
    The tag being released, e.g. v0.777. A leading "v" is optional.

.PARAMETER OutputPath
    Where to write the body. Defaults to release-body.md in the repository root.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Tag,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$Root = if ($PSScriptRoot) { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) } else { (Get-Location).Path }
if (-not $OutputPath) { $OutputPath = Join-Path $Root 'release-body.md' }

$Version = $Tag -replace '^v', ''

$TemplatePath = Join-Path $Root 'docs\RELEASE_TEMPLATE.md'
$ChangelogPath = Join-Path $Root 'CHANGELOG.md'
$NotesPath = Join-Path $Root "docs\releases\$Tag.md"

if (-not (Test-Path -LiteralPath $TemplatePath)) { throw "release template not found at '$TemplatePath'" }

function Read-Utf8([string]$Path) {
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Get-ChangelogSection([string]$Path, [string]$Version) {
    if (-not (Test-Path -LiteralPath $Path)) { return "_No CHANGELOG.md found._" }

    $lines = (Read-Utf8 $Path) -split "`r?`n"
    $pattern = '^##\s+\[' + [regex]::Escape($Version) + '\]'
    $next = '^##\s+\['
    $start = -1
    $end = $lines.Count

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($start -lt 0) {
            if ($lines[$i] -match $pattern) { $start = $i }
            continue
        }
        if ($lines[$i] -match $next) { $end = $i; break }
    }

    if ($start -lt 0) { return "_No CHANGELOG.md entry for ``$Version``._" }

    # Drop the heading line itself; the release page already shows the version.
    $body = ($lines[($start + 1)..($end - 1)] -join "`n").Trim()
    if (-not $body) { $body = "_No changes recorded for this release._" }
    return $body
}

if (Test-Path -LiteralPath $NotesPath) {
    # Drop the file's own "# heading" - the release page already has a title.
    $upgradeNotes = ((Read-Utf8 $NotesPath) -split "`r?`n" | Where-Object { $_ -notmatch '^#\s' } | Out-String).Trim()
} else {
    $upgradeNotes = '_No special upgrade steps. A clean install is always the safest path._'
}

$sha = 'unknown'
try {
    $sha = (& git rev-parse --short HEAD 2>$null | Select-Object -First 1)
    if (-not $sha) { $sha = 'unknown' }
} catch { $sha = 'unknown' }

$body = Read-Utf8 $TemplatePath
$body = $body.Replace('{{VERSION}}', $Version)
$body = $body.Replace('{{TAG}}', $Tag)
$body = $body.Replace('{{DATE}}', (Get-Date -Format 'yyyy-MM-dd'))
$body = $body.Replace('{{SHA}}', $sha)
$body = $body.Replace('{{UPGRADE_NOTES}}', $upgradeNotes)
$body = $body.Replace('{{CHANGELOG}}', (Get-ChangelogSection -Path $ChangelogPath -Version $Version))

# UTF-8 without a BOM - the release body is rendered as markdown.
[System.IO.File]::WriteAllText($OutputPath, $body, (New-Object System.Text.UTF8Encoding($false)))
"Release body written to $OutputPath (" + $body.Length + " chars, version $Version)"
