# Agent notes

Linux-only customizations for **dev containers**: skills, scripts, and a
container-flavoured git config. See `README.md` for layout and install, `TODO.md`
for planned work.

## Constraints

- **Do not commit or push** unless the user explicitly asks. Propose the message
  and wait.
- **Container-only.** If it needs a `uname` check, it does not belong here.
  macOS-specific tooling stays on the development machine.
- **No secrets.** This repo is public. Tokens, keys, `.netrc`, `.aws`, `.ssh`
  contents never go in.
- **Installer is conservative.** `install.sh` links into `$HOME` and never
  overwrites a real file. Do not change that: a skipped existing file is
  intended, not a bug. Adopting it is a deliberate move-aside, then re-run.

Skills live in `skills/` and are linked to `~/.agents/skills/`. New scripts go in
`bin/` and are added to the `LINKS` array in `install.sh`.
