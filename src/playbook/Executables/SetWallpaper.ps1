<#
.SYNOPSIS
    Applies the ANCX777 desktop and/or lock screen wallpaper.

.DESCRIPTION
    Runs under the logged-in user's elevated context so HKCU is the real user hive.
    The image is taken from the path the playbook passes in; if that path does not
    exist yet, the copy bundled inside the playbook is staged at a stable system
    location first, so the wallpaper keeps working after the playbook's temporary
    extraction directory is deleted.

.PARAMETER Mode
    Desktop    - sets the current user's desktop wallpaper.
    LockScreen - sets the machine lock screen image.

.PARAMETER ImagePath
    Preferred absolute path to the image. A missing/unreadable image is a no-op
    (exit 0), so a playbook with no bundled image never fails.

.NOTES
    Fail-closed: a missing or unreadable image leaves the current wallpaper untouched.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Desktop', 'LockScreen')]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$ImagePath
)

$ErrorActionPreference = 'Stop'

$WallpaperDir = Join-Path $env:SystemRoot 'Web\Wallpaper\ANCX777'
$StableImage  = Join-Path $WallpaperDir 'img0.jpg'
$BundledImage = Join-Path $PSScriptRoot 'Windows\Web\Wallpaper\ANCX777\img0.jpg'

function Write-Log([string]$Message) {
    try {
        $logDir = Join-Path $env:ProgramData 'ANCX777\Logs'
        if (-not (Test-Path -LiteralPath $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        $line = '{0} SetWallpaper: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        Add-Content -LiteralPath (Join-Path $logDir 'ANCX777-Scripts.log') -Value $line -Encoding UTF8
    } catch { }
}

function Resolve-Image([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    # Expand %winDir%-style tokens and $env: references used by the playbook.
    $candidate = [System.Environment]::ExpandEnvironmentVariables($Path)
    $candidate = $candidate -replace '\$env:systemroot', $env:SystemRoot
    $candidate = $candidate -replace '\$env:windir', $env:windir
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    return $null
}

# 1. Preferred path: the final system location the playbook hands us.
$resolved = Resolve-Image $ImagePath

# 2. Fall back to the image bundled in the playbook, staged next to this script.
if (-not $resolved -and (Test-Path -LiteralPath $BundledImage -PathType Leaf)) {
    try {
        if (-not (Test-Path -LiteralPath $WallpaperDir)) {
            New-Item -Path $WallpaperDir -ItemType Directory -Force | Out-Null
        }
        Copy-Item -LiteralPath $BundledImage -Destination $StableImage -Force
        $resolved = $StableImage
        Write-Log "staged bundled image at '$StableImage'"
    } catch {
        Write-Log "could not stage bundled image: $($_.Exception.Message)"
    }
}

if (-not $resolved) {
    Write-Log "image not found for '$ImagePath' - skipping (no change)"
    exit 0
}

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class AncxWallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    public static bool Set(string path) {
        const int SPI_SETDESKWALLPAPER = 0x0014;
        const int SPIF_UPDATEINIFILE = 0x01;
        const int SPIF_SENDCHANGE = 0x02;
        return SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE) != 0;
    }
}
'@ -ErrorAction Stop

try {
    switch ($Mode) {
        'Desktop' {
            $desktop = 'HKCU:\Control Panel\Desktop'
            # WallpaperStyle = 10 (Fill), TileWallpaper = 0; WallPaper makes it stick across logon.
            Set-ItemProperty -Path $desktop -Name WallpaperStyle -Value '10'     -Force
            Set-ItemProperty -Path $desktop -Name TileWallpaper  -Value '0'      -Force
            Set-ItemProperty -Path $desktop -Name WallPaper      -Value $resolved -Force

            # Seed the per-user theme cache so Explorer does not fall back to the old image.
            try {
                $themes = Join-Path $env:APPDATA 'Microsoft\Windows\Themes'
                if (-not (Test-Path -LiteralPath $themes)) { New-Item -ItemType Directory -Path $themes -Force | Out-Null }
                Copy-Item -LiteralPath $resolved -Destination (Join-Path $themes 'TranscodedWallpaper') -Force
            } catch {
                Write-Log "theme cache not written: $($_.Exception.Message)"
            }

            $applied = [AncxWallpaper]::Set($resolved)
            Write-Log "desktop wallpaper set to '$resolved' (live=$applied)"
        }
        'LockScreen' {
            $screenDir = Join-Path $env:SystemRoot 'Web\Screen'
            if (-not (Test-Path -LiteralPath $screenDir)) { New-Item -ItemType Directory -Path $screenDir -Force | Out-Null }
            $lockImage = Join-Path $screenDir 'ANCX777-lockscreen.jpg'
            Copy-Item -LiteralPath $resolved -Destination $lockImage -Force

            $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
            if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
            Set-ItemProperty -Path $key -Name LockScreenImageStatus -Value 1          -Type DWord  -Force
            Set-ItemProperty -Path $key -Name LockScreenImagePath   -Value $lockImage  -Type String -Force
            Set-ItemProperty -Path $key -Name LockScreenImageUrl    -Value $lockImage  -Type String -Force
            Write-Log "lock screen image set to '$lockImage'"
        }
    }
} catch {
    Write-Log "failed for mode '$Mode': $($_.Exception.Message)"
    exit 0
}

exit 0
