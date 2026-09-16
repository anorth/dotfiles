# dotfiles

Personal customizations, scripts and agent skills, in a form that can be installed
on a fresh machine or inside a dev container.

Public repo: **no secrets, ever.** No tokens, keys, `.netrc`, `.aws`, or `.ssh`
contents. Machine-specific secrets belong in the environment, not here.

## Install

```sh
git clone https://github.com/anorth/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh --dry-run` prints what would change without touching anything.

The script is safe to re-run. Links that are already correct are left alone, and
anything that exists but is not a symlink is reported and skipped rather than
overwritten, so adopting an existing file is a deliberate act: move it aside,
then re-run.

## Layout

| Path | Purpose |
| --- | --- |
| `skills/` | Agent skills, one directory per skill |
| `install.sh` | Links repo contents into `$HOME` |

## How skills are installed

Skills fan out in two hops:

```
dotfiles/skills/<name>
  <- ~/.agents/skills/<name>        the agent-neutral hub
       <- ~/.cursor/skills/<name>
       <- ~/.claude/skills/<name>
```

The hub exists so that each skill has exactly one home regardless of how many
agents are installed, and so skills that arrive by other means (a skills CLI
installing into `~/.agents/skills`, for instance) fan out to every agent too
without being copied into this repo.

Because the agent directories hold per-skill links rather than one link to the
whole directory, machine-local skills can sit alongside repo-managed ones.

To add an agent, extend `AGENT_SKILL_DIRS` in `install.sh`.

## Editing

Skills are symlinked, not copied, so editing a skill in this repo takes effect
immediately for every agent on the machine. Commit and push, then re-run
`install.sh` elsewhere to pick up new skills.
