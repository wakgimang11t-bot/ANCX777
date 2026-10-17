#Requires -Version 5.1
<#
.SYNOPSIS
    Validates and builds the ANCX777 .apbx playbook.

.DESCRIPTION
    Packages src/playbook into a single encrypted archive using the AME-standard
    password, so AME Wizard can import it by drag and drop. Writes the .apbx and a
    SHA256 checksum into src/release-zip.

    Playbooks are renamed ZIP archives. The password is not a security measure -
    it only keeps browsers and antivirus from scanning the archive contents.

    Before packaging, playbook.conf is validated against the limits AME Wizard
    enforces, so a broken config fails here instead of inside AME.

.PARAMETER Name
    Base file name for the produced archive.

.PARAMETER Password
    Archive password. Must stay 'malte' for AME Wizard to import the playbook.

.PARAMETER SkipValidation
    Package without running the playbook.conf checks. For debugging only.
#>
[CmdletBinding()]
param(
    [string]$Name   = 'ANCX777',
    [string]$Password = 'malte',
    [switch]$SkipValidation
)

$ErrorActionPreference = 'Stop'

$Root = if ($PSScriptRoot) { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) } else { (Get-Location).Path }
$SourceDir = Join-Path $Root 'src\playbook'
$OutputDir = Join-Path $Root 'src\release-zip'
$ConfPath  = Join-Path $SourceDir 'playbook.conf'

function Get-SevenZip {
    $cmd = Get-Command 7z, 7za -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    foreach ($p in @(
            (Join-Path $env:ProgramFiles '7-Zip\7z.exe'),
            (Join-Path ${env:ProgramFiles(x86)} '7-Zip\7z.exe')
        )) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    throw '7-Zip was not found. Install it or add 7z to PATH.'
}

function Test-PlaybookConf([string]$Path) {
    $errors = @()

    try {
        $xml = [xml](Get-Content -LiteralPath $Path -Raw)
    } catch {
        throw "playbook.conf is not valid XML: $($_.Exception.Message)"
    }

    # AME Wizard rejects pages with too many options; mirror the limits here.
    $limits = @{ CheckboxPage = 4; RadioPage = 4; RadioImagePage = 4 }
    $seen = @{}

    foreach ($page in $xml.Playbook.FeaturePages.ChildNodes) {
        $tag = $page.Name
        if (-not $limits.ContainsKey($tag)) {
            if ($tag -eq 'FeaturePage') {
                $errors += "FeaturePage cannot be used directly - use CheckboxPage, RadioPage or RadioImagePage"
            }
            continue
        }

        $options = @($page.Options.ChildNodes)
        $topBottomCount = @($page.PSObject.Properties | Where-Object { $_.Name -in 'TopLine', 'BottomLine' }).Count
        $limit = switch ($topBottomCount) {
            2 { [Math]::Min(2, $limits[$tag]) }
            1 { [Math]::Min(3, $limits[$tag]) }
            default { $limits[$tag] }
        }

        if ($options.Count -gt $limit) {
            $errors += "$tag has $($options.Count) options; AME allows at most $limit"
        }

        foreach ($opt in $options) {
            $n = $opt.Name
            if ([string]::IsNullOrWhiteSpace($n)) { $errors += "$tag contains an option without a <Name>"; continue }
            if ($seen.ContainsKey($n)) { $errors += "duplicate option name '$n'" } else { $seen[$n] = $true }
        }
    }

    if ($errors.Count) {
        throw ("playbook.conf validation failed:`n  - " + ($errors -join "`n  - "))
    }

    $title = $xml.Playbook.Title
    $version = $xml.Playbook.Version
    Write-Host "playbook.conf OK - '$title' v$version, $($seen.Count) options in $($xml.Playbook.FeaturePages.ChildNodes.Count) pages"
}

if (-not (Test-Path -LiteralPath $ConfPath)) { throw "playbook.conf not found at '$ConfPath'" }
if (-not $SkipValidation) { Test-PlaybookConf -Path $ConfPath }

$sevenZip = Get-SevenZip
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$outFile = Join-Path $OutputDir "$Name.apbx"
Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue

# Archive root must be playbook.conf / Configuration / Executables, so run from SourceDir.
Push-Location $SourceDir
try {
    & $sevenZip a -tzip "-p$Password" -mx=9 $outFile *
    if ($LASTEXITCODE -ne 0) { throw "7-Zip failed with exit code $LASTEXITCODE." }
} finally {
    Pop-Location
}

& $sevenZip t "-p$Password" $outFile | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Archive integrity test failed.' }

$hash = (Get-FileHash -LiteralPath $outFile -Algorithm SHA256).Hash
Set-Content -LiteralPath (Join-Path $OutputDir "$Name.apbx.sha256") -Value "$hash  $Name.apbx" -Encoding ASCII

"Built {0} ({1:N1} KB)" -f $outFile, ((Get-Item $outFile).Length / 1KB)
"SHA256 $hash"
