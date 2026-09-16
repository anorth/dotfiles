# dotfiles

Customizations and scripts for **Linux dev containers**.

Agent skills live in a separate public catalog,
[anorth/agent-skills](https://github.com/anorth/agent-skills). This installer
clones that repo and links its skills into `~/.agents/skills/` so containers
still get them automatically. Others can install the skills alone with
`npx skills add anorth/agent-skills`.

## Scope

This repo holds only things that work in a container. That keeps the installer
free of OS detection and per-platform branching: if something needs a `uname`
check to be safe, it doesn't belong here.

So macOS-specific tooling stays on the development machine and out of this repo,
and where a config exists in both places it is allowed to differ. `git/gitconfig`
is the worked example. The skills catalog is not container-only; it is a
separate repo that this installer happens to consume.

Public repo: **no secrets, ever.** No tokens, keys, `.netrc`, `.aws`, or `.ssh`
contents. Machine-specific secrets belong in the environment, not here.

## Install

```sh
git clone https://github.com/anorth/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh --dry-run` prints what would change without touching anything.

Everything is installed as a symlink, so editing a file in the repo takes effect
immediately.

## Conservative by design

The installer never overwrites a real file. If a target already exists and is not
a symlink, it says so and moves on. Re-running is therefore always safe, and
adopting a file that's already there is a deliberate act: move it aside, then
re-run.

This is what makes it safe to run on a development machine that has its own
config. Running it on a Mac with an existing `~/.gitconfig` reports that the file
was kept and leaves it untouched, so the container-flavoured config here can
never clobber the local one.

## Layout

| Path | Purpose |
| --- | --- |
| `bin/` | Scripts, linked into `~/bin` |
| `git/` | Container-flavoured git config and global ignore |
| `install.sh` | Links repo contents into `$HOME`; also fetches agent-skills |

`~/bin` lands on `PATH` courtesy of the container's default `.profile`, which adds
it when the directory exists — so it works in login shells and in an editor
terminal, but a bare non-login `docker exec` shell won't see it.

`bin/gflow` needs `python3`. This repo's own container installs it with the
`ghcr.io/devcontainers/features/python:1` feature (`installTools` off — we only
need the interpreter). Other projects that want gflow should declare the same
feature, or already have Python in their image.

### Agent skills

`install.sh` resolves [anorth/agent-skills](https://github.com/anorth/agent-skills)
like this:

1. If a sibling checkout exists next to this repo (e.g.
   `/Users/me/Projects/agent-skills` beside `/Users/me/Projects/dotfiles`), use
   that — the working copy you edit on the development machine.
2. Otherwise clone or `git pull --ff-only` into `~/agent-skills` (the container
   path). If the tree is dirty, diverged, or the network fails, the installer
   reports and skips rather than overwriting or failing the rest of the install.

Each skill is then linked into `~/.agents/skills/`, which Cursor reads directly
and which is neutral across agents. Per-skill links mean machine-local skills can
sit alongside catalog ones.

## Dev containers

Set these in Cursor's user `settings.json` and every dev container gets the repo
cloned and installed automatically, with no per-project configuration:

```json
"dotfiles.repository": "anorth/dotfiles",
"dotfiles.targetPath": "~/dotfiles"
```

`dotfiles.installCommand` can be left unset: `install.sh` is the first filename
the dev containers CLI looks for, so it is picked up automatically.

Dev containers in Cursor run through its own `anysphere.remote-containers`
extension rather than Microsoft's, and dotfiles support arrived there in 1.0.14
with the ordering relative to credential setup fixed in 1.0.16. Note that these
settings are not covered by Cursor's official documentation, so treat them as
subject to change.

### Why this repo is public

Being public is what lets the `owner/repo` shorthand work: the clone is anonymous,
so containers need no credentials and SSH agent forwarding can stay switched off.

That matters because agent forwarding is not scoped to reading one repository. It
lets anything in the container use the forwarded key for any operation it
authorises, including pushing to every repo that key can reach. Keeping this repo
public buys a container that can install these dotfiles and still has no
credentials at all — verified: no agent socket, no `~/.ssh` keys, no
`~/.git-credentials`, and `ssh -T git@github.com` is refused.

The cost is that everything here is world-readable, which is why the no-secrets
rule above is a hard constraint rather than a preference.

If it ever goes private, the shorthand breaks in a way that is easy to miss. It
expands to an HTTPS URL, the container has no credentials, and the clone dies with
`fatal: could not read Username for 'https://github.com'` — but container creation
still reports success, so nothing surfaces in the UI and the container just comes
up without any of this installed. The creation log is the only place that error
appears. Fixing it means switching to `git@github.com:anorth/dotfiles.git` and
enabling `dev.containers.enableSSHAgentForwarding`, i.e. giving containers push
access to everything.

For environments that never read editor settings, such as CI, clone explicitly
from `devcontainer.json` instead:

```json
"postCreateCommand": "git clone --depth 1 https://github.com/anorth/dotfiles.git ~/dotfiles 2>/dev/null || git -C ~/dotfiles pull --ff-only; ~/dotfiles/install.sh"
```

### Testing changes to the installer

This repo has its own dev container, which installs from the mounted workspace
rather than from a clone so that uncommitted changes can be exercised. Open the
folder in a container, or from the command line:

```sh
devcontainer up --workspace-folder .         # create and start, runs postCreateCommand
devcontainer exec --workspace-folder . bash  # interactive shell inside it
```

Prefix both with `npx -y @devcontainers/cli` if the CLI isn't installed globally
(`npm install -g @devcontainers/cli`).

`exec` drops you into `/workspaces/dotfiles` as `vscode`, the same place and user
the editor gives you. Reaching in with `docker exec` needs
`-u vscode -w /workspaces/dotfiles` to match.

Re-running `up` reuses an existing container, which is fast but ignores changes to
`devcontainer.json`; add `--remove-existing-container` to force a rebuild. There
is no `down` subcommand, so tear down through docker, matching on the label the
CLI stamps on containers it creates:

```sh
docker rm -f $(docker ps -aq --filter label=devcontainer.local_folder="$PWD")
```

## Cloud agents

Cursor cloud agents do not use the dotfiles mechanism at all. They are configured
per repo through `.cursor/environment.json`, with a Dockerfile and an `install`
script that must be idempotent because it runs on every build.

There is a separate path for skills alone: Settings → Agents → Sync Skills for
Cloud Agents copies the contents of `~/.cursor/skills/`, and *only* that
directory. `~/.agents/skills/` is not copied to cloud agents, remote SSH
sessions, or self-hosted workers, so skills linked by this installer are
invisible to those environments. Getting them there would need a different
approach, such as also linking into `~/.cursor/skills/`, project-level skills
committed to the repo being worked on, or baking them into a worker image.
