# dotfiles

Customizations, scripts and agent skills for **Linux dev containers**.

## Scope

This repo holds only things that work in a container. That keeps the installer
free of OS detection and per-platform branching: if something needs a `uname`
check to be safe, it doesn't belong here.

So macOS-specific tooling stays on the development machine and out of this repo,
and where a config exists in both places it is allowed to differ. `git/gitconfig`
is the worked example.

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
| `skills/` | Agent skills, one directory per skill |
| `git/` | Container-flavoured git config and global ignore |
| `install.sh` | Links repo contents into `$HOME` |

Skills are linked into `~/.agents/skills/`, which Cursor reads directly and which
is neutral across agents.

Because these are per-skill links rather than one link to the whole directory,
machine-local skills can sit alongside repo-managed ones.

## Dev containers

Set these in Cursor's user `settings.json` and every dev container gets the repo
cloned and installed automatically, with no per-project configuration:

```json
"dotfiles.repository": "git@github.com:anorth/dotfiles.git",
"dotfiles.targetPath": "~/dotfiles"
```

`dotfiles.installCommand` can be left unset: `install.sh` is the first filename
the dev containers CLI looks for, so it is picked up automatically.

Dev containers in Cursor run through its own `anysphere.remote-containers`
extension rather than Microsoft's, and dotfiles support arrived there in 1.0.14
with the ordering relative to credential setup fixed in 1.0.16. Note that these
settings are not covered by Cursor's official documentation, so treat them as
subject to change.

### Why the SSH URL, and why failures are invisible

Because this repo is private, the `owner/repo` shorthand does not work. It expands
to an HTTPS URL, and the container has no credentials for it, so the clone dies
with:

```
fatal: could not read Username for 'https://github.com': No such device or address
```

The part that makes this hard to spot is that container creation reports success
regardless — a failed dotfiles clone is not fatal to the container, so nothing
appears in the UI and the container simply comes up without any of this installed.
The creation log is the only place that error shows up.

The SSH form authenticates with the forwarded SSH agent instead, which requires
agent forwarding to be enabled (`dev.containers.enableSSHAgentForwarding`).

A public repo would avoid the question entirely, since it clones anonymously
everywhere.

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
sessions, or self-hosted workers, so skills installed by this repo are invisible
to those environments. Getting them there would need a different approach, such
as project-level skills committed to the repo being worked on, or baking them
into a worker image.
