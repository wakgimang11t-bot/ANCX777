<h1 align="center">
  <img src="src/playbook/playbook.png" alt="ANCX777" width="220">
</h1>

<p align="center">
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/wakgimang11t-bot/ANCX777?style=for-the-badge&logo=github&color=1A91FF"/></a>
  <a href="https://github.com/wakgimang11t-bot/ANCX777/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/wakgimang11t-bot/ANCX777?style=for-the-badge&color=1A91FF"/></a>
  <a href="https://github.com/wakgimang11t-bot/ANCX777/graphs/contributors"><img alt="Contributors" src="https://img.shields.io/github/contributors/wakgimang11t-bot/ANCX777?style=for-the-badge&color=1A91FF"/></a>
</p>

<p align="center">An open-source AME Wizard playbook that makes Windows 10 and 11 feel lighter, respond faster, and collect less.</p>

<p align="center">
  <a href="https://github.com/wakgimang11t-bot/ANCX777/releases/latest">⬇️ Download</a>
  •
  <a href="docs/INSTALL.md">📚 Install guide</a>
  •
  <a href="docs/FAQ.md">❓ FAQ</a>
  •
  <a href="docs/RELEASING.md">🚀 Releasing</a>
  •
  <a href="https://docs.amelabs.net">📖 AME docs</a>
  •
  <a href="https://github.com/wakgimang11t-bot/ANCX777/discussions">💬 Discussions</a>
</p>

---

## ✨ What is ANCX777?

ANCX777 is a [Playbook](https://docs.amelabs.net/developers.html) for [AME Wizard](https://amelabs.net). It applies a curated set of performance, responsiveness and privacy tweaks to an existing Windows install — no custom ISO, no activation changes, no third-party patcher.

Every change is a plain-text line you can read. Nothing is hidden in a binary.

## 🤔 Why ANCX777?

### 📈 Lighter, faster Windows
Startup delay removed, menus instant, background apps and power throttling disabled, Superfetch and hibernation off, telemetry services stopped. The goal is a Windows that boots quick and never stutters over a menu animation.

### 🔒 Fewer phone-home components
Telemetry services (`DiagTrack`, `dmwappushservice`), scheduled tasks, tips/suggestions, Spotlight, and advertising IDs are turned off. This covers Windows itself — not your browser or third-party apps.

### 🖱️ Responsiveness, not placebo
No "registry magic" numbers copied off a forum. Every tweak in `Configuration/main.yml` has a visible effect or it wouldn't be there. If a tweak is purely cosmetic in benchmarks, it shouldn't be in the list.

### 🛡️ Security is your choice, and it is shown to you
Most Windows "optimizers" quietly strip security features. ANCX777 makes each one an explicit option and tells you the trade-off before you click:

| Option | Default | Trade-off |
|---|---|---|
| Windows Defender | **Disabled** | Better performance, **no real-time AV** |
| User Account Control | Enabled | Disabling it can break Microsoft account sign-in |
| Windows Update | Untouched | — |
| SmartScreen | Untouched | — |

If you don't want Defender off, pick **Keep Defender** on the options page — one click.

> ⚠️ Disabling Defender is the default but it is **not** required. On a daily-driver PC we recommend keeping it.

### 🔍 Open source and transparent
Unlike a patched Windows ISO, this playbook is auditable in a browser:

- `playbook.conf` — metadata and the option pages
- `Configuration/main.yml` — every action, in plain YAML
- `Executables/` — the couple of PowerShell scripts, also plain text

The archive is a renamed ZIP with the password `malte`, the AME standard. That password is **not** protection — it exists so browsers and antivirus don't scan the archive contents. Unzip it and read everything.

AME Wizard's GUI is closed source, but its entire backend ([TrustedUninstaller](https://github.com/Ameliorated-LLC/trusted-uninstaller-cli)) is MIT-licensed and contains every action a playbook can run.

### 🎨 Branding, and how to turn it off
The playbook writes the registered organization, so About Windows (`winver`) shows
**ACNX+ Optimize** on the line under `Windows User`. Choose **Keep Windows Default**
to leave that registry value untouched. Nothing here touches activation, your
Microsoft account, or the license — it is a display string. See the [FAQ](docs/FAQ.md).

### ⚖️ Legal compliance
ANCX777 does not redistribute a modified Windows image, so it stays within the [Microsoft Windows usage terms](https://www.microsoft.com/content/dam/microsoft/usetm/documents/windows/11/oem-(pre-installed)/UseTerms_OEM_Windows_11_English.pdf). It never touches activation.

---

## ⬇️ Installation

1. Read the [install guide](docs/INSTALL.md).
2. Create a **System Restore point** or back up important data first.
3. Download `ANCX777.apbx` from [Releases](https://github.com/wakgimang11t-bot/ANCX777/releases/latest).
4. Verify the checksum against the attached `.sha256` file.
5. Run `AME Wizard Beta.exe` and drag the `.apbx` into the Playbooks column.
6. Pick your options, run it, reboot.

**Requirements:** Windows 10 1809+ or Windows 11, and AME Wizard 0.8.4+.

> Defender may flag AME Wizard itself. That is a known false positive — see the [AME security exceptions guide](https://docs.amelabs.net).

## ↩️ Reverting

There is no uninstaller. Options are in [`docs/UNINSTALL.md`](docs/UNINSTALL.md):

- **System Restore** (only if you made a restore point)
- **Windows Reset** — cleanest result
- **Manual** — service and registry names are visible in `main.yml`

Re-running the playbook and choosing the **Keep …** option for a feature restores
its stock state. Defender, printing, search indexing, visual effects, SysMain and
hibernation/Fast Startup all have an undo path. `keep-edge` and `keep-wallpaper`
are deliberate no-ops — an Edge removal cannot be undone, and keeping a wallpaper
means changing nothing.

---

## 🔧 Building from source

```powershell
git clone https://github.com/wakgimang11t-bot/ANCX777.git
cd ANCX777
./src/dependencies/New-Playbook.ps1
```

Output lands in `src/release-zip/ANCX777.apbx` with a matching `.sha256`.

Needs 7-Zip on `PATH`. The script validates `playbook.conf` (XML well-formedness, AME's per-page option limits, duplicate option names) before packaging, so a broken config fails locally rather than inside AME Wizard.

Optional YAML cross-check — verifies every `option:` in `main.yml` is declared in `playbook.conf`:

```bash
pip install pyyaml
python src/dependencies/validate.py
```

### Repository layout

```
.github/
  workflows/apbx.yaml              CI: validate, build, publish releases
  release.yml                      categories for auto-generated notes
src/playbook/
  playbook.conf                    metadata + option pages
  Configuration/main.yml           every action
  Executables/                     bundled scripts and wallpaper
src/dependencies/
  New-Playbook.ps1                 validate + package + checksum
  New-ReleaseNotes.ps1             build the release page body from the template
  validate.py                      YAML / option cross-check
docs/
  INSTALL.md  FAQ.md  UNINSTALL.md
  RELEASING.md  RELEASE_TEMPLATE.md
  releases/v0.777.md               per-release upgrade notes
```

## 🚀 Releases

Releases are cut from tags, and the tag is the version. Push `v0.778` and CI
validates the sources, builds the playbook, generates the release page from
[`docs/RELEASE_TEMPLATE.md`](docs/RELEASE_TEMPLATE.md) plus that version's
changelog entry, and attaches `ANCX777.apbx` and its SHA256 — one entry per tag,
newest first, the same shape as an AtlasOS release.

```powershell
git tag v0.778
git push origin v0.778
```

Full steps, including hotfixes and re-releasing a bad tag, are in
[docs/RELEASING.md](docs/RELEASING.md).

## 🧩 Verified status

This playbook is **not verified by Ameliorated** — AME Wizard will show an *Unverified* badge. Verification is only granted to playbooks with an established reputation; see the [verification docs](https://docs.amelabs.net/developers/verification.html). Until then, audit the source yourself — that is exactly what it is there for.

## 🤝 Contributing

Tweaks, fixes and documentation are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## 🔐 Security

Found a tweak that breaks a system or a malicious PR? See [SECURITY.md](SECURITY.md).

## 📜 License

[GPL-3.0](LICENSE) — the same license AtlasOS uses.

## 💙 Credits

- [Ameliorated](https://amelabs.net) — AME Wizard and the playbook format
- [AtlasOS](https://github.com/Atlas-OS/Atlas) — reference for structure, tooling and documentation style
