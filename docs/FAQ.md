# FAQ

## Is this a custom Windows ISO?

No. It is a playbook for [AME Wizard](https://amelabs.net) that runs on your
existing Windows install. Nothing is redistributed, and activation is never touched.

## Will it delete my files?

No. The playbook changes services, registry values, scheduled tasks, and removes a
few built-in apps. It does clean temp files if you leave that option on. It does
not touch your documents, pictures, or personal folders.

## Is it safe? Why does it disable Defender?

Defender is off **by default** for performance, and it is the single biggest
security decision this playbook makes. You are told about it before you click, and
you can pick **Keep Defender** on the options page instead.

If this PC holds anything you care about, keep Defender on. You still get every
performance tweak — Defender is independent of them.

## AME Wizard wouldn't start, or my antivirus flagged it

Known false positive. AME Wizard modifies Windows deeply, which looks like malware
behaviour to a scanner. Add an exclusion for the AME Wizard folder, exactly as the
[AME docs](https://docs.amelabs.net) describe.

## The run finished but reported errors. Is it broken?

Usually not. ANCX777 targets a wide range of Windows builds, and a tweak that does
not apply to yours reports an error instead of failing the run. Only investigate if
a feature you actually use stopped working.

## Why does AME Wizard say "Unverified"?

Verification is granted by Ameliorated only to playbooks with an established
reputation. It is a manual review process — see the
[verification docs](https://docs.amelabs.net/developers/verification.html).

The upside of an unverified playbook is that you can read every line of it. The
archive is a ZIP (password `malte`) full of text.

## Can I undo it?

Not automatically. See [UNINSTALL.md](UNINSTALL.md). A System Restore point made
beforehand is the fast path.

## Why is the wallpaper 1920x1080? My screen is different.

The image is scaled to **fill** the screen (`WallpaperStyle = 10`), so it stays
proportional on any resolution — 1366x768, 1600x900, 2560x1440 and so on. On an
aspect ratio other than 16:9, the overflowing edge is cropped rather than stretched.

To use your own image, replace
`src/playbook/Executables/Windows/Web/Wallpaper/ANCX777/img0.jpg` and rebuild.

## Which tweaks are placebo?

None on purpose. If a change only looks good in a benchmark and does nothing real,
it does not get merged — see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Does it work on Windows 10?

Yes. Supported builds are listed in `SupportedBuilds` inside `playbook.conf`.

## Does it break NVIDIA's overlay (Alt+Z)?

No — keeping the overlay working is an explicit option, on by default. The playbook
leaves NVIDIA services and scheduled tasks alone and never sets the graphics
`DisableOverlays` flag that would block the overlay plane.

## Why does winver show "ACNX+ Optimize" under "Windows User"?

`winver` builds the "licensed to" block from two values under
`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion`: it prints `RegisteredOwner`
first (that is the `Windows User` line), then `RegisteredOrganization` on the next
line. The **Add ACNX+ Optimize Branding** option writes the second one.

It is cosmetic. It does not change activation, your Microsoft account, or the
license. To go back:

```powershell
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v RegisteredOrganization /t REG_SZ /d "" /f
```

Or run the playbook again and pick **Keep Windows Default**. If you would rather
replace the `Windows User` line itself, that is `RegisteredOwner` — same key,
different value.

## Can I use this on a machine I don't own?

No. Use it on hardware you control.

## Can I redistribute it?

Yes — it is GPL-3.0. Keeping the source available is the point of the project, so if
you fork and redistribute, publish your source too.
