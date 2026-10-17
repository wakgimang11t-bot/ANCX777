# Security Policy

## Reporting a vulnerability

A playbook can modify Windows deeply, so a malicious or broken change is treated
as a security issue, not a normal bug.

Report privately through GitHub's **Security → Report a vulnerability** tab
(Security Advisories), or contact the maintainer directly. Please do not open a
public issue first.

Include:

- What the change does and where it lives (`playbook.conf` option, `main.yml` action, or a file in `Executables/`)
- Why it is dangerous — data loss, credential exposure, broken security feature
- The Windows build you reproduced it on
- Any log from `%ProgramData%\AME\Logs\`

Expect an acknowledgement within a few days.

## What counts

- A tweak that silently weakens security beyond the documented option
- A bundled binary that is not the published, hash-listed one
- An action that exfiltrates data or opens network access
- A change that makes a "keep" option non-functional, so users cannot revert

## Verifying a release

Every release ships a `.sha256` next to the `.apbx`:

```powershell
Get-FileHash .\ANCX777.apbx -Algorithm SHA256
```

Compare it with the value in `ANCX777.apbx.sha256` attached to the release.

> **The hash verifies the file you downloaded, not the source.** Playbook archives
> are encrypted with ZipCrypto, which writes a fresh random header into every
> encrypted entry — so building the same sources twice produces two different
> `.apbx` files with two different hashes. The `.sha256` attached to a release is
> generated from that exact artifact inside CI, which is what makes it meaningful.

Because the playbook is plain text, you can also unzip it (password `malte`) and
read every file before running it.

## Scope

This policy covers the ANCX777 playbook in this repository. AME Wizard itself is
maintained by Ameliorated — report issues with the tool to them.
