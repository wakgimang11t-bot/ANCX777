# Releasing

Releases are cut from tags, exactly like AtlasOS. One tag makes one entry in the
Releases list, newest first, and the `.apbx` is attached to it automatically.

## Cut a release

1. **Write the changelog entry.** Add a new section at the top of `CHANGELOG.md`:

   ```markdown
   ## [0.778] - 2026-11-02

   ### Added
   - ...
   ```

2. **Bump the playbook version.** In `src/playbook/playbook.conf`:

   ```xml
   <Version>0.778</Version>
   ```

   This is what AME Wizard shows, and it is what drives the playbook's own updater.

3. **Optional: upgrade notes.** Drop `docs/releases/v0.778.md` with anything users
   must know before applying — required Windows build, steps that changed, known
   issues. If the file is missing, the release page falls back to a default line.

4. **Commit and push to `main`.** CI builds and validates, but does not publish.

5. **Tag and push the tag:**

   ```powershell
   git tag v0.778
   git push origin v0.778
   ```

6. CI generates the release body from `docs/RELEASE_TEMPLATE.md` plus the changelog
   section and the upgrade notes, then publishes the release with:

   - `ANCX777.apbx`
   - `ANCX777.apbx.sha256`

## Naming

| Type | Tag | Result |
|---|---|---|
| Normal release | `v0.778` | `ANCX777 v0.778` |
| Hotfix | `v0.778.1` | `ANCX777 v0.778.1` |
| Test build | `v0.779-beta` | shows as a pre-release once you tick the box |

The tag **is** the version — `v0.778.1` looks for `## [0.778.1]` in the changelog
and `docs/releases/v0.778.1.md` for notes.

## Checksums

CI writes `ANCX777.apbx.sha256` from the artifact it just built, then attaches both
to the release. That pairing is the point — it lets a user prove the file they
downloaded is the file that was published.

Do not try to make the hash reproducible. Playbook archives use ZipCrypto
encryption, and ZipCrypto writes a fresh random header into every encrypted entry,
so the same sources produce a different `.apbx` — and a different hash — on every
build. Two people building from the same commit will not match, and that is
expected.

## Preview the release page locally

```powershell
./src/dependencies/New-ReleaseNotes.ps1 -Tag v0.778
```

Writes `release-body.md` and prints the size. Open it and check the links before
you push the tag.

## Fixing a bad release

Delete the release in the GitHub UI, delete the tag locally and remotely, then
re-tag the corrected commit:

```powershell
git tag -d v0.778
git push origin :refs/tags/v0.778
```

Re-releasing the same version is fine while nothing has moved past it. Once users
have installed a version, prefer a new patch version over a silent edit — AME
Wizard compares versions.
