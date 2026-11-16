# Notes for coding agents and contributors

Packages [Niko1221/Strata](https://github.com/Niko1221/Strata), a local
inference engine, with a NixOS service module.

- Package: `package.nix`; module: `modules/strata-inference.nix`. Packages:
  `strata-inference`, `strata-engine`, and `-p40` variants built for Tesla P40
  (compute 6.1); change both variants together.
- Not the same project as `lgse/strata` (a GTK file manager). Binaries and the
  service are named `strata-inference` on purpose; keep that name.
- Build and try it: `nix run .`.
- Manual update: bump `version`, set the changed hash to `lib.fakeHash`,
  build, and copy the hash Nix reports. The package pins two sources; bump both `rev`s and hashes together.

<!-- nix-agent-guides:core BEGIN (v2). Synced from deepwatrcreatur/nix-agent-guides templates/agents-core.md by scripts/sync-agents-core.sh. Edit it there, not here. -->
## Shared conventions

Canonical, newest version:
https://raw.githubusercontent.com/deepwatrcreatur/nix-agent-guides/main/CONVENTIONS.md
If you can fetch it, read it before larger changes; where it differs from the
summary below, it is newer. This repo's own instructions above take
precedence over both.

Summary (offline fallback):

- **Comments explain why, not what.** Mark them `# WHY:`, `# GOTCHA:`,
  `# INVARIANT:`, `# SECURITY:`, `# UPSTREAM:` or `# TODO(#issue):`. One to
  three lines above the code they protect; longer reasoning goes in `docs/`
  with a pointer (`# WHY: docs/x.md#heading`). Never narrate the next line.
- **Before editing a file**, read its tags:
  `rg -n '# (WHY|GOTCHA|INVARIANT|SECURITY|UPSTREAM|TODO)' <file>`.
  Fix or delete any tag your change makes untrue.
- **Exported Nix functions** get RFC 145 doc comments (`/** ... */`).
- **Validate before committing:** the narrowest `nix build` first, then
  `nix flake check`; read all output. Run `bash -n`/`shellcheck` on shell
  generated from Nix. Exit code 0 is not proof the change worked.
- **Same change, same PR:** behaviour changes come with docs and a check.
- **Never commit secrets**, and do not deploy to or change live hosts unless
  asked.
<!-- nix-agent-guides:core END -->
