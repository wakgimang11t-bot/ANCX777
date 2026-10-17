# Contributing to ANCX777

Thanks for wanting to help. This project is a playbook, so almost everything is
plain text — there is no compiler, no SDK, and no build server requirement.

## Ways to contribute

- **Report a bug** — a tweak that breaks a feature, or an option that does nothing
- **Propose a tweak** — with a concrete reason it helps, not a benchmark screenshot
- **Improve documentation** — the install guide, FAQ and uninstall notes get the most questions
- **Test** — apply the playbook on a throwaway VM or clean install and report what broke

## Before you open a PR

1. **Keep it plain text.** No new `.exe`/`.dll` in `Executables/` unless there is
   no alternative, and if there is, the source must be linked and its hash listed.
2. **No placebo tweaks.** If a change has no measurable effect, it does not belong.
3. **Never silently break a feature.** If a tweak can break printing, Bluetooth,
   or an overlay, it must be behind its own option.
4. **One concern per option.** Do not fold unrelated changes into an existing option.

## Adding a new tweak

1. Add the option to a page in `src/playbook/playbook.conf`.

   Remember AME's limits — it rejects a page that breaks any of these:

   | Page type | Max options | With one `TopLine`/`BottomLine` | With both |
   |---|---|---|---|
   | `CheckboxPage` | 4 | 3 | 2 |
   | `RadioPage` | 4 | 3 | 2 |
   | `RadioImagePage` | 4 | — | — |

   Option `<Name>` values must be unique across the whole playbook.

2. Add the matching action(s) to `src/playbook/Configuration/main.yml` with
   `option: 'your-option-name'` so it only runs when selected.

3. If the option is a toggle, add the "keep" counterpart too, so re-running the
   playbook can undo it.

## Local checks

Run both before pushing:

```powershell
./src/dependencies/New-Playbook.ps1     # validates playbook.conf and packages
python src/dependencies/validate.py     # cross-checks options against main.yml
```

CI (`.github/workflows/apbx.yaml`) runs the same two steps, so a PR that fails
locally will fail there.

Releases are cut from tags, not from a script you have to run by hand — see
[docs/RELEASING.md](docs/RELEASING.md).

`New-Playbook.ps1` catches the AME config limits above and duplicate option
names. `validate.py` catches an action referencing an option that does not exist,
or a declared option that nothing uses.

## Testing your change

- Test on a **clean Windows install or snapshot** — the playbook assumes a stock system.
- Note which Windows build you tested: `winver`.
- If your tweak is reversible, verify the revert path actually works.

## Commit and PR style

- Small, focused commits with a clear subject: `fix: keep NVIDIA overlay working`
- One feature per pull request.
- In the PR description, state: **what it changes**, **why**, and **what you tested on**.

## Repository settings to fill in

If you forked this, replace the `wakgimang11t-bot` placeholder before publishing:

- `README.md` and `README.id.md` — badge and clone URLs
- `src/playbook/playbook.conf` — the `<Git>` and `<Website>` fields

`<Git>` gives AME Wizard users a **Source Code** button and enables playbook
auto-updates. Do **not** invent a `<ProductCode>` — that is issued by Ameliorated
as part of [verification](https://docs.amelabs.net/developers/verification.html).

## License

By contributing you agree your work is released under [GPL-3.0](LICENSE).
