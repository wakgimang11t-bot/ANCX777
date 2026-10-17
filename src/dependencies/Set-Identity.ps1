#Requires -Version 5.1
<#
.SYNOPSIS
    Points the repository at your own GitHub account.

.DESCRIPTION
    Fills in the details that cannot be shipped in a template:

      * replaces the USERNAME placeholder in the docs, issue templates and
        changelog with your account name
      * adds <Git> and <Website> to playbook.conf, which gives AME Wizard users a
        "Source Code" button and enables the playbook's own updater
      * optionally adds <DonateLink> and <ProductCode>

    Run this once, before the first push. It is idempotent: running it again with
    a different account rewrites the previous one, and <Git>/<Website> are only
    inserted when they are missing.

.PARAMETER Username
    GitHub account or organisation, e.g. acenkk13. Also used to build the URLs.

.PARAMETER Repository
    Repository name. Defaults to ANCX777.

.PARAMETER DonateLink
    Optional donation URL.

.PARAMETER ProductCode
    Optional verification code issued by Ameliorated. Do not invent one - it only
    comes from the verification process.

.EXAMPLE
    ./src/dependencies/Set-Identity.ps1 -Username acenkk13
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [string]$Repository = 'ANCX777',

    [string]$DonateLink,

    [string]$ProductCode
)

$ErrorActionPreference = 'Stop'

$Root = if ($PSScriptRoot) { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) } else { (Get-Location).Path }
$RepoUrl = "https://github.com/$Username/$Repository"
$ConfPath = Join-Path $Root 'src\playbook\playbook.conf'

# UTF-8 without a BOM, and no line-ending translation, so LF files stay LF.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Read-Text([string]$Path) { [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
function Write-Text([string]$Path, [string]$Text) { [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom) }

# Files that carry the placeholder in their links.
$docFiles = @(
    'README.md'
    'README.id.md'
    'CONTRIBUTING.md'
    'CHANGELOG.md'
    'SECURITY.md'
    'docs\RELEASE_TEMPLATE.md'
    'docs\RELEASING.md'
    'docs\INSTALL.md'
    'docs\FAQ.md'
    'docs\UNINSTALL.md'
    '.github\ISSUE_TEMPLATE\config.yml'
)

if ($Username -match '[/:\\ ]') { throw "'$Username' is not a valid GitHub account name." }

Write-Host "Pointing the repository at $RepoUrl`n"

$totalReplaced = 0
foreach ($rel in $docFiles) {
    $path = Join-Path $Root $rel
    if (-not (Test-Path -LiteralPath $path)) { continue }

    $text = Read-Text $path
    # Ordinal, case-sensitive: <Username>ANCX777</Username> must not be touched.
    $hits = ([regex]::Matches($text, 'USERNAME')).Count
    if ($hits -eq 0) { continue }

    Write-Text $path ($text.Replace('USERNAME', $Username))
    $totalReplaced += $hits
    Write-Host ("  {0,-46} {1} replacement(s)" -f $rel, $hits)
}

if ($totalReplaced -eq 0) { Write-Host '  no placeholders left to replace' }

if (-not (Test-Path -LiteralPath $ConfPath)) { throw "playbook.conf not found at '$ConfPath'" }

$conf = Read-Text $ConfPath
$changed = $false

if ($conf -notmatch '<Git>') {
    # Anchor on the last metadata element before the option pages.
    $anchor = "`t<FeaturePages>"
    if ($conf -notmatch [regex]::Escape($anchor)) { throw 'playbook.conf has no <FeaturePages> element to anchor on.' }
    $conf = $conf.Replace($anchor, "`t<Git>$RepoUrl</Git>`n`t<Website>$RepoUrl</Website>`n$anchor")
    $changed = $true
    Write-Host '  playbook.conf                              added <Git> and <Website>'
} else {
    # Already set up - rewrite the URLs if the account changed.
    $updated = $false
    foreach ($tag in 'Git', 'Website') {
        $match = [regex]::Match($conf, "<$tag>.*?</$tag>", 'Singleline')
        if (-not $match.Success) {
            $conf = $conf.Replace("`t<Git>", "`t<$tag>$RepoUrl</$tag>`n`t<Git>")
            $updated = $true
            continue
        }
        $want = "<$tag>$RepoUrl</$tag>"
        if ($match.Value -ne $want) {
            # Remove + Insert rather than regex-replace, so a '$' in the URL is literal.
            $conf = $conf.Remove($match.Index, $match.Length).Insert($match.Index, $want)
            $updated = $true
        }
    }
    if ($updated) {
        $changed = $true
        Write-Host "  playbook.conf                              updated <Git> and <Website>"
    } else {
        Write-Host '  playbook.conf                              <Git> and <Website> already correct'
    }
}

if ($DonateLink) {
    if ($conf -match '<DonateLink>') {
        $conf = [regex]::Replace($conf, '<DonateLink>.*?</DonateLink>', "<DonateLink>$DonateLink</DonateLink>")
    } else {
        $conf = $conf.Replace("`t<Git>", "`t<DonateLink>$DonateLink</DonateLink>`n`t<Git>")
    }
    $changed = $true
    Write-Host "  playbook.conf                              <DonateLink> = $DonateLink"
}

if ($ProductCode) {
    if ($conf -match '<ProductCode>') {
        $conf = [regex]::Replace($conf, '<ProductCode>.*?</ProductCode>', "<ProductCode>$ProductCode</ProductCode>")
    } else {
        $conf = $conf.Replace("`t<Git>", "`t<ProductCode>$ProductCode</ProductCode>`n`t<Git>")
    }
    $changed = $true
    Write-Host "  playbook.conf                              <ProductCode> = $ProductCode"
}

if ($changed) { Write-Text $ConfPath $conf }

Write-Host "`nDone. Next:"
Write-Host '  1. ./src/dependencies/New-Playbook.ps1        rebuild the .apbx'
Write-Host '  2. push the repo, then tag it (see docs/RELEASING.md)'
