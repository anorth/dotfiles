# Agent notes

Linux-only customizations for **dev containers**: scripts and a
container-flavoured git config. See `README.md` for layout and install, `TODO.md`
for planned work.

Agent skills are not in this repo. They live in
[anorth/agent-skills](https://github.com/anorth/agent-skills). `install.sh`
clones or reuses that catalog and links each skill into `~/.agents/skills/`.

## Constraints

- **Do not commit or push** unless the user explicitly asks. Propose the message
  and wait.
- **Container-only.** If it needs a `uname` check, it does not belong here.
  macOS-specific tooling stays on the development machine. Skills are the
  exception that lives elsewhere: edit them in the agent-skills repo, not here.
- **No secrets.** This repo is public. Tokens, keys, `.netrc`, `.aws`, `.ssh`
  contents never go in.
- **Installer is conservative.** `install.sh` links into `$HOME` and never
  overwrites a real file. Do not change that: a skipped existing file is
  intended, not a bug. Adopting it is a deliberate move-aside, then re-run.
  The same rule applies to the agent-skills checkout: dirty or diverged trees
  are reported and skipped, not force-updated.

New scripts go in `bin/` and are added to the `LINKS` array in `install.sh`.
New skills go in the agent-skills repo.
