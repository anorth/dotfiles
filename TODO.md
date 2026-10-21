# TODO

Things discussed but not yet done. The scope rule in `README.md` applies: if it
needs a `uname` check, it doesn't belong here.

## Mechanisms

- **A manifest file.** `install.sh` currently declares links in a `LINKS` array
  and external checkouts in a `REPOS` array, both inline. If either grows much
  further, move it out to a file. Submodules stay rejected: pinning fights
  against a repo you're actively editing.

## Open questions

- **Cloud agents.** Only `~/.cursor/skills/` syncs to them, and this installer
  links skills into `~/.agents/skills/` and `~/.claude/skills/`, so they are
  invisible to cloud agents, remote SSH sessions and self-hosted workers. Needs
  a different approach if that ever matters: also link into `~/.cursor/skills/`,
  project-level skills, or baking them into a worker image.
