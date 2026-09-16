# TODO

Things discussed but not yet done. The scope rule in `README.md` applies: if it
needs a `uname` check, it doesn't belong here.

## Content to bring over

- **`bin/` scripts.** `replace-all` is the one worth having, but it needs work
  first: it relies on BSD `sed -i ''`, which is a syntax error under GNU sed, and
  on `ack`, which isn't in a container. Either port it or rewrite it over `rg`.
- **Portable shell config.** The git aliases from `.zshrc` are the valuable part.
  Containers give bash, so this wants to be a `shell/common.sh` that both
  `.bashrc` and a local `.zshrc` can source. Of the functions, `extract` is
  portable, `killport` needs `lsof`, and `j` needs `fzf`.

Deliberately staying out: `notify` (macOS `osascript`), the `zed` and `zq` binaries
in `~/bin` (113MB combined — install from a package manager instead), and the
macOS-only parts of `.zshrc` (Homebrew paths, conda, pnpm, oh-my-zsh and the `myh`
theme).

## Mechanisms

- **External repos.** A declarative list of repos that `install.sh` clones or
  pulls, then symlinks from. Prove it out with `gflow`
  (`github.com/anorth/gflows`, currently reached via `~/bin/gflow` pointing into
  `~/src/gflows`), then use the same mechanism for the repo where new agent skills
  are being developed. Submodules were rejected for this: pinning fights against a
  repo you're actively editing. Open question whether to pin refs at all.
- **A manifest file.** `install.sh` currently declares links in a `LINKS` array
  inline. If that grows much beyond git config, move it out to a file.

## Open questions

- **Cloud agents.** Only `~/.cursor/skills/` syncs to them, and this repo installs
  to `~/.agents/skills/`, so skills here are invisible to cloud agents, remote SSH
  sessions and self-hosted workers. Needs a different approach if that ever
  matters: project-level skills, or baking them into a worker image.
