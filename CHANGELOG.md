# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project uses its own versioning (`0.777`, `0.778`, …).

## [0.777] - 2026-10-17

Initial public release.

### Added
- Playbook metadata and option pages: Defender, UAC, Edge, wallpaper, printing,
  taskbar cleanup, and optional app removals (OneDrive, Teams, WSL, Photos, Xbox, AI/Copilot)
- Performance and responsiveness options: startup delay, instant menus, power
  throttling, background apps, tips/suggestions/Spotlight, last access timestamp,
  CPU priority, accessibility prompts, reserved storage, temp cleanup, faster
  shutdown, automatic maintenance
- Service and search options: Search indexing, Snappy visuals, SysMain, Hibernate & Fast Startup
- NVIDIA Overlay guarantee — keeps Alt+Z / ShadowPlay working (on by default)
- ANCX777 wallpaper (1920x1080) for desktop and lock screen, staged from the playbook
  so it survives after the temporary extraction directory is removed
- Build tooling: `src/dependencies/New-Playbook.ps1` validates `playbook.conf`
  against AME's page limits and packages the `.apbx` with a SHA256 checksum
- `src/dependencies/validate.py` cross-checks every `option:` in `main.yml`
  against the options declared in `playbook.conf`
- CI workflow that validates, builds, and attaches the playbook to GitHub releases
- Reversible options: re-running with a **Keep …** choice now restores the stock
  state for Defender, printing, search indexing, visual effects, SysMain, and
  hibernation/Fast Startup — previously those choices ran nothing at all
- Branding option: **Add ACNX+ Optimize Branding** writes `RegisteredOrganization`
  so the name shows on the line under `Windows User` in About Windows (winver).
  **Keep Windows Default** leaves the value untouched

### Fixed
- Removed the `DisableOverlays` graphics flag that could stop GPU overlays
  (NVIDIA Alt+Z, Steam, Discord) from appearing
- Split the performance options across multiple pages — AME Wizard rejects any
  `CheckboxPage` with more than four options

[0.777]: https://github.com/wakgimang11t-bot/ANCX777/releases/tag/v0.777
