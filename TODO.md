# TODO

Things discussed but not yet done. The scope rule in `README.md` applies: if it
needs a `uname` check, it doesn't belong here.

## Content to bring over

- **Portable shell config.** The git aliases from `.zshrc` are the valuable part.
  Containers give bash, so this wants to be a `shell/common.sh` that both
  `.bashrc` and a local `.zshrc` can source. Of the functions, `extract` is
  portable, `killport` needs `lsof`, and `j` needs `fzf`.

  There is a wrinkle to solve here: the installer will not overwrite the
  container's existing `~/.bashrc`, so it cannot simply append a `source` line.
  Either ship a `.bashrc` and require the default be moved aside, or accept that
  shell config only applies where something already sources it. The same
  constraint is why `~/bin` currently reaches `PATH` only via `.profile`.

## Mechanisms

- **A manifest file.** `install.sh` currently declares links in a `LINKS` array
  inline. If that grows much beyond git config, move it out to a file.
- **Generalised external repos.** Skills are now fetched from
  [anorth/agent-skills](https://github.com/anorth/agent-skills) (sibling checkout
  or `~/agent-skills`, no pin, skip on dirty/diverged). If a second external
  repo appears, lift that into a declarative list rather than another special
  case. Submodules stay rejected: pinning fights against a repo you're actively
  editing.

## Open questions

- **Cloud agents.** Only `~/.cursor/skills/` syncs to them, and this installer
  links skills into `~/.agents/skills/`, so they are invisible to cloud agents,
  remote SSH sessions and self-hosted workers. Needs a different approach if
  that ever matters: also link into `~/.cursor/skills/`, project-level skills, or
  baking them into a worker image.
