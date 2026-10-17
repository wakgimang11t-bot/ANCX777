# Install guide

Read this whole page before running anything. Applying a playbook changes Windows
in ways that are not fully reversible.

## 1. Check requirements

| Requirement | Notes |
|---|---|
| Windows 10 1809+ or Windows 11 | `winver` shows your build. Supported builds are listed in `playbook.conf` → `SupportedBuilds` |
| [AME Wizard Beta](https://amelabs.net) 0.8.4+ | Must be the current Beta, not an old release |
| Windows Security exception for AME Wizard | Defender often flags `AME Wizard Beta.exe` as malicious. It is a known false positive — see the [AME security exceptions guide](https://docs.amelabs.net) |
| ~2 GB free space | For temporary extraction and cleanup |

**Do not run this on a machine you cannot reinstall.** A clean install is the only
guaranteed way back.

## 2. Back up

Do at least one of these:

- Create a **System Restore point** (`SystemPropertiesProtection.exe` → Create)
- Snapshot the VM if you are testing in one
- Copy anything irreplaceable off the machine

## 3. Download and verify

1. Download `ANCX777.apbx` from the [latest release](https://github.com/wakgimang11t-bot/ANCX777/releases/latest).
2. Download the matching `ANCX777.apbx.sha256` file too.
3. Verify the hash:

```powershell
Get-FileHash .\ANCX777.apbx -Algorithm SHA256
```

The output must match the contents of `ANCX777.apbx.sha256`. If it does not, do
not run the file — re-download it.

Optional: verify what you are about to run by unzipping it. The password is `malte`.

```powershell
7z x ANCX777.apbx -omalte_check
```

## 4. Run AME Wizard

1. Launch `AME Wizard Beta.exe`.
2. Drag `ANCX777.apbx` into the **Playbooks** column on the left.
3. Select **ANCX777** in the list.
4. Click **Next** through the requirement checks and the license agreement.
5. On **Configure Options**, choose what you want. Defaults are sane, but read the
   Defender row before continuing — see below.
6. Start the run and wait. Do not close the window.

> AME Wizard will show an **Unverified** badge next to ANCX777. See the
> [verified status](../README.md#-verified-status) section.

## 5. Choosing options

Options worth stopping on:

| Option | Default | Think about it if… |
|---|---|---|
| **Defender** | Disabled | You use this PC for banking, email, or anything from the internet. Then pick **Keep Defender** |
| **UAC** | Enabled | Disabling it can break Microsoft account sign-in |
| **Edge** | Removed | You rely on Edge profiles, IE mode, or WebView2 apps |
| **Printing** | Enabled | You actually need to print |
| **Hibernate** | Disabled | You use Fast Startup or hibernation on a laptop |
| **NVIDIA Overlay** | Keep | Leave this on if you record or screenshot with Alt+Z |

## 6. After it finishes

- Reboot if AME Wizard does not reboot for you.
- Sign in and give Windows a minute to settle — the first boot after tweaks does extra work.
- Check `%ProgramData%\AME\Logs\` if something looks wrong.

## 7. Verify it worked

- Menus and Start open instantly
- `services.msc` shows `DiagTrack` stopped and disabled
- Task Manager → Startup has fewer entries
- Your wallpaper (if selected) is the ANCX777 image

## Troubleshooting

**AME Wizard refuses the playbook.** Update AME Wizard. If it still refuses, your
Windows build is probably outside `SupportedBuilds`.

**The run reported errors.** Expected on some builds — the playbook targets a wide
range and skips what does not apply. Only worry if a feature you use stopped working.

**Something broke.** See [UNINSTALL.md](UNINSTALL.md).
