# Uninstalling / reverting

There is no uninstaller. A playbook is not an installed program — it is a one-shot
set of changes to Windows. Reverting means putting those changes back yourself.

Pick the first option that is available to you.

## Option 0 — Re-run with the "Keep" choice (supported)

Every aggressive option has an undo path. Run AME Wizard again and pick the
**Keep …** choice for whatever you want back:

| To restore | Choose |
|---|---|
| Windows Security / Defender | **Keep Defender** |
| Printing | **Keep Printing** |
| Search indexing | **Keep Search** |
| Visual effects / animations | **Keep visuals** |
| SysMain (Superfetch) + prefetch | **Keep SysMain** |
| Hibernation + Fast Startup | **Keep Hibernate** |

Only two options do not restore anything: `keep-edge` (Edge removal deletes files —
it cannot be undone) and `keep-wallpaper` (keeping the current wallpaper simply
changes nothing).

## Option 1 — System Restore (fastest, if you made a point)

Only works if you created a restore point **before** applying the playbook.

```
SystemPropertiesProtection.exe
```

Select the restore point and roll back. Tweaks applied after that point come back.

## Option 2 — Windows Reset (cleanest)

Settings → System → Recovery → **Reset this PC** → *Keep my files* (or remove
everything for a fully clean result).

This restores Windows itself. Your data stays if you choose to keep files.

## Option 3 — Reinstall Windows

The only guaranteed 100% clean result. Recommended if you hit odd, unexplained
behaviour after a run.

## Option 4 — Undo specific tweaks by hand

Everything applied is visible in `src/playbook/Configuration/main.yml`. Each line
tells you exactly what it changed:

| Change type | Where to look |
|---|---|
| Services disabled | `services.msc` — the `!service` actions name each service |
| Registry values | `regedit` — the `!registryValue` actions give the full path and value |
| Scheduled tasks | Task Scheduler — the `!run` / `!cmd` schtasks actions |
| Removed apps | Reinstall from the Microsoft Store — the `!appx` actions name each package |
| Removed files | The `!file` actions list each path |

### Common ones

**Windows Security / Defender back on**

The supported way: run the playbook again and select **Keep Defender**. If you
want to do it by hand:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
sc config WinDefend start= auto
sc start WinDefend
```

Then reboot. Note that some third-party AV may have taken over while Defender was off.

**Telemetry service back on**

```powershell
sc config DiagTrack start= auto
sc start DiagTrack
```

**Superfetch / SysMain back on**

```powershell
sc config SysMain start= auto
sc start SysMain
```

**Hibernation back on**

```powershell
powercfg /hibernate on
```

**Print Spooler back on**

```powershell
sc config Spooler start= auto
sc start Spooler
```

**Search back on**

```powershell
sc config WSearch start= delayed-auto
sc start WSearch
```

## Before you wipe anything

If you are reverting because a **specific feature broke** rather than wanting a
clean system, open an issue first — it may be a one-line fix, and it helps the
next person.
