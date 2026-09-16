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

## Dev containers

Set these in Cursor's user `settings.json` and every dev container gets the repo
cloned and installed automatically, with no per-project configuration:

```json
"dotfiles.repository": "anorth/dotfiles",
"dotfiles.targetPath": "~/dotfiles"
```

`dotfiles.installCommand` can be left unset: `install.sh` is the first filename
the dev containers CLI looks for, so it is picked up automatically. (If none of
its expected names were found it would instead symlink every top-level file into
the home directory, which is not what this repo wants.)

Dev containers in Cursor run through its own `anysphere.remote-containers`
extension rather than Microsoft's, and dotfiles support arrived there in 1.0.14
with the ordering relative to credential setup fixed in 1.0.16. Note that these
settings are not covered by Cursor's official documentation, so treat them as
subject to change. Keeping this repo public avoids the credential question at
clone time entirely.

For environments that never read editor settings, such as CI, clone explicitly
from `devcontainer.json` instead:

```json
"postCreateCommand": "git clone --depth 1 https://github.com/anorth/dotfiles.git ~/dotfiles 2>/dev/null || git -C ~/dotfiles pull --ff-only; ~/dotfiles/install.sh"
```

## Cloud agents

Cursor cloud agents do not use the dotfiles mechanism at all. They are configured
per repo through `.cursor/environment.json`, with a Dockerfile and an `install`
script that must be idempotent because it runs on every build.

There is a separate path for skills alone: Settings → Agents → Sync Skills for
Cloud Agents copies the contents of `~/.cursor/skills/`, and *only* that
directory — `~/.agents/skills/` is not copied to cloud agents, remote SSH
sessions, or self-hosted workers.

That matters for the layout here, because `~/.cursor/skills/` holds symlinks into
the hub rather than real files. Whether the sync dereferences those symlinks or
copies them as links (which would dangle) is untested. If cloud agent sync
becomes important, verify it, and fall back to copying skills into
`~/.cursor/skills/` instead of linking them.

## Editing

Skills are symlinked, not copied, so editing a skill in this repo takes effect
immediately for every agent on the machine. Commit and push, then re-run
`install.sh` elsewhere to pick up new skills.
